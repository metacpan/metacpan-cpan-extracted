# ABSTRACT: SimpleFlow - easy, simple workflow manager (and logger); for keeping track of and debugging large and complex shell command workflows
package SimpleFlow;
# NB: the package statement comes first on purpose. Until 0.16 the "use"
# lines below sat above it, so DDP's "p"/"np" and Cwd's "getcwd" were
# imported into main:: -- every program that loaded SimpleFlow silently
# acquired three subs it never asked for, and could collide with its own.
use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';

# Quoted, not the bare number: a numeric version is stringified through %g,
# so 0.20 would become "0.2" and compare as older than "0.15" on CPAN.
our $VERSION = '0.161';

use Capture::Tiny 'capture';
use Cwd 'getcwd';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Exporter 'import';
use List::Util qw(max min);
use POSIX ();
use Scalar::Util 'openhandle';
use Time::HiRes;

our @EXPORT = qw(say2 task);
our @EXPORT_OK = @EXPORT;

# Windows portability: the legacy Windows console (cmd.exe) prints raw ANSI
# escape sequences as garbage. Disable colouring there unless a terminal that
# understands ANSI is in use (Windows Terminal, ConEmu, ANSICON). Unix and
# modern Windows terminals are left untouched.
BEGIN {
	$ENV{ANSI_COLORS_DISABLED} = 1
		if $^O eq 'MSWin32'
		&& !$ENV{WT_SESSION} # Windows Terminal
		&& !$ENV{ConEmuANSI} # ConEmu
		&& !$ENV{ANSICON};   # ANSICON
}

# Ceiling on the length of any one field of the record when it is printed.
# Nothing was capped at all before 0.16, so a chatty command's entire stdout
# was echoed: a measured 3 MB capture wrote 3,002,832 bytes to the terminal
# and the same again to the log. 4096 is roughly 50 lines of an 80-column
# terminal -- enough to read a typical error message in full. What was
# dropped is marked, so a clipped field is never mistaken for a short one.
my $STRING_MAX_CAP = 4096;

# Minimal drop-in for Term::ANSIColor's colored(\@attrs, $text): map the few
# colour names we use to SGR codes so Perl core alone can colour the output.
# Honours $ENV{ANSI_COLORS_DISABLED} at call time (set above and by the caller).
my %ANSI_CODE = (
	reset         =>   0,
	black         =>  30,
	red           =>  31,
	green         =>  32,
	blue          =>  34,
	on_black      =>  40,
	on_green      =>  42,
	on_bright_red => 101,
);
sub colored {
	my ($attrs, $text) = @_;
	return $text if $ENV{ANSI_COLORS_DISABLED};
	my @codes = map {
		$ANSI_CODE{$_} // die "unknown colour attribute '$_'"
	} split ' ', join ' ', @$attrs;
	return $text unless @codes;
	return "\e[" . join(';', @codes) . 'm' . $text . "\e[0m";
}

sub say2 { # say to both command line and log file
	my ($msg, $fh) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my @c = caller;
	$msg = '' if not defined $msg; # interpolating undef below would be fatal under "warnings FATAL => 'all'"
	if (not openhandle($fh)) {
		die "the filehandle given to $current_sub with \"$msg\" from $c[1] line $c[2] isn't actually a filehandle";
	}
	_autoflush($fh);
	$msg = "\@ $c[1] line $c[2] $msg";
	say $msg;
	say $fh $msg;
	return $msg;
}

# Turn on autoflush for a log filehandle. Without it the record of the very
# task that killed the run is still sitting in stdio's buffer when the process
# dies: measured with a SIGKILL (the shape of an OOM kill or a scheduler
# eviction) part-way through a pipeline, a log that reached 862 bytes on a
# clean exit held only 139 bytes after the kill -- every line written after
# the last command started was lost, including that command's exit code,
# duration and captured output. select() is used rather than
# IO::Handle::autoflush so that nothing outside core is needed.
sub _autoflush {
	my $fh = shift;
	my $previously_selected = select $fh;
	$| = 1;
	select $previously_selected;
	return;
}

# A copy of a record with its over-long fields clipped to $STRING_MAX_CAP and
# the drop marked. Data::Printer's own "string_max" property does this job,
# and 0.16 left it to do it -- but string_max only arrived in Data::Printer
# 0.99_001 (2018), and every release before that ignores a property it does
# not recognize, in silence. A CPAN tester on Data::Printer 0.38 therefore had
# the whole of a 200,000-character capture printed to its terminal and copied
# into its log. Clipping here holds the ceiling on every version.
# The record the caller is handed is untouched: only the printed copy is
# clipped, so $t->{stdout} still has the full capture. The mark is
# Data::Printer's own wording, so the output does not change on the versions
# that were already capping it.
sub _clipped {
	my $r = shift;
	my %clipped = %$r; # shallow: only the top-level fields are ever this long
	foreach my $key (grep {ref $clipped{$_} eq ''} keys %clipped) {
		next unless defined $clipped{$key}; # length undef is fatal here
		my $dropped = length($clipped{$key}) - $STRING_MAX_CAP;
		next if $dropped <= 0;
		$clipped{$key} = substr($clipped{$key}, 0, $STRING_MAX_CAP)
			. "(...skipping $dropped chars...)";
	}
	return \%clipped;
}

# Print the result record to the terminal (unless "quiet") and to the log
# filehandle (if one was given). "quiet" silences only this routine chatter;
# errors still go to STDERR, since a caller that asked for less noise did not
# ask to be kept in the dark about a failure.
sub _report {
	my ($r, $log_fh, $quiet) = @_;
	my $clipped = _clipped($r);
	# string_max => 0 turns Data::Printer 1.x's own clipping off: the fields
	# arrive clipped already, and a second pass would print a second
	# "skipping" mark. Older releases ignore the property either way.
	p(%$clipped, output => $log_fh, string_max => 0) if defined $log_fh;
	p(%$clipped, string_max => 0) unless $quiet;
	return;
}

# Newest and oldest modification times among the named files, or undef when
# none of them exist. stat's mtime is used rather than -M because -M is
# measured from the interpreter's start time, which makes it useless for
# comparing against files written during the run.
sub _newest_mtime {
	my @mtimes = map { (stat $_)[9] } grep { -e $_ } @_;
	return undef if scalar @mtimes == 0;
	return max(@mtimes);
}
sub _oldest_mtime {
	my @mtimes = map { (stat $_)[9] } grep { -e $_ } @_;
	return undef if scalar @mtimes == 0;
	return min(@mtimes);
}

# Fold the "<kind>.file" (a single name) and "<kind>.files" (a name or an
# array ref) forms into one list, and reject names that cannot meaningfully be
# filetested. undef and '' are caught HERE, before any -f: "-f undef" is a
# fatal warning under "warnings FATAL => 'all'" and "-f ''" is merely false,
# so until 0.16 a bad input name surfaced either as a crash inside SimpleFlow
# or as the misleading "missing or unreadable", never as the argument error
# it actually is.
sub _normalise_files {
	my ($args, $kind) = @_;
	my ($single, $plural) = ("$kind.file", "$kind.files");
	# The two forms are mutually exclusive: mixing them is almost always a
	# mistake (which one holds the truth?), so refuse it outright.
	if ((defined $args->{$single}) && (defined $args->{$plural})) {
		p $args;
		die "\"$single\" and \"$plural\" cannot both be given; use one or the other";
	}
	my @files;
	my $given = $plural;
	if (defined $args->{$plural}) {
		my $ref = ref $args->{$plural};
		if ($ref eq 'ARRAY') {
			@files = @{ $args->{$plural} };
		} elsif ($ref eq '') { # a scalar
			@files = ($args->{$plural});
		} else {
			p $args;
			die "ref type \"$ref\" is not allowed for \"$plural\"";
		}
	} elsif (defined $args->{$single}) {
		$given = $single;
		my $ref = ref $args->{$single};
		if ($ref ne '') { # a single file only, never a ref
			p $args;
			die "$ref isn't allowed for \"$single\"; it takes a single filename (use \"$plural\" for a list)";
		}
		@files = ($args->{$single});
	}
	my @bad = grep { (not defined $files[$_]) || (length $files[$_] == 0) } 0 .. $#files;
	if (scalar @bad > 0) {
		p $args;
		die 'undefined or 0-length filenames are not allowed (found in "'
			. $given . '" at ' . ((scalar @bad == 1) ? 'index ' : 'indices ')
			. join(', ', @bad) . ')';
	}
	return @files;
}

# Run $cmd under a wall-clock limit and return its raw wait status together
# with a flag saying whether the limit was hit. system() cannot be used here:
# a $SIG{ALRM} that fires while it is blocked in waitpid unwinds the Perl
# stack but leaves the child running as an orphan. The child is therefore
# forked explicitly and put into its own process group, so that the timeout
# can kill the group as a whole -- a shell command is usually a pipeline, not
# a single process, and killing only the shell would leave its children
# behind. POSIX-only; the caller refuses "timeout" on MSWin32.
sub _run_with_timeout {
	my ($cmd, $timeout) = @_;
	my $pid = fork();
	die "fork() failed, so \"timeout\" cannot be honoured: $!" if not defined $pid;
	if ($pid == 0) { # the child
		setpgrp(0, 0); # lead a new process group, so the kill below reaches the whole pipeline
		my $exec_ok = (ref $cmd eq 'ARRAY')
			? exec({ $cmd->[0] } @{ $cmd })
			: exec($cmd);
		# Only reached when exec itself failed. _exit, not exit: exit would
		# run END blocks and flush the parent's buffers a second time.
		POSIX::_exit(127); # 127 is the shell's own "command not found" status
	}
	my $timed_out = 0;
	my $status;
	eval {
		local $SIG{ALRM} = sub { $timed_out = 1; die "SF_TIMEOUT\n" };
		alarm $timeout;
		waitpid $pid, 0;
		$status = $?;
		alarm 0;
		1;
	} or do {
		my $error = $@;
		alarm 0;
		die $error if not $timed_out; # something other than the timeout went wrong
		kill 'KILL', -$pid; # negative pid: the process group, not just the shell
		waitpid $pid, 0;
		$status = $?;
	};
	return ($status, $timed_out);
}

sub task {
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	# Accept either a single hash ref -- task({ cmd => ... }) -- or a flat
	# key/value list -- task(cmd => ...). A lone non-hashref scalar, or an
	# odd-length list, can't be read either way and is fatal.
	my $args;
	if (@_ == 1 && ref $_[0] eq 'HASH') {
		$args = $_[0];
	} elsif (@_ % 2 == 0) {
		$args = { @_ };
	} else {
		die "args to $current_sub must be a hash ref (e.g. $current_sub({ cmd => ... })) or a flat key/value list (e.g. $current_sub(cmd => ...)); got an odd-length list";
	}
	my @c = caller;
	my @reqd_args = (
		'cmd', # the shell command
	);
	my @undef_args = grep { !defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'die',			# die if not successful; 0 or 1
		'dry.run',     # dry run or not
		'input.file',  # a single input file; the convenience form of "input.files"
		'input.files', # check for input files; SCALAR or ARRAY
		'log.fh',
		'note',        # a note for the log
		'output.file', # for a single file, gets pushed into output.files anyway
		'output.files',# product files that need to be checked; can be scalar or array
		'overwrite',   # bool
		'quiet',       # bool; suppress the terminal record, but never the log or STDERR
		'stale',       # bool; also re-run when an input is newer than an output
		'timeout',     # whole seconds of wall clock; 0 means no limit
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args;
		say "the above arguments are not recognized by $current_sub";
		p @defined_args, array_max => scalar @defined_args;
		die "The above args are accepted by $current_sub";
	}
	if (
			(defined $args->{'log.fh'}) &&
			(not openhandle($args->{'log.fh'}))
		) {
		p $args;
		die "the filehandle given to $current_sub isn't actually a filehandle";
	}
	_autoflush($args->{'log.fh'}) if defined $args->{'log.fh'};

	# "cmd" is either a string handed to the shell, or an array ref that is
	# run without a shell (so no quoting or metacharacter surprises). Until
	# 0.16 only definedness was checked, and any other reference was
	# stringified straight into the shell: task(cmd => ['echo','hi']) ran the
	# literal command "ARRAY(0x5ed9d076e618)".
	my $cmd_ref = ref $args->{cmd};
	if (($cmd_ref ne '') && ($cmd_ref ne 'ARRAY')) {
		p $args;
		die "\"cmd\" must be a string or an array ref, not a $cmd_ref";
	}
	if ($cmd_ref eq 'ARRAY') {
		if (scalar @{ $args->{cmd} } == 0) {
			p $args;
			die '"cmd" is an empty array ref; there is no command to run';
		}
		my @undefined_words = grep { not defined $args->{cmd}[$_] } 0 .. $#{ $args->{cmd} };
		if (scalar @undefined_words > 0) {
			p $args;
			die '"cmd" array ref holds undefined elements at index/indices ' . join(', ', @undefined_words);
		}
	} elsif (length $args->{cmd} == 0) {
		p $args;
		die '"cmd" is the empty string; there is no command to run';
	}
	# The printable form of the command, used in every message and stored as
	# the record's "cmd". An array-ref command is shown space-joined, which is
	# readable but is NOT a shell-quoted round trip: it was never passed to a
	# shell in the first place.
	my $cmd_string = ($cmd_ref eq 'ARRAY') ? join(' ', @{ $args->{cmd} }) : $args->{cmd};

	if (defined $args->{timeout}) {
		if ($args->{timeout} !~ /^\d+$/) {
			p $args;
			die '"timeout" must be a whole number of seconds (0 means no limit)';
		}
		if (($args->{timeout} > 0) && ($^O eq 'MSWin32')) {
			p $args;
			die '"timeout" is not supported on MSWin32: it needs fork() and POSIX process groups to kill the command';
		}
	}

	# Both file lists are normalised, and their names validated, before any
	# filetest touches them.
	my @input_files  = _normalise_files($args, 'input');
	my @output_files = _normalise_files($args, 'output');

	my %input_file_size;
	if (scalar @input_files > 0) {
		my @missing_files = grep {not -f -r $_ } @input_files;
		if (scalar @missing_files > 0) {
			say STDERR 'this list of arguments:';
			p $args;
			say STDERR 'Cannot run because these files are either missing or unreadable in: ' . getcwd();
			p @missing_files;
			die 'the above files are missing or are not readable';
		}
		%input_file_size = map { $_ => -s $_ } @input_files;
	}

	my %r = (
		cmd            => $cmd_string,
		dir				=> getcwd(),
		'source.file'  => $c[1],
		'source.line'  => $c[2],
		'output.files' => [@output_files],
	);
	$r{'die'}     = $args->{'die'}     // 1; # by default, true
	$r{'dry.run'} = $args->{'dry.run'} // 0; # by default, false
	$r{note}      = $args->{note}      // '';# by default, no note
	$r{overwrite} = $args->{overwrite} // 0; # by default, false
	$r{quiet}     = $args->{quiet}     // 0; # by default, false
	$r{stale}     = $args->{stale}     // 0; # by default, false
	$r{timeout}   = $args->{timeout}   // 0; # by default, no limit
	# These belong to a command that actually ran, but they are seeded on
	# every path so that the record has the same shape after a skip or a dry
	# run. They used to be absent there, which meant a caller reading
	# $t->{'exit'} after a skip took an uninitialized-value warning -- fatal
	# under the "warnings FATAL => 'all'" this module itself recommends.
	$r{'exit'}      = 0;
	$r{signal}      = 0;
	$r{stdout}      = '';
	$r{stderr}      = '';
	$r{'timed.out'} = 0;
	$r{duration}    = 0;
	$r{'will.do'} = 'yes';
	$r{'will.do'} = 'no: dry run'  if $r{'dry.run'};
	if (scalar @input_files > 0) {
		$r{'input.files'}     = [@input_files];
		$r{'input.file.size'} = \%input_file_size;
	}

	my $msg = "\@ $c[1] line $c[2] The command is:\n" . colored(['blue on_bright_red'], $cmd_string);
	say $msg unless $r{quiet};
	say {$args->{'log.fh'}} "\@ $c[1] line $c[2] The command is:\n$cmd_string" if defined $args->{'log.fh'};

	# The same test as the post-run check further down (-f -r, not a bare -f).
	# A file that exists but cannot be read is not a usable result, and
	# counting it as "already done" would skip the very step that could
	# replace it.
	my @existing_files = grep {-f -r $_} @output_files;

	# Staleness, as make and snakemake understand it: outputs that already
	# exist are still out of date if any input is newer than any of them.
	# Off by default, because switching it on unconditionally would silently
	# start re-running steps in pipelines written against 0.15 and earlier.
	my $is_stale = 0;
	if (($r{stale}) && (scalar @input_files > 0) && (scalar @output_files > 0)) {
		my $newest_input  = _newest_mtime(@input_files);
		my $oldest_output = _oldest_mtime(@output_files);
		if (
				(defined $newest_input)  &&
				(defined $oldest_output) &&
				($newest_input > $oldest_output)
			) {
			$is_stale = 1;
		}
	}
	$r{'out.of.date'} = $is_stale;

	my %output_file_size = map {$_ => -s $_} @output_files;
	if (
			(!$r{overwrite})   &&
			(!$is_stale)       &&
			(scalar @output_files > 0) &&
			(scalar @existing_files == scalar @output_files)
		) { # this has been done before
		$r{done} = 'before';
		$r{'will.do'} = 'no';
		say colored(['black on_green'], "\"$cmd_string\"\n") . ' has been done before' unless $r{quiet};
		$r{'output.file.size'} = \%output_file_size;
		_report(\%r, $args->{'log.fh'}, $r{quiet});
		return \%r;
	} else {
		$r{done} = 'not yet';
	}
	if ($is_stale) {
		say colored(['red on_black'], "\"$cmd_string\"")
			. ' is being re-run: an input file is newer than an output file' unless $r{quiet};
	}
	if ($r{'dry.run'}) {
		unless ($r{quiet}) {
			say "\@ $c[1] line $c[2] in $r{dir} the command was going to be:";
			say colored(['red on_black'], "\"$cmd_string\"");
			say 'But this is a dry run';
			say '-------------';
		}
		return \%r;
	}
	my $t0 = Time::HiRes::time();
	my @run_result;
	($r{stdout}, $r{stderr}, @run_result) = capture {
		return _run_with_timeout($args->{cmd}, $r{timeout}) if $r{timeout};
		my $raw_status = ($cmd_ref eq 'ARRAY')
			? system(@{ $args->{cmd} })
			: system($args->{cmd});
		return ($raw_status, 0);
	};
	my $t1 = Time::HiRes::time();
	$r{duration} = $t1-$t0;
	my ($status, $timed_out) = @run_result;
	$r{'timed.out'} = $timed_out ? 1 : 0;
	# Decode the raw wait status. On Unix the low 7 bits hold the death
	# signal and the high byte holds the exit code. The signal MUST be read
	# from the raw status *before* shifting -- the old code shifted first and
	# then did ($exit & 127), so $r{signal} was always 0 and could never
	# detect a kill by signal 9/15. Windows has no POSIX signals, and a -1
	# return from system() means the command never launched.
	if (!defined $status || $status == -1) {
		$r{'exit'}   = -1;
		$r{signal}   = 0;
	} elsif ($^O eq 'MSWin32') {
		$r{signal}   = 0;
		$r{'exit'}   = $status >> 8;
	} else {
		$r{signal}   = $status & 127; # FIX: taken from raw status, not from $exit
		$r{'exit'}   = $status >> 8;
	}
	foreach my $std ('stderr', 'stdout') {
		$r{$std} =~ s/\s+$//; # remove trailing whitespace/newline
	}
	$r{done} = 'now';
	$r{'will.do'} = 'done';
	# A command that timed out, exited non-zero, or failed to produce its
	# declared outputs has failed, whether or not "die" is set. Until 0.16
	# the FAILED assignment for a non-zero exit lived inside the "die" branch,
	# so under die => 0 -- the very mode in which the caller is expected to
	# read will.do -- a failing command was reported as "done".
	my @missing_output_files = grep {not -f -r $_} @output_files;
	if ((scalar @missing_output_files > 0) || ($r{'exit'} != 0) || ($r{'timed.out'})) {
		$r{'will.do'} = 'FAILED';
	}
	if (scalar @missing_output_files > 0) {
		my $clipped_args = _clipped($args);
		say STDERR "this input to $current_sub:";
		p $clipped_args;
		say {$args->{'log.fh'}} "this input to $current_sub:" if defined $args->{'log.fh'};
		p($clipped_args, output => $args->{'log.fh'}, string_max => 0) if defined $args->{'log.fh'};
		say STDERR 'has these output files missing:';
		say {$args->{'log.fh'}} 'has these output files missing:' if defined $args->{'log.fh'};
		p @missing_output_files;
		p(@missing_output_files, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
		_report(\%r, $args->{'log.fh'}, $r{quiet});
		if ($r{'die'}) { # use the resolved value (defaults to 1), not the raw arg
			die 'those above files should have been made but are missing';
		} else {
			say STDERR 'those above files should have been made but are missing';
		}
	}
	%output_file_size = map {$_ => -s $_} @output_files;
	$r{'output.file.size'} = \%output_file_size;
	my @files_with_zero_size = grep { ($output_file_size{$_} // 0) == 0 } @output_files;
	if (scalar @files_with_zero_size > 0) {
		p @files_with_zero_size;
		warn 'the above output files have 0 size.';
	}
	if ($r{'timed.out'}) {
		_report(\%r, $args->{'log.fh'}, $r{quiet});
		if ($r{'die'}) {
			die "\"$cmd_string\" was killed after exceeding its $r{timeout}s timeout, from $c[1] line $c[2]";
		}
		warn "\"$cmd_string\" was killed after exceeding its $r{timeout}s timeout, from $c[1] line $c[2]";
		return \%r;
	}
	if ($r{'exit'} != 0) {
		_report(\%r, $args->{'log.fh'}, $r{quiet});
		if ($r{'die'}) {
			die "\"$cmd_string\" failed from $c[1] line $c[2]"
		}
		# die => 0 asks task not to stop the pipeline, not to keep quiet:
		# a warning is the only signal a caller gets that did not look at
		# will.do.
		warn "\"$cmd_string\" exited $r{'exit'} from $c[1] line $c[2]";
		return \%r;
	}
	_report(\%r, $args->{'log.fh'}, $r{quiet});
	return \%r;
}
1;

=encoding utf8

=head1 NAME

SimpleFlow - easy, simple workflow manager (and logger); for keeping track of and debugging large and complex shell command workflows

=head1 VERSION

version 0.161

=head1 DESCRIPTION

A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to B<debug> and B<reproduce>.

Every step is a single C<task()> call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its C<stdout>,
C<stderr>, exit code and signal, optionally logs a full structured record, and
skips work that has already been done. It can also bound a step with a
L<timeout|/"Timeouts"> and rebuild L<out-of-date outputs|/"Out-of-date outputs">.

Two subroutines are exported by default: L</"task"> and L</"say2">.

=head1 Install

With a CPAN client:

 cpanm SimpleFlow

Or from a checkout:

 perl Makefile.PL
 make
 make test
 make install

=head1 Synopsis

The simplest useful case: run a command and confirm it produced its output:

 use SimpleFlow qw(task say2);
 
 my $t = task(
     cmd            => 'which ls',
     'output.files' => '/tmp/AFK3mnEK8L.log',
 );

C<task> returns a hash reference describing exactly what happened:

 {
     cmd            "which ls",
     die            1,
     dir            "/home/con/Scripts/SimpleFlow",
     done           "now",
     dry.run        0,
     duration       0.00191903114318848,
     exit           0,
     note           "",
     output.files   [
         [0] "/tmp/AFK3mnEK8L.log"
     ],
     overwrite      1,
     signal         0,
     source.file    "t/01.t",
     source.line    29,
     stderr         "",
     stdout         "/usr/bin/ls",
     will.do        "done"
 }

 > B<Portability note.> SimpleFlow runs whatever shell command you give it via
 > C<system()>, so the I<commands themselves> are your responsibility to keep
 > cross-platform (e.g. C<which ls> is Unix-only). SimpleFlow's own behaviour
 > exit/signal decoding and coloured output is cross-platform; see the
 > change log.

=head1 C<task>

 my $result = task(%args);      # or task(\%args)

Runs one command with checking, timing, capture and logging. Takes either a
flat key/value list or a single hash reference; the only required key is C<cmd>.

=head2 Arguments



=begin html

<table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>cmd</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td><b>Required.</b> The command to run. A string is handed to the shell; an array ref is run without a shell.</td>
</tr>
<tr>
  <td><code>die</code></td>
  <td>bool (<code>0</code>/<code>1</code>)</td>
  <td><code>1</code></td>
  <td>Die if the command fails (non-zero exit, timeout, or a missing output file). Set to <code>0</code> to warn and continue instead.</td>
</tr>
<tr>
  <td><code>dry.run</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Print the command (and log it) but do not execute it.</td>
</tr>
<tr>
  <td><code>input.files</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>File(s) that must exist and be readable <b>before</b> running; otherwise <code>task</code> dies.</td>
</tr>
<tr>
  <td><code>input.file</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>input.files</code> for a <b>single</b> file. Must be a plain filename (not a reference). Cannot be combined with <code>input.files</code>.</td>
</tr>
<tr>
  <td><code>output.files</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>File(s) expected to exist <b>after</b> running; used both for the missing-output check and for skip detection.</td>
</tr>
<tr>
  <td><code>output.file</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>output.files</code> for a <b>single</b> file. Must be a plain filename (not a reference). Cannot be combined with <code>output.files</code>.</td>
</tr>
<tr>
  <td><code>log.fh</code></td>
  <td>open filehandle</td>
  <td><code>undef</code></td>
  <td>If given, the full result record is also written here. Must be a real, open filehandle; <code>task</code> switches it to autoflush.</td>
</tr>
<tr>
  <td><code>note</code></td>
  <td>scalar</td>
  <td><code>''</code></td>
  <td>Free-text note copied into the result and the log.</td>
</tr>
<tr>
  <td><code>overwrite</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>If false and all <code>output.files</code> already exist, the command is skipped. Set true to always run.</td>
</tr>
<tr>
  <td><code>quiet</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Suppress the record printed to the terminal. The log and error messages on <code>STDERR</code> are unaffected. See Quiet runs.</td>
</tr>
<tr>
  <td><code>stale</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Also re-run when an input file is newer than an output file. See Out-of-date outputs.</td>
</tr>
<tr>
  <td><code>timeout</code></td>
  <td>whole seconds</td>
  <td><code>0</code></td>
  <td>Kill the command if it runs longer than this. <code>0</code> means no limit. See Timeouts.</td>
</tr>
</tbody>
</table>

=end html



Passing an unrecognised key, an undefined or empty filename, a C<cmd> that is
neither a string nor an array ref, or a non-filehandle C<log.fh> causes C<task>
to die: these are usually mistakes worth catching early. Giving both
C<output.file> and C<output.files> (or both C<input.file> and C<input.files>), or a
reference where a single filename is expected, dies for the same reason.

=head2 Return value

C<task> always returns a hash reference. Every field below except the two
C<input.*> ones is present on B<every> path, so a caller running under
C<< use warnings FATAL =E<gt> 'all' >> can read the record after a skip or a dry run
without an uninitialized-value warning turning fatal. On those paths the
execution-only fields simply hold their empty values (C<exit> and C<signal> are
C<0>, C<stdout> and C<stderr> are C<''>, C<duration> is C<0>).



=begin html

<table>
<thead>
<tr>
  <th>Field</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>cmd</code></td>
  <td>The command that was run. An array-ref <code>cmd</code> is recorded space-joined for readability; that is not a shell-quoted round trip, since it never went near a shell.</td>
</tr>
<tr>
  <td><code>dir</code></td>
  <td>Working directory at execution time.</td>
</tr>
<tr>
  <td><code>done</code></td>
  <td><code>"now"</code> (just ran), <code>"before"</code> (skipped, outputs already existed), or <code>"not yet"</code> (dry run).</td>
</tr>
<tr>
  <td><code>will.do</code></td>
  <td><code>"done"</code>, <code>"no"</code> (skipped), <code>"no: dry run"</code>, or <code>"FAILED"</code>. <code>"FAILED"</code> is set whenever the command exited non-zero, timed out, or left a declared output file missing — <b>whether or not <code>die</code> is set</b>.</td>
</tr>
<tr>
  <td><code>duration</code></td>
  <td>Wall-clock seconds the command took (<code>0</code> for skips/dry runs).</td>
</tr>
<tr>
  <td><code>exit</code></td>
  <td>Exit code of the command (<code>-1</code> if it could not be launched).</td>
</tr>
<tr>
  <td><code>signal</code></td>
  <td>Signal number if the command process was killed by a signal, else <code>0</code>. Always <code>0</code> on Windows (no POSIX signals).</td>
</tr>
<tr>
  <td><code>timed.out</code></td>
  <td><code>1</code> if the command was killed for exceeding its <code>timeout</code>, else <code>0</code>.</td>
</tr>
<tr>
  <td><code>out.of.date</code></td>
  <td><code>1</code> if <code>stale</code> was set and an input was newer than an output, else <code>0</code>.</td>
</tr>
<tr>
  <td><code>stdout</code>, <code>stderr</code></td>
  <td>Captured output, with trailing whitespace stripped.</td>
</tr>
<tr>
  <td><code>die</code>, <code>dry.run</code>, <code>overwrite</code>, <code>note</code>, <code>quiet</code>, <code>stale</code>, <code>timeout</code></td>
  <td>The (defaulted) argument values used.</td>
</tr>
<tr>
  <td><code>output.files</code></td>
  <td>Array ref of the output files (a scalar argument, or an <code>output.file</code>, is normalised to a one-element array).</td>
</tr>
<tr>
  <td><code>output.file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the outputs.</td>
</tr>
<tr>
  <td><code>input.files</code></td>
  <td>Array ref of the input files, normalised the same way (present only if you passed <code>input.files</code> or <code>input.file</code>).</td>
</tr>
<tr>
  <td><code>input.file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the inputs (present only if you passed <code>input.files</code> or <code>input.file</code>).</td>
</tr>
<tr>
  <td><code>source.file</code>, <code>source.line</code></td>
  <td>Where in <i>your</i> code the <code>task</code> was called: handy when debugging a long pipeline.</td>
</tr>
</tbody>
</table>

=end html



=head2 Skipping completed work

If C<overwrite> is false (the default) and every file in C<output.files> already
exists, C<task> does B<not> re-run the command. This makes pipelines
restartable: re-running the script picks up where it left off.

 open my $log, '>', 'logfile.txt';
 my $t = task(
     cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
     'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
     'output.files' => 'em.tpr',
     'log.fh'       => $log,
 );
 close $log;

On the first run C<done> is C<"now">; on a re-run (with C<em.tpr> present) C<done>
is C<"before"> and C<will.do> is C<"no">. Pass C<< overwrite =E<gt> 1 >> to force it.

An output file that exists but cannot be B<read> does not count as done: it is
not a usable result, and treating it as one would skip the very step that could
replace it.

=head2 Out-of-date outputs

Existence alone is a weak test. If an input file has been edited since the
output was built, the output is stale even though it is present — and by
default C<task> will still skip the step, exactly as earlier versions did.

Pass C<< stale =E<gt> 1 >> to get the rule C<make> and C<snakemake> use: re-run whenever
the newest C<input.files> mtime is later than the oldest C<output.files> mtime.

 my $t = task(
     cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
     'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
     'output.files' => 'em.tpr',
     stale          => 1,
 );

Editing C<em.mdp> now rebuilds C<em.tpr>; leaving it alone still skips. The
result's C<out.of.date> field says which of the two happened. This is off by
default so that upgrading does not silently start re-running steps in pipelines
written against 0.15 and earlier.

=head2 Timeouts

C<timeout> gives a step a wall-clock budget in whole seconds:

 my $t = task(
     cmd     => 'a command that sometimes wedges',
     timeout => 600,
     die     => 0,
 );

The command is run in its own process group and, if the budget is exceeded, the
B<whole group> is killed — a shell command is usually a pipeline, not a single
process, and killing only the shell would leave its children running. The
result then has C<< timed.out =E<gt> 1 >> and C<< will.do =E<gt> "FAILED" >>; with the default
C<< die =E<gt> 1 >> the pipeline stops there instead.

C<timeout> needs C<fork()> and POSIX process groups, so it is refused on
C<MSWin32>. Leaving it at C<0> (the default) changes nothing anywhere.

=head2 Running without a shell

Giving C<cmd> an array ref runs the command directly, with no shell in between:

 my $t = task(
     cmd           => ['gzip', '-9', $file],   # $file needs no quoting
     'output.file' => "$file.gz",
 );

This is the form to reach for when an argument comes from data — a filename
with a space, a quote, or a C<$> in it is passed through untouched instead of
being re-parsed by the shell. You lose shell features (C<< E<gt> >>, C<|>, C<*>, C<&&>) in
exchange; use the string form when you want them.

=head2 Quiet runs

Every C<task> prints its record to the terminal. Over a hundred-step pipeline
that is a lot of scrollback, so C<< quiet =E<gt> 1 >> suppresses it:

 my $t = task(
     cmd      => 'one of very many steps',
     'log.fh' => $log,
     quiet    => 1,
 );

The log filehandle still receives the full record, and error messages still go
to C<STDERR>: asking for less noise is not the same as asking to be kept in the
dark about a failure.

=head2 Dry runs

Useful for inspecting a pipeline without executing anything expensive:

 my $t = task(
     cmd       => 'a long-running, time-consuming command',
     'dry.run' => 1,
     'log.fh'  => $fh,
 );

The command is printed (and logged) but not run; C<will.do> is C<"no: dry run">.

=head2 Failure behaviour

By default (C<< die =E<gt> 1 >>) C<task> dies if the command exits non-zero, exceeds its
C<timeout>, or leaves any declared C<output.files> missing afterwards, so a broken
step stops the pipeline immediately.

With C<< die =E<gt> 0 >>, C<task> instead warns and returns its result hash with
C<< will.do =E<gt> "FAILED" >>, letting you decide what to do:

 my $t = task(cmd => 'a step that may fail', die => 0);
 if ($t->{'will.do'} eq 'FAILED') {
     ...   # $t->{'exit'}, $t->{stderr} and $t->{'timed.out'} say why
 }

=head2 C<say2>

 say2($message, $filehandle);

"Say to two places": prints C<$message> to standard output B<and> to the given
log filehandle, prefixed with the calling file and line number so log entries
are traceable. The filehandle must be open, or C<say2> dies.

 open my $log, '>', 'run.log';
 say2('starting equilibration', $log);   # -> STDOUT and run.log
 close $log;

=head1 Dependencies

Core/runtime modules used by SimpleFlow:

=over

=item * L<Capture::Tiny> captures C<stdout>/C<stderr>

=item * L<Data::Printer> (C<DDP>) pretty result/record printing

=item * L<Devel::Confess> better backtraces on death

=item * C<List::Util>, C<Scalar::Util>, C<Time::HiRes>, C<Cwd>, C<POSIX> core utilities

=back

The test suite additionally uses C<Test::More> and
L<Test::Exception>.

=head1 Changes

The release notes are in the C<Changes> file at the root of the
distribution, in the format CPAN itself reads.

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself
