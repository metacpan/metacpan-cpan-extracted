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

# While this file compiles, perl names each anonymous sub for where it was
# written -- SimpleFlow::__ANON__[.../SimpleFlow.pm:123] rather than plain
# SimpleFlow::__ANON__ -- so that a stack trace through one of SimpleFlow's
# closures says which. These are the $^P bits Devel::Confess's import() sets
# (0x100, informative names for evals; 0x200, for anonymous subs; perlvar,
# "$^P"), for the whole program and for good. Until 0.19 the module imported
# Devel::Confess, and so set them for its caller too; now it sets them for
# its own code only, and the BEGIN block just above "1;" puts back whatever
# was there before.
our $CALLER_PERLDB_FLAGS;
BEGIN {
	$CALLER_PERLDB_FLAGS = $^P;
	$^P |= 0x100 | 0x200;
}

# Quoted, not the bare number: a numeric version is stringified through %g,
# so 0.20 would become "0.2" and compare as older than "0.15" on CPAN.
our $VERSION = '0.193';

use Cwd 'getcwd';
use Digest::MD5 'md5_hex';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess (); # loaded, not imported: task() enables it for itself; see _confess_here
use Exporter 'import';
use Fcntl ();
use File::Find ();
use File::Path ();
use File::Spec;
use File::Temp ();
use List::Util qw(max min);
use POSIX ();
use Scalar::Util 'openhandle';
use Storable ();
use Time::HiRes;

our @EXPORT = qw(say2 task);
# not exported unless asked for, so that a program loading SimpleFlow does not
# acquire two more common names
our @EXPORT_OK = (@EXPORT, 'parallel', 'report');

# Defaults for every task() in the program, for any key the call itself leaves
# undefined: local %SimpleFlow::DEFAULTS = ('dry_run' => 1) dry-runs a whole
# pipeline from one line. "env" and "env_secret" are merged with a task's own
# rather than replaced by it. Keys that name one particular step are refused;
# see @PER_STEP_KEYS in task().
our %DEFAULTS;

# [file, line] for task() to report as its caller, instead of its real one;
# undef = its real one. parallel() sets it, since each task it runs is called
# from parallel() itself, in a child, and the caller wants its own line.
our $CALLER;

# Runs a closure when it goes out of scope, however the scope is left: return,
# die, or the end of the block. task() uses it to go back to the caller's
# directory after "dir". The package name is on its own line so that PAUSE and
# MetaProvides do not index it: it is not API.
package # not indexed
	SimpleFlow::Guard;
sub new {
	my ($class, $code) = @_;
	return bless { code => $code }, $class;
}
sub DESTROY {
	my $self = shift;
	$self->{code}->();
	return;
}
package SimpleFlow;

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
	# Devel::Confess for this call only, as in task(): see _confess_here
	local $SIG{__DIE__}  = $SIG{__DIE__};
	local $SIG{__WARN__} = $SIG{__WARN__};
	local $Devel::Confess::OLD_SIG{__DIE__}  = $Devel::Confess::OLD_SIG{__DIE__};
	local $Devel::Confess::OLD_SIG{__WARN__} = $Devel::Confess::OLD_SIG{__WARN__};
	local $Devel::Confess::OPTIONS{color}    = $Devel::Confess::OPTIONS{color};
	_confess_here();
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
#
# The copy is built field by field, and an over-long field is never copied in
# full: "%clipped = %$r" followed by substr, as 0.17 did it, copied the whole
# of stdout and stderr first, and perls before 5.20 have no copy-on-write to
# make that cheap: on perl-5.10.1, clipping a record holding a 100 MB stdout
# raised peak RSS from 205 MB to 303 MB, for text that was then thrown away.
sub _clipped {
	my $r = shift;
	my %clipped; # shallow: only the top-level fields are ever this long
	foreach my $key (keys %$r) {
		my $value = \$r->{$key};
		my $dropped = ((defined $$value) && (ref $$value eq '')) # length undef is fatal here
			? length($$value) - $STRING_MAX_CAP
			: 0;
		$clipped{$key} = ($dropped > 0)
			? substr($$value, 0, $STRING_MAX_CAP) . "(...skipping $dropped chars...)"
			: $$value;
	}
	return \%clipped;
}

# Print the result record to the terminal (unless "quiet") and to the log
# filehandle (if one was given), and append it to the trace filehandle as one
# JSON line (if one was given). "quiet" silences only this routine chatter;
# errors still go to STDERR, since a caller that asked for less noise did not
# ask to be kept in the dark about a failure.
#
# In one of parallel()'s workers the record is written holding an flock on
# $REPORT_LOCK, so that the records of tasks running at once do not
# interleave. Until 0.192 nothing kept them apart, and a long trace line,
# which perl writes in several write()s, could be split by another worker's:
# the trace was no longer JSON lines, and report() refused it. The lock is
# on a file each worker opens for itself, since workers that share one open
# file -- the inherited log or trace handle -- share its flock too.
our $REPORT_LOCK; # undef = not in a worker; else the lock file's path
sub _report {
	my ($r, $log_fh, $quiet, $trace_fh) = @_;
	my $clipped = _clipped($r);
	my $lock;
	if (defined $REPORT_LOCK) {
		open $lock, '>>', $REPORT_LOCK or die "cannot open \"$REPORT_LOCK\" to write a record: $!";
		flock $lock, Fcntl::LOCK_EX() or die "cannot lock \"$REPORT_LOCK\" to write a record: $!";
	}
	# string_max => 0 turns Data::Printer 1.x's own clipping off: the fields
	# arrive clipped already, and a second pass would print a second
	# "skipping" mark. Older releases ignore the property either way.
	p(%$clipped, output => $log_fh, string_max => 0) if defined $log_fh;
	p(%$clipped, string_max => 0) unless $quiet;
	print {$trace_fh} _trace_line($r), "\n" if defined $trace_fh;
	if (defined $lock) {
		_flush(\*STDOUT); # the log and trace handles are autoflushed already
		close $lock; # and with it the lock
	}
	return;
}

# Fields of the record written to the trace as JSON numbers, when they look
# like one; everything else is a string. A caller's own value for a boolean
# option ("yes", say) is not a number, and is written as a string, so the line
# is valid JSON whatever the caller passed.
my %TRACE_NUMBER = map { $_ => 1 } qw(
	attempts cpu.system cpu.user die dry_run duration exit lock out.of.date
	overwrite protect quiet retries retry_delay signal source.line stale
	start.time time timed.out timeout
);
my $JSON_NUMBER = qr/\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/;

# One record as a line of JSON, in the spirit of Nextflow's trace.txt: every
# field but the captured stdout and stderr, which can be any size and are in
# the record and the log already, plus "time", when the line was written.
# JSON::PP is core only from perl 5.14, so this is written out here; it needs
# only strings, numbers, null, and arrays and hashes of those.
sub _trace_line {
	my $r = shift;
	my %line = (%$r, time => Time::HiRes::time());
	delete @line{'stdout', 'stderr'};
	return _json(\%line, 0);
}
sub _json {
	my ($value, $number) = @_; # $number: 1 = write a number-like scalar as a JSON number
	return 'null' if not defined $value;
	if (ref $value eq 'ARRAY') {
		return '[' . join(',', map { _json($_, 0) } @$value) . ']';
	}
	if (ref $value eq 'HASH') {
		# the values of a "*.size" hash are byte counts
		return '{' . join(',', map {
			_json_string($_) . ':' . _json($value->{$_},
				($number || $TRACE_NUMBER{$_} || /\.size\z/) ? 1 : 0)
		} sort keys %$value) . '}';
	}
	return $value if $number && ($value =~ $JSON_NUMBER);
	return _json_string($value);
}
# The string as JSON, in UTF-8, whatever perl holds it as. A character string
# is encoded. A byte string that is valid UTF-8 -- a filename read from the
# system, typically -- is taken to be UTF-8 already and written as it is; any
# other byte string is taken to be Latin-1 characters, as perl itself treats
# it, and encoded, so that "caf\x{e9}" is not written as a lone byte the JSON
# cannot hold. The trace filehandle should be opened without an encoding
# layer, or all of this is encoded a second time.
sub _json_string {
	my $string = shift;
	if (not utf8::is_utf8($string)) {
		my $decoded = $string;
		$string = $decoded if utf8::decode($decoded);
	}
	utf8::encode($string);
	$string =~ s/(["\\])/\\$1/g;
	$string =~ s/([\x00-\x1f])/sprintf('\\u%04x', ord $1)/ge;
	return qq{"$string"};
}

# What "env_secret" puts in place of a value it hides.
my $SECRET_SHOWN = '(secret)';

# The names "env_secret" holds, sorted and once each, as far as they can be
# read: this also runs on arguments not yet validated, for an error message.
sub _secret_names {
	my $args = shift;
	my $names = $args->{'env_secret'};
	return () if ref $names ne 'ARRAY';
	my %seen;
	return sort grep { (defined $_) && (ref $_ eq '') && (not $seen{$_}++) } @$names;
}

# A copy of the arguments, or of %DEFAULTS, that is safe to print: the "env"
# values that "env_secret" names are hidden. Only "env" is copied deeply.
sub _shown_args {
	my $args = shift;
	my %shown = %$args;
	my @secret = _secret_names($args);
	if ((ref $args->{env} eq 'HASH') && (scalar @secret > 0)) {
		my %env = %{ $args->{env} };
		foreach my $name (grep { exists $env{$_} } @secret) {
			$env{$name} = $SECRET_SHOWN if defined $env{$name}; # undef, removing one, gives nothing away
		}
		$shown{env} = \%env;
	}
	return \%shown;
}

# Print the arguments to STDERR before an error, as every argument error does,
# with the secrets hidden.
sub _dump_args {
	my $shown = _shown_args(shift);
	p $shown, output => 'STDERR';
	return;
}

# Turn Devel::Confess on -- stack traces, in colour on a terminal -- for the
# dynamic scope of the task() that calls this, which has localised every
# variable assigned here. Until 0.19 the module said "use Devel::Confess
# 'color'", which installs its __DIE__ and __WARN__ handlers globally and for
# good: every program that loaded SimpleFlow had a stack trace appended to its
# own die "message\n", so code comparing $@ with a string broke.
#
# This does what Devel::Confess 0.009004's import() does (Devel/Confess.pm,
# "sub import"), but to localised copies: the caller's handler is kept in
# %Devel::Confess::OLD_SIG, which _die and _warn call in turn, and the colour
# is its "color" option. Those are internals, not API, so if a later release
# drops _die or _warn this turns nothing on rather than dying; t/04.fixes.t
# block 9 checks that the traces are still there.
sub _confess_here {
	return if not ((defined &Devel::Confess::_die) && (defined &Devel::Confess::_warn));
	foreach my $sig (['__DIE__', \&Devel::Confess::_die], ['__WARN__', \&Devel::Confess::_warn]) {
		my ($name, $handler) = @$sig;
		# a caller that enabled Devel::Confess itself already has it here
		next if (defined $SIG{$name}) && ($SIG{$name} eq $handler);
		$Devel::Confess::OLD_SIG{$name} = $SIG{$name};
		$SIG{$name} = $handler;
	}
	$Devel::Confess::OPTIONS{color} = 1;
	return;
}

# Newest and oldest modification times among the named files, or undef when
# none of them exist. stat's mtime is used rather than -M because -M is
# measured from the interpreter's start time, which makes it useless for
# comparing against files written during the run. It is Time::HiRes's stat,
# which has the sub-second part: core stat's whole seconds made an input
# rewritten in the same second as its output look no newer, and until 0.19
# "stale" kept the out-of-date output.
# The stat is copied into an array before [9] is taken, not sliced where it
# is called: Time::HiRes 1.9719, which perl 5.10.1 and 5.12.5 ship, returns
# the wrong value for a direct slice -- (Time::HiRes::stat($f))[9] is 9 there,
# not the mtime, measured on both.
sub _mtime {
	my @stat = Time::HiRes::stat(shift);
	return $stat[9];
}
sub _newest_mtime {
	my @mtimes = map { -d $_ ? _tree_mtime($_) : _mtime($_) } grep { -e $_ } @_;
	return undef if scalar @mtimes == 0;
	return max(@mtimes);
}
sub _oldest_mtime {
	my @mtimes = map { -d $_ ? _tree_mtime($_) : _mtime($_) } grep { -e $_ } @_;
	return undef if scalar @mtimes == 0;
	return min(@mtimes);
}
# The newest mtime of a directory and anything in it: when a directory output
# was last written to, which is what "stale" compares an input against. The
# directory's own mtime changes only when an entry is added or removed, not
# when a file in it is rewritten.
sub _tree_mtime {
	my $top = shift;
	my $newest = _mtime($top);
	# File::Find warns, through its own category, on a directory it cannot
	# read; under this module's FATAL warnings that would be a die
	no warnings 'File::Find';
	File::Find::find({
		no_chdir => 1,
		wanted   => sub {
			my $mtime = _mtime($File::Find::name);
			$newest = $mtime if (defined $mtime) && ($mtime > $newest);
		},
	}, $top);
	return $newest;
}

# Fold the "<kind>_file" (a single name) and "<kind>_files" (a name or an
# array ref) forms into one list, and reject names that cannot meaningfully be
# filetested. undef and '' are caught HERE, before any -f: "-f undef" is a
# fatal warning under "warnings FATAL => 'all'" and "-f ''" is merely false,
# so until 0.16 a bad input name surfaced either as a crash inside SimpleFlow
# or as the misleading "missing or unreadable", never as the argument error
# it actually is.
sub _normalise_files {
	my ($args, $kind, $noun) = @_; # $noun: 'file' (the default) or 'dir'
	$noun //= 'file';
	my ($single, $plural) = ("${kind}_$noun", "${kind}_${noun}s");
	# The two forms are mutually exclusive: mixing them is almost always a
	# mistake (which one holds the truth?), so refuse it outright.
	if ((defined $args->{$single}) && (defined $args->{$plural})) {
		_dump_args($args);
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
			_dump_args($args);
			die "ref type \"$ref\" is not allowed for \"$plural\"";
		}
	} elsif (defined $args->{$single}) {
		$given = $single;
		my $ref = ref $args->{$single};
		if ($ref ne '') { # a single file only, never a ref
			_dump_args($args);
			die "$ref isn't allowed for \"$single\"; it takes a single filename (use \"$plural\" for a list)";
		}
		@files = ($args->{$single});
	}
	my @bad = grep { (not defined $files[$_]) || (length $files[$_] == 0) } 0 .. $#files;
	if (scalar @bad > 0) {
		_dump_args($args);
		die 'undefined or 0-length filenames are not allowed (found in "'
			. $given . '" at ' . ((scalar @bad == 1) ? 'index ' : 'indices ')
			. join(', ', @bad) . ')';
	}
	return @files;
}

# Move each existing output of a failed step to "<file>.failed" and return
# the new names. Until 0.19 a failed step's outputs were left where they were:
# a file half-written before a non-zero exit, a kill or a timeout then
# satisfied the next run's "already done" test, and the truncated file became
# the result for good. Snakemake deletes a failed job's outputs for the same
# reason; moving them keeps the partial contents for debugging. A move that
# fails is warned about rather than fatal, since the step has failed already
# and its own message is the one the caller needs.
#
# Until 0.192 each name was moved as it came, and three kinds of list lost
# data. A name given twice had its .failed deleted, as "left from before", by
# its own second pass. An output named like another's .failed, as in ['out',
# 'out.failed'], was deleted to make room for the other. And a file inside a
# directory output was renamed in place, then carried off with the directory,
# so the name reported for it did not exist. So the list is cut down first,
# to one entry for each path, and to none for a path inside a directory that
# is moved itself, which takes it along under its own name; and the longest
# names are moved first, so that "out.failed" is out of the way before "out"
# is moved onto it.
sub _move_aside {
	my %seen;
	my @unique = grep { not $seen{_canonical($_)}++ } grep { -e $_ } @_;
	my @dirs = map { _canonical($_) } grep { (-d $_) && (not -l $_) } @unique;
	my @movable = grep {
		my $path = _canonical($_);
		not grep { _is_within($path, $_) } @dirs;
	} @unique;
	my @moved;
	foreach my $file (sort { (length $b <=> length $a) || ($a cmp $b) } @movable) {
		my $aside = "$file.failed";
		# a .failed left by an earlier failure is removed first, so this
		# does not rest on rename() replacing a file on every platform, and
		# a directory output's .failed is a directory, which unlink cannot
		# remove
		if ((-d $aside) && (not -l $aside)) {
			File::Path::rmtree($aside);
		} elsif ((-e $aside) || (-l $aside)) {
			unlink $aside;
		}
		if (rename $file, $aside) {
			push @moved, $aside;
		} else {
			warn "cannot move \"$file\", an output of a failed step, to \"$aside\": $!; the next run will take it as done";
		}
	}
	return sort @moved;
}

# A path made absolute and tidied, so that "out" and "./out" compare equal.
# Only the text is compared: a symbolic link and its target are two paths.
sub _canonical {
	return File::Spec->canonpath(File::Spec->rel2abs(shift));
}

# True when $path is strictly inside directory $dir; both are _canonical.
sub _is_within {
	my ($path, $dir) = @_;
	my @path = File::Spec->splitdir($path);
	my @dir  = File::Spec->splitdir($dir);
	return 0 if scalar @path <= scalar @dir;
	foreach my $i (0 .. $#dir) {
		return 0 if $path[$i] ne $dir[$i];
	}
	return 1;
}

# Remove the write permission from each output, and from everything inside a
# directory output, as Snakemake's protected() does, so that a finished result
# is not overwritten by accident. Symbolic links are left alone: chmod would
# follow one to whatever it points at, which is not the step's to protect.
#
# On POSIX each path is opened with O_NOFOLLOW and changed through the handle,
# so that the thing tested is the thing changed. Until 0.192 the path was
# tested with -l and then chmod-ed by name, and something swapped in between
# -- a symbolic link, by anyone who can write to the output tree -- had its
# target's permission changed instead. A path that cannot be opened, such as
# a file without read permission, is still done by name; so is everything on
# MSWin32, which has neither O_NOFOLLOW nor fchmod. O_NONBLOCK keeps a FIFO
# among the outputs from blocking the open.
my $O_NOFOLLOW = eval { Fcntl::O_NOFOLLOW() } // 0; # 0 = this system has none
my $O_NONBLOCK = eval { Fcntl::O_NONBLOCK() } // 0; # 0 = this system has none
sub _protect {
	foreach my $output (@_) {
		my @paths = ($output);
		if ((-d $output) && (not -l $output)) {
			no warnings 'File::Find'; # see _tree_mtime
			File::Find::find({ no_chdir => 1, wanted => sub { push @paths, $File::Find::name } }, $output);
		}
		foreach my $path (@paths) {
			if (($^O ne 'MSWin32') && $O_NOFOLLOW
					&& (sysopen my $fh, $path, Fcntl::O_RDONLY() | $O_NOFOLLOW | $O_NONBLOCK)) {
				my $mode = (stat $fh)[2];
				chmod(($mode & 07777) & ~0222, $fh)
					or warn "cannot make \"$path\" read-only for \"protect\": $!";
				next;
			}
			next if -l $path;
			my $mode = (stat $path)[2];
			next if not defined $mode;
			chmod(($mode & 07777) & ~0222, $path)
				or warn "cannot make \"$path\" read-only for \"protect\": $!";
		}
	}
	return;
}

# Make $dir, where SimpleFlow keeps its lock files and command records, unless
# it is there, and refuse one that is a symbolic link. Until 0.192 a link was
# followed, and someone who could write to the working directory could point
# ".simpleflow" anywhere and have the files made there. The files in it are
# opened with O_NOFOLLOW, for the same reason. These guard against a link,
# not against a directory others can write to: the working directory, and the
# outputs, are to be writable only by those trusted to run the pipeline.
sub _metadata_dir {
	my ($dir, $what) = @_; # $what: what the directory is for, for the message
	if ((not -d $dir) && (not mkdir $dir) && (not -d $dir)) { # another run may make it first
		die "cannot make \"$dir\" in " . getcwd() . " for $what: $!";
	}
	die "\"$dir\" in " . getcwd() . " is a symbolic link, which is not followed for $what; make it a directory"
		if -l $dir;
	return;
}

# Take an exclusive lock for each declared output of a step, and return the
# handles holding them; the locks go when the handles do, however task()
# returns. A second run of the same pipeline that reaches the step meanwhile
# waits here, and then finds the outputs made. The lock files are in
# ".simpleflow" in the working directory, one per path, named for it, and are
# left there afterwards: removing a lock file another process is waiting on
# would let a third take a lock on a new file of the same name, and the two
# would both run. Two runs in different working directories do not see each
# other's locks, as with Snakemake's.
#
# Until 0.192 the lock was named for the output's absolute path as written,
# so two names for one file -- "out" and "sub/../out", or through a linked
# directory -- took two locks, and a directory output did not exclude a step
# whose output was a file inside it. Now an output is named for its real
# directory (Cwd::realpath) and its own name, and, when it is itself a
# symbolic link, for what that resolves to as well; and a step takes a shared
# lock on every directory above each output, which a step whose output is that
# directory locks exclusively. Hard links, which have no one name, are still
# two files here.
sub _lock_outputs {
	my ($cmd_string, @outputs) = @_;
	my %mode; # path => Fcntl::LOCK_EX() for an output, LOCK_SH() for a directory above one
	$mode{$_} = Fcntl::LOCK_EX() foreach map { _lock_names($_) } @outputs;
	foreach my $locked (keys %mode) {
		$mode{$_} //= Fcntl::LOCK_SH() foreach _ancestors($locked);
	}
	return () if scalar keys %mode == 0;
	my $lock_dir = '.simpleflow';
	_metadata_dir($lock_dir, 'the lock files of "lock"');
	my @held;
	# in sorted order, so that two runs cannot each hold a lock the other wants
	foreach my $path (sort keys %mode) {
		# md5_hex takes bytes, and until 0.192 a name with a character above
		# 255 died "Wide character in subroutine entry" here. Encoded as
		# _signature_file encodes it, which is also how perl itself hands
		# such a name to the system.
		my $bytes = $path;
		utf8::encode($bytes) if utf8::is_utf8($bytes);
		my $lock_file = File::Spec->catfile($lock_dir, md5_hex($bytes) . '.lock');
		sysopen(my $fh, $lock_file, Fcntl::O_WRONLY() | Fcntl::O_APPEND() | Fcntl::O_CREAT() | $O_NOFOLLOW)
			or die "cannot open \"$lock_file\", the lock file for \"$path\": $!";
		if (not flock $fh, $mode{$path} | Fcntl::LOCK_NB()) {
			say STDERR "waiting for another run, which holds a lock on \"$path\", to finish before running \"$cmd_string\"";
			flock $fh, $mode{$path} or die "cannot lock \"$lock_file\" for \"$path\": $!";
		}
		push @held, $fh;
	}
	return @held;
}

# The names an output is locked under: its real directory and its own name,
# and, for a symbolic link, what it resolves to.
sub _lock_names {
	my $absolute = File::Spec->canonpath(File::Spec->rel2abs(shift));
	my ($volume, $dirs, $name) = File::Spec->splitpath($absolute);
	my $parent = File::Spec->catpath($volume, $dirs, '');
	my $real_parent = (-d $parent) ? _realpath($parent) : undef;
	my @names = (defined $real_parent) ? (File::Spec->catfile($real_parent, $name)) : ($absolute);
	if (-l $absolute) {
		my $target = _realpath($absolute);
		push @names, $target if (defined $target) && ($target ne $names[0]);
	}
	return @names;
}
# Cwd::realpath, or undef where it cannot resolve the path; some versions die
# rather than return undef.
sub _realpath {
	my $path = shift;
	no warnings; # a path it cannot resolve is an undef here, not a warning
	return eval { Cwd::realpath($path) };
}
# Every directory above $path, outermost first.
sub _ancestors {
	my @parts = File::Spec->splitdir(shift);
	return grep { $_ ne '' } map { File::Spec->catdir(@parts[0 .. $_ - 1]) } 1 .. $#parts;
}

# Run $cmd in a child of its own and wait for it, as system() would, and
# return its raw wait status, a flag saying whether $timeout (seconds; 0 for
# none) was hit, why the command could not be launched ('' if it was), and
# the name of any signal that interrupted the wait, or undef. POSIX-only; on
# MSWin32 task() uses system(), and refuses "timeout".
#
# system() itself is not used, for two reasons. A $SIG{ALRM} that fires while
# system() is blocked in waitpid unwinds the Perl stack but leaves the child
# running as an orphan. And system() shields its caller from INT and QUIT only:
# a TERM or HUP sent to perl alone -- by a batch scheduler, or "kill <pid>" --
# killed perl and left the command running, until 0.19. Here each of those is
# passed on to the command, which is waited for, and the signal is then
# re-raised by task() once the record is written.
#
# The child leads a process group of its own, so that a signal can reach the
# command as a whole: a shell command is usually a pipeline, not a single
# process, and signalling only the shell leaves its children behind. Until
# 0.192 that was so only under a timeout; without one the child stayed in
# perl's group, a TERM was passed to the shell alone, and the rest of the
# pipeline ran on as orphans. perl's own group cannot be signalled instead:
# it holds whatever else the caller's shell started with perl, such as a
# "tee" its output is piped into.
#
# So perl stands in for a shell's job control. The command's group is not the
# terminal's foreground group, and a Ctrl-C or Ctrl-Z there reaches perl
# alone. With a timeout, an interrupt (HUP, INT, QUIT, TERM) kills the group,
# as the timeout does. Without one, it is passed on to the group and the
# command waited for; INT and QUIT are then not re-raised, as system() does
# not, and HUP and TERM are. A Ctrl-Z (TSTP) stops the group and perl with it,
# and both carry on when perl is continued.
#
# $foreground is true when the command's stdin is the caller's terminal. The
# command is then handed the terminal's foreground, as a shell hands it to a
# job, and perl takes it back afterwards; a Ctrl-C or Ctrl-Z then reaches the
# command alone. Until 0.19 a timed command reading the terminal was stopped
# by SIGTTIN until the timeout killed it, and reported as timed out. A command
# that opens the terminal itself -- ssh or sudo asking for a password, with
# stdin on the null device -- is stopped by SIGTTIN or SIGTTOU too, and is
# given the foreground then, as "fg" would. Stopped from the terminal (Ctrl-Z),
# a command is suspended as a shell would suspend a job: perl stops too, and on
# being continued gives the command back the terminal, if it had it, and
# continues it. The timeout does not run while it is suspended.
#
# A failed exec cannot report its errno through the exit status, so the child
# writes it down a pipe that exec closes on success -- the method perl's own
# system() uses (pp_sys.c, pp_system) -- and the command is then reported as
# system() would report it: exit -1, with the reason.
sub _run_forked {
	my ($cmd, $timeout, $foreground) = @_;
	my $timed = ($timeout > 0) ? 1 : 0;
	my $cmd_string = (ref $cmd eq 'ARRAY') ? join(' ', @$cmd) : $cmd;
	# The caller's own pending alarm, if any: "alarm $timeout" below would
	# replace it and "alarm 0" cancel it, as both did until 0.19. It is put
	# back at the end, less the time spent here.
	my $caller_alarm = $timed ? alarm(0) : 0;
	my $started = Time::HiRes::time();
	my $tty = _controlling_terminal(); # undef = perl has none
	# Only a perl in the terminal's foreground can hand it on; one in the
	# background would take it from the job that has it.
	$foreground = ($foreground && _is_foreground($tty)) ? 1 : 0;
	# The write end must close itself in the child when the exec succeeds.
	# perl marks a new descriptor close-on-exec only above $^F, and until
	# 0.192 nothing else did, so a caller that had raised $^F handed the
	# command the write end: the sysread below then waited for the command to
	# end, before the alarm was set, and "timeout" never fired.
	pipe(my $exec_failed_read, my $exec_failed_write)
		or die "cannot make a pipe to run \"$cmd_string\": $!";
	fcntl($exec_failed_write, Fcntl::F_SETFD(), Fcntl::FD_CLOEXEC())
		or die "cannot mark a pipe close-on-exec to run \"$cmd_string\": $!";
	# Held back from before the fork until the handlers below are in place.
	# The command can send one as soon as it has started, and until 0.191 one
	# that arrived before the handlers went to the caller's alone: the command
	# was neither killed nor passed it, and ran on to be reported as done. A
	# CPAN smoker (perl 5.16.3, Alpine) lost such a race in t/07.coverage.t.
	my $held = POSIX::SigSet->new(POSIX::SIGHUP(), POSIX::SIGINT(), POSIX::SIGQUIT(), POSIX::SIGTERM(), POSIX::SIGTSTP());
	my $caller_mask = POSIX::SigSet->new();
	POSIX::sigprocmask(POSIX::SIG_BLOCK(), $held, $caller_mask)
		or die "cannot block signals to run \"$cmd_string\": $!";
	my $pid = fork();
	if (not defined $pid) {
		my $error = $!;
		POSIX::sigprocmask(POSIX::SIG_SETMASK(), $caller_mask);
		_restore_alarm($caller_alarm, $started);
		die "fork() failed, so the command cannot be run: $error";
	}
	if ($pid == 0) { # the child
		close $exec_failed_read;
		setpgrp(0, 0); # lead a new process group, so that a signal reaches the whole pipeline
		_take_terminal($tty, $$) if $foreground;
		# A failed exec warns "Can't exec", which "warnings FATAL" turns into
		# a die -- and a die here unwinds into the caller's evals as a second
		# copy of the caller's program. Until 0.18 exactly that happened.
		no warnings 'exec';
		# A blocked mask survives exec. The caller's handlers become the
		# default across it, and one it ignores stays ignored, which is what
		# system() leaves its child with.
		POSIX::sigprocmask(POSIX::SIG_SETMASK(), $caller_mask);
		my $exec_ok = (ref $cmd eq 'ARRAY')
			? exec({ $cmd->[0] } @{ $cmd }) # the block form never uses the shell, even for one word
			: exec($cmd);
		# Only reached when exec itself failed. _exit, not exit: exit would
		# run END blocks and flush the parent's buffers a second time.
		syswrite $exec_failed_write, ($! + 0);
		POSIX::_exit(127); # 127 is the shell's own "command not found" status
	}
	close $exec_failed_write;
	# From both sides, as a shell does, since either may run first; the one
	# that runs before the child's setpgrp fails harmlessly.
	_take_terminal($tty, $pid) if $foreground;
	my $has_terminal = $foreground; # 1 = the command's group has the terminal's foreground
	# Returns at once with nothing when the exec succeeded, and with the
	# child's errno when it did not.
	my $got = sysread $exec_failed_read, my $errno, 16;
	close $exec_failed_read;
	if ((defined $got) && ($got > 0)) {
		waitpid $pid, 0;
		POSIX::sigprocmask(POSIX::SIG_SETMASK(), $caller_mask); # one held meanwhile goes to the caller
		_take_terminal($tty, getpgrp()) if $has_terminal;
		_restore_alarm($caller_alarm, $started);
		local $! = $errno + 0;
		return (-1, 0, "$!", undef);
	}
	# Signals that would otherwise reach perl alone. One the caller ignores
	# stays ignored, by perl and, since it is inherited, by the command.
	my @interrupts = grep { not _ignored($_) } qw(HUP INT QUIT TERM);
	my $timed_out = 0;
	my $interrupted; # undef, or the name of the signal to re-raise
	my $cut_short = 0; # 1 = the wait was ended by one of the two dies below
	my $status;
	# Stop the command and perl with it, as a shell stops a job, with the
	# clock stopped; on being continued, give the command the terminal if it
	# wants it and perl has it to give, and continue it. $wants_terminal: the
	# command had the terminal, or stopped asking for it.
	my $suspend = sub {
		my $wants_terminal = shift;
		my $left = $timed ? Time::HiRes::alarm(0) : 0;
		_take_terminal($tty, getpgrp()) if $has_terminal;
		$has_terminal = 0;
		kill 'STOP', $$;
		if ($wants_terminal && _is_foreground($tty)) {
			_take_terminal($tty, $pid);
			$has_terminal = 1;
		}
		kill 'CONT', -$pid;
		Time::HiRes::alarm($left) if $left > 0;
	};
	eval {
		# only with a timeout: otherwise an alarm is the caller's own business
		local $SIG{ALRM} = sub { $timed_out = 1; $cut_short = 1; die "SF_TIMEOUT\n" } if $timed;
		# With a timeout the command is killed below, so the wait is cut
		# short. Otherwise its group is sent the same signal, and it is waited
		# for as before: perl's waitpid resumes after a handler that returns.
		local @SIG{@interrupts} = $timed
			? (sub { $interrupted = shift; $cut_short = 1; die "SF_INTERRUPTED\n" }) x @interrupts
			: (sub {
				my $signal = shift;
				$interrupted = $signal if ($signal eq 'HUP') || ($signal eq 'TERM');
				kill $signal, -$pid;
			}) x @interrupts;
		# A Ctrl-Z at the terminal, which reaches perl alone unless the
		# command has the terminal
		local $SIG{TSTP} = sub { kill 'STOP', -$pid; $suspend->($has_terminal) } if not _ignored('TSTP');
		# one held since the fork is delivered here, to the handlers above
		POSIX::sigprocmask(POSIX::SIG_SETMASK(), $caller_mask);
		alarm $timeout if $timed;
		while (1) {
			my $waited = waitpid $pid, POSIX::WUNTRACED();
			$status = $?;
			last if not (($waited == $pid) && POSIX::WIFSTOPPED(${^CHILD_ERROR_NATIVE}));
			my $stop = POSIX::WSTOPSIG(${^CHILD_ERROR_NATIVE});
			# by a STOP from something other than the terminal, which is the
			# sender's to continue
			next if $stop == POSIX::SIGSTOP();
			my $wants_terminal = (($stop == POSIX::SIGTTIN()) || ($stop == POSIX::SIGTTOU())) ? 1 : 0;
			if ($wants_terminal && _is_foreground($tty)) { # perl has it to give, as "fg" would
				_take_terminal($tty, $pid);
				$has_terminal = 1;
				kill 'CONT', -$pid;
				next;
			}
			# a Ctrl-Z while it had the terminal, or the terminal wanted while
			# perl is in the background
			$suspend->($wants_terminal || $has_terminal);
		}
		alarm 0 if $timed;
		1;
	} or do {
		my $error = $@;
		my $reaped_status = $?; # holds the child's status if waitpid above had already returned
		alarm 0 if $timed;
		# The alarm can land after waitpid has reaped the child but before
		# "alarm 0" cancels it. The child then finished within its limit, a
		# second waitpid would return -1 and overwrite its real status, and
		# its pid is free for the kernel to hand to an unrelated process. So
		# the group is killed only if the child has not already been reaped.
		# An interrupt can land in the same window, and is treated the same.
		my $waited = waitpid $pid, POSIX::WNOHANG();
		if ($waited == -1) { # already reaped by the waitpid inside the eval
			$timed_out = 0;
			$status    = $reaped_status;
		} elsif ($waited == $pid) { # exited of its own accord at the deadline
			$timed_out = 0;
			$status    = $?;
		} else { # 0: still running, or stopped, which KILL ends as well
			kill 'KILL', -$pid; # negative pid: the process group, not just the shell
			waitpid $pid, 0;
			$status = $?;
			$timed_out = 0 if defined $interrupted; # it was the interrupt that killed it
		}
		# Anything but the two dies above -- a caller's own handler that
		# died, for an alarm of its own, say -- is passed on as it is, once
		# the command is gone. Until 0.192 the command was left running,
		# unwaited for. A flag, not the text of $@, tells them apart, since
		# Devel::Confess appends a stack trace to that.
		if (not $cut_short) {
			_take_terminal($tty, getpgrp()) if $has_terminal;
			_restore_alarm($caller_alarm, $started);
			die $error;
		}
	};
	_take_terminal($tty, getpgrp()) if $has_terminal;
	_restore_alarm($caller_alarm, $started);
	return ($status, $timed_out, '', $interrupted);
}

# True when the caller ignores signal $name; task() leaves such a signal
# ignored, as system() does.
sub _ignored {
	my $name = shift;
	return ((defined $SIG{$name}) && ($SIG{$name} eq 'IGNORE')) ? 1 : 0;
}

# A handle on perl's controlling terminal, or undef when it has none, as in a
# batch job or a daemon. Marked close-on-exec, so that the command does not
# inherit it whatever $^F is.
sub _controlling_terminal {
	return undef if $^O eq 'MSWin32';
	open my $tty, '+<', '/dev/tty' or return undef;
	fcntl($tty, Fcntl::F_SETFD(), Fcntl::FD_CLOEXEC()) or return undef;
	return $tty;
}

# True when perl's process group is the terminal's foreground group.
sub _is_foreground {
	my $tty = shift;
	return 0 if not defined $tty;
	return (POSIX::tcgetpgrp(fileno $tty) == getpgrp()) ? 1 : 0;
}

# Make process group $pgrp the foreground group of the terminal $tty. A
# process outside the foreground group that tries this is sent SIGTTOU, which
# stops it, so SIGTTOU is ignored for the call, as shells do. A failure leaves
# things as they were.
sub _take_terminal {
	my ($tty, $pgrp) = @_;
	return if not defined $tty;
	local $SIG{TTOU} = 'IGNORE';
	POSIX::tcsetpgrp(fileno $tty, $pgrp);
	return;
}

# Put back an alarm the caller had pending when _run_forked began:
# $pending seconds were left at $since. One that fell due in the meantime is
# delivered now, to the caller's own $SIG{ALRM}, since that is back in place.
sub _restore_alarm {
	my ($pending, $since) = @_;
	return if $pending == 0; # none was set
	my $left = $pending - (Time::HiRes::time() - $since);
	if ($left > 0) {
		alarm POSIX::ceil($left);
	} else {
		kill 'ALRM', $$;
	}
	return;
}

# Flush a handle's buffer without IO::Handle: setting $| true flushes at once,
# and its previous value is put back so the caller's autoflush is untouched.
sub _flush {
	my $fh = shift;
	my $previously_selected = select $fh;
	my $autoflush = $|;
	$| = 1;
	$| = $autoflush;
	select $previously_selected;
	return;
}

# Read the whole of $fh into the scalar $$into, through the translation
# layers the caller's own handle had. read() appends into the target buffer,
# and the first call asks for the whole file, so the text is allocated once,
# in the record, and never copied.
sub _slurp_into {
	my ($fh, $layers, $into) = @_;
	seek $fh, 0, 0 or die "cannot rewind a capture file: $!";
	binmode $fh; # :raw, then only the layers that translate text
	# Only these: a caller's STDOUT may be an in-memory "scalar" handle, and
	# :unix, :perlio and the like are the plumbing a temporary file already has.
	my @translating = grep { /^(?:crlf|utf8|encoding\(.*\))$/ } @$layers;
	binmode $fh, ':' . join(':', @translating) if scalar @translating > 0;
	$$into = '';
	# A length of 0 would read nothing at all, and a child the command put in
	# the background may still be writing to a file that measured empty; the
	# 64 KiB floor keeps the loop reading to the real end.
	my $chunk = max(-s $fh, 65536);
	while (1) {
		my $got = read $fh, $$into, $chunk, length $$into;
		die "cannot read a capture file: $!" if not defined $got;
		last if $got == 0;
	}
	return;
}

# Run $code with file descriptors 1 and 2 on temporary files, and read what
# landed there into $$stdout and $$stderr. Returns what $code returned.
#
# $to_file, if given, maps a descriptor (1 or 2) to a file the command's
# output is appended to instead, for "stdout_file" and "stderr_file"; its
# scalar is then left empty, since the point of those options is not to hold
# a large output in memory. One file named for both is opened once, so the
# two streams interleave in it as they would on a terminal.
#
# This replaces Capture::Tiny, which 0.17 and earlier used, for memory: it
# slurps each capture into a lexical and hands it back through several list
# copies, and perls before 5.20 have no copy-on-write to make those free.
# Measured with a command printing 100 MB on perl-5.10.1: task() peaked at
# 498 MB RSS and took 0.53 s with Capture::Tiny 0.50, and peaks at 108 MB
# and takes 0.17 s with this.
#
# The redirection is done on the descriptors, with POSIX::dup2, not on the
# STDOUT and STDERR globs, since descriptors are what a child inherits. So a
# caller that has pointed STDOUT at an in-memory scalar still has the
# command's output captured; under Capture::Tiny it went straight to the
# real fd 1.
sub _capture {
	my ($stdout, $stderr, $code, $to_file) = @_;
	$to_file //= {};
	# A caller may have closed 0, 1 or 2. Each hole is plugged with the null
	# device, so that the temporary files below cannot land on a standard
	# descriptor and be closed out from under us when it is restored.
	# POSIX::open returns the lowest free descriptor, which is $fd itself,
	# since every lower one is already open by the time the loop reaches it.
	my @plugs;
	foreach my $fd (0 .. 2) {
		my $probe = POSIX::dup($fd);
		if (defined $probe) {
			POSIX::close($probe);
			next;
		}
		my $plug = POSIX::open(File::Spec->devnull, POSIX::O_RDWR());
		die "cannot plug closed descriptor $fd with " . File::Spec->devnull . ": $!" if not defined $plug;
		push @plugs, $plug;
	}
	my %layers = (
		1 => [PerlIO::get_layers(\*STDOUT, output => 1)],
		2 => [PerlIO::get_layers(\*STDERR, output => 1)],
	);
	my (%file, %named);
	foreach my $fd (1, 2) {
		my $path = $to_file->{$fd};
		if (not defined $path) {
			$file{$fd} = File::Temp->new;
			next;
		}
		if (not defined $named{$path}) {
			open $named{$path}, '>>', $path
				or die "cannot open \"$path\" for the command's " . (($fd == 1) ? 'stdout' : 'stderr') . ": $!";
		}
		$file{$fd} = $named{$path};
	}
	# Anything the caller printed but perl has not yet written goes to the
	# terminal now, not into the command's capture.
	_flush(\*STDOUT);
	_flush(\*STDERR);
	my %saved;
	my @result;
	my $ok = eval {
		foreach my $fd (1, 2) {
			$saved{$fd} = POSIX::dup($fd);
			die "cannot save descriptor $fd: $!" if not defined $saved{$fd};
			defined POSIX::dup2(fileno $file{$fd}, $fd)
				or die "cannot redirect descriptor $fd to a capture file: $!";
		}
		@result = $code->();
		1;
	};
	my $error = $@;
	# as Capture::Tiny did, anything perl itself printed while redirected
	# belongs to the capture
	_flush(\*STDOUT);
	_flush(\*STDERR);
	foreach my $fd (sort keys %saved) {
		POSIX::dup2($saved{$fd}, $fd);
		POSIX::close($saved{$fd});
	}
	POSIX::close($_) foreach @plugs;
	die $error if not $ok;
	_slurp_into($file{1}, $layers{1}, $stdout) if not defined $to_file->{1};
	_slurp_into($file{2}, $layers{2}, $stderr) if not defined $to_file->{2};
	return @result;
}

# Run the command once, as task() has set it up, and fill in the fields of
# the record that describe that run: exit, signal, stdout, stderr, timed.out,
# duration, start.time and the CPU times. Returns the name of a signal that
# interrupted a timed run, or undef, and why the command could not be
# launched, or ''.
sub _run_once {
	my ($r, $cmd, $cmd_ref, $cmd_string, $env) = @_; # $env: the real values, which $r->{env} may hide
	# _capture redirects fd 1 and fd 2 and nothing else, as Capture::Tiny did
	# before it, so before 0.17 the command inherited the caller's fd 0. A
	# command that prompts -- "rm" over a write-protected file, "cp -i", git
	# asking for a password -- then wrote its question into the captured
	# stderr, where nobody could see it, and blocked on the terminal for an
	# answer that was never coming. With no "timeout" that hang was
	# unbounded; with one, the record blamed the clock (timed.out => 1,
	# signal => 9) for what was really a question. fd 0 therefore points at
	# the null device for the duration of the run; _run_forked's child
	# inherits fd 0 across the fork and exec just as system()'s does.
	#
	# STDIN itself is reopened rather than localised. The child inherits the
	# descriptor, and "open local *STDIN" attaches the glob to some other fd
	# while fd 0 goes on pointing at the terminal; reopening STDIN closes
	# fd 0, so the new open reclaims it as the lowest free descriptor.
	#
	# That holds only when STDIN is fd 0, or closed. A caller's STDIN can be
	# an in-memory scalar, whose fileno is -1, or some other descriptor; until
	# 0.192 such a STDIN was saved with "<&" as well, which perl 5.44.0 could
	# not reopen, and task() died "cannot restore STDIN" after the command
	# had run. Then the glob is not the command's stdin anyway, so it is left
	# alone, and fd 0 itself is pointed at the null device and put back.
	my $stdin_fd = fileno STDIN; # undef = closed, -1 = no descriptor, else the descriptor
	my $stdin_is_fd0 = ((not defined $stdin_fd) || ($stdin_fd == 0)) ? 1 : 0; # 1 = reopen the glob
	my ($saved_stdin, $saved_fd0); # $saved_fd0: undef = fd 0 was closed
	if (($r->{stdin} eq 'devnull') && $stdin_is_fd0) {
		# a caller may legitimately have closed STDIN: there is then nothing
		# to save, and it is closed again below rather than restored
		if (defined $stdin_fd) {
			open $saved_stdin, '<&', \*STDIN
				or die "cannot save STDIN before running \"$cmd_string\": $!";
		}
		open STDIN, '<', File::Spec->devnull
			or die 'cannot reopen STDIN on ' . File::Spec->devnull . ": $!";
	} elsif ($r->{stdin} eq 'devnull') {
		$saved_fd0 = POSIX::dup(0);
		my $null = POSIX::open(File::Spec->devnull, POSIX::O_RDONLY());
		die 'cannot open ' . File::Spec->devnull . " for the command's stdin: $!" if not defined $null;
		if ($null != 0) { # 0 itself when fd 0 was closed, as the lowest free descriptor
			defined POSIX::dup2($null, 0) or die 'cannot point descriptor 0 at ' . File::Spec->devnull . ": $!";
			POSIX::close($null);
		}
	}
	# "env": the command's environment is the caller's with these changes,
	# and the caller's is put back when this returns. %ENV is localised only
	# when there is something to change, so that a task without "env" does
	# not touch the environment at all.
	local %ENV = %ENV if (scalar keys %$env > 0) || ($r->{threads} > 0);
	foreach my $name (keys %$env) {
		if (defined $env->{$name}) {
			$ENV{$name} = $env->{$name};
		} else {
			delete $ENV{$name}; # undef: the command runs without it
		}
	}
	# "threads", told to the command, as Snakemake's {threads} is: the command
	# decides what to do with it, since only it knows its own option for it
	$ENV{SIMPLEFLOW_THREADS} = $r->{threads} if $r->{threads} > 0;
	my %to_file;
	$to_file{1} = $r->{'stdout_file'} if $r->{'stdout_file'} ne '';
	$to_file{2} = $r->{'stderr_file'} if $r->{'stderr_file'} ne '';
	my @cpu_before = times;
	my $t0 = Time::HiRes::time();
	$r->{'start.time'} = $t0;
	my @run_result;
	# Wrapped in eval so that fd 0 is restored even when the run dies --
	# _run_forked dies if fork() fails -- rather than leaving a caller
	# that traps the exception without its stdin.
	my $run_ok = eval {
		@run_result = _capture(\$r->{stdout}, \$r->{stderr}, sub {
			# The command gets the terminal's foreground only when it has the
			# terminal as its stdin, the one case where it could need it.
			return _run_forked($cmd, $r->{timeout},
				(($r->{stdin} eq 'inherit') && (-t STDIN)) ? 1 : 0) if $^O ne 'MSWin32';
			# MSWin32: system(), which forks before it execs, and when the exec
			# fails its child warns "Can't exec" -- which "warnings FATAL"
			# makes a die, in the forked child, inside this eval. Until 0.18
			# that child unwound out of task() and ran the rest of the
			# caller's program as a second copy, while the parent read the
			# copy's exit status: a command that did not exist was reported
			# as exit 0, "done".
			no warnings 'exec';
			# The block form never uses the shell, even for a one-element list.
			# Until 0.18 plain system(@list) was used, and perl hands a list of
			# one to the shell: cmd => ['echo hi; rm x'] ran both commands.
			my $raw_status = ($cmd_ref eq 'ARRAY')
				? system({ $cmd->[0] } @{ $cmd })
				: system($cmd);
			# $! says why a -1 happened, and is read here, before _capture's
			# own system calls can overwrite it. Until 0.19 it was thrown away.
			return ($raw_status, 0, ($raw_status == -1) ? "$!" : '');
		}, \%to_file);
		1;
	};
	my $run_error = $@;
	my $t1 = Time::HiRes::time();
	my @cpu_after = times;
	if (($r->{stdin} eq 'devnull') && (not $stdin_is_fd0)) {
		if (defined $saved_fd0) {
			defined POSIX::dup2($saved_fd0, 0)
				or die "cannot restore descriptor 0 after running \"$cmd_string\": $!";
			POSIX::close($saved_fd0);
		} else {
			POSIX::close(0); # it was closed when we were called; leave it that way
		}
	} elsif ($r->{stdin} eq 'devnull') {
		if (defined $saved_stdin) {
			open STDIN, '<&', $saved_stdin
				or die "cannot restore STDIN after running \"$cmd_string\": $!";
			close $saved_stdin;
		} else {
			close STDIN; # it was closed when we were called; leave it that way
		}
	}
	die $run_error if not $run_ok;
	$r->{duration} = $t1 - $t0;
	# The children's user and system time, which counts every descendant the
	# command waited for. times() counts in clock ticks, 1/100 s on Linux
	# (sysconf(_SC_CLK_TCK) is 100 on perl 5.10.1 and 5.44.0 here), so the
	# difference is rounded to the millisecond to drop the float noise of
	# subtracting two tick counts, without losing anything a tick can say.
	$r->{'cpu.user'}   = sprintf('%.3f', $cpu_after[2] - $cpu_before[2]) + 0;
	$r->{'cpu.system'} = sprintf('%.3f', $cpu_after[3] - $cpu_before[3]) + 0;
	# $interrupted: undef, or the name of a signal ('INT', 'TERM', ...) that
	# arrived while a timed command ran; $launch_error: '', or why system()
	# could not start the command
	my ($status, $timed_out, $launch_error, $interrupted) = @run_result;
	$launch_error //= '';
	$r->{'timed.out'} = $timed_out ? 1 : 0;
	# Decode the raw wait status. On Unix the low 7 bits hold the death
	# signal and the high byte holds the exit code. The signal MUST be read
	# from the raw status *before* shifting -- the old code shifted first and
	# then did ($exit & 127), so the signal was always 0 and could never
	# detect a kill by signal 9/15. Windows has no POSIX signals, and a -1
	# return from system() means the command never launched.
	if (!defined $status || $status == -1) {
		$r->{'exit'}   = -1;
		$r->{signal}   = 0;
	} elsif ($^O eq 'MSWin32') {
		$r->{signal}   = 0;
		$r->{'exit'}   = $status >> 8;
	} else {
		$r->{signal}   = $status & 127; # taken from the raw status, not from the exit code
		$r->{'exit'}   = $status >> 8;
	}
	# Remove trailing whitespace. This walks back from the end rather than
	# using s/\s+$//, as 0.17 did, which scans forward from the start of the
	# capture and, on a perl with copy-on-write, copies the whole of it first.
	# Measured on a 100 MB stdout: 0.09 s on perl-5.10.1, and on 5.44.0 0.13 s
	# and peak RSS 107 MB -> 205 MB, to remove one newline. The walk costs
	# only the whitespace it removes.
	foreach my $std ('stderr', 'stdout') {
		my $end = length $r->{$std};
		$end-- while ($end > 0) && (substr($r->{$std}, $end - 1, 1) =~ /\s/);
		substr($r->{$std}, $end) = '';
	}
	# Nothing ran, so nothing wrote to stderr; what a shell would have said
	# there is the next best thing, and the one place a caller under die => 0
	# can read it.
	$r->{stderr} = "cannot run \"$cmd_string\": $launch_error"
		if ($launch_error ne '') && ($r->{stderr} eq '') && ($r->{'stderr_file'} eq '');
	return ($interrupted, $launch_error);
}

# True when a directory holds nothing but "." and "..". One that cannot be
# read is not called empty: that is a different problem, and not this one's.
sub _is_empty_dir {
	my $path = shift;
	opendir(my $dh, $path) or return 0;
	my @entries = grep { !/\A\.\.?\z/ } readdir $dh;
	closedir $dh;
	return (scalar @entries == 0) ? 1 : 0;
}

# The command as it is actually run, as an array ref of words, when it is to
# run inside something -- an executor, a container, a conda environment, a
# wrapper -- or undef when it runs as it is. The layers nest in that order,
# outermost first: the executor starts the container, the container runs
# conda, and conda runs the wrapper, which runs the command. A string command
# keeps its shell features by being handed to the shell inside all of them.
sub _wrapped_cmd {
	my ($r, $cmd) = @_;
	my @layers;
	if ($r->{executor} eq 'slurm') {
		# srun blocks until the job step ends, and passes its exit status on,
		# so task() waits for it and reads it as for any other command
		push @layers, 'srun',
			(($r->{threads} > 0) ? "--cpus-per-task=$r->{threads}" : ()),
			(($r->{mem} ne '')   ? "--mem=$r->{mem}"               : ()),
			(($r->{walltime} ne '') ? "--time=$r->{walltime}"       : ()),
			@{ $r->{'executor_args'} };
	}
	if ($r->{container} ne '') {
		my $cwd = $r->{dir}; # the step's working directory, mounted at the same path
		if (($r->{'container_engine'} eq 'docker') || ($r->{'container_engine'} eq 'podman')) {
			push @layers, $r->{'container_engine'}, 'run', '--rm',
				(($r->{stdin} eq 'inherit') ? '-i' : ()),
				# docker runs as root unless told otherwise, and a file root
				# makes in the mounted directory is root's; podman, rootless,
				# maps the caller's own user already
				(($r->{'container_engine'} eq 'docker') && ($^O ne 'MSWin32')
					? ('--user', $> . ':' . (split ' ', $))[0]) : ()),
				'-v', "$cwd:$cwd", '-w', $cwd,
				# the variables "env" and "threads" set, by name: the engine
				# copies each value from its own environment, which is the
				# command's
				(map { ('-e', $_) } grep { defined $r->{env}{$_} } sort keys %{ $r->{env} }),
				(($r->{threads} > 0) ? ('-e', 'SIMPLEFLOW_THREADS') : ()),
				@{ $r->{'container_args'} }, $r->{container};
		} else { # singularity and apptainer, which pass the environment through themselves
			push @layers, $r->{'container_engine'}, 'exec', '--bind', $cwd, '--pwd', $cwd,
				@{ $r->{'container_args'} }, $r->{container};
		}
	}
	if ($r->{'conda_env'} ne '') {
		# --no-capture-output, or conda holds the command's output back until
		# it ends; a path names a prefix, anything else an environment's name
		push @layers, 'conda', 'run', '--no-capture-output',
			(($r->{'conda_env'} =~ m{[/\\]}) ? '-p' : '-n'), $r->{'conda_env'};
	}
	push @layers, @{ $r->{wrapper} };
	return undef if scalar @layers == 0;
	return [@layers, @$cmd] if ref $cmd eq 'ARRAY';
	return [@layers, ($^O eq 'MSWin32') ? ('cmd.exe', '/c', $cmd) : ('/bin/sh', '-c', $cmd)];
}

# What "stale_cmd" compares: a digest of everything that decides what the
# command does, other than its inputs -- the command, whether it went to a
# shell, the environment it was given, and what it runs inside. Separated by
# NUL, which cannot occur in a command's words or the environment, so that
# ['a b'] and ['a', 'b'] differ.
#
# What it runs inside went in as "wrapped.cmd", which is space-joined, so
# until 0.192 a wrapper of ['w', 'a b'] and one of ['w', 'a', 'b'] had the
# same digest. The words of those layers -- $run_cmd, less the command's own
# part -- are now added with their boundaries, but only when one of them holds
# a space: without one, the space-joined form is already unambiguous, and
# leaving the digest as it was keeps every digest 0.191 recorded valid, so an
# upgrade does not re-run every "stale_cmd" step. Likewise "threads", which
# reaches a local command only as SIMPLEFLOW_THREADS, is added only when it
# is set; under SLURM it is in srun's --cpus-per-task already.
sub _command_signature {
	my ($r, $cmd, $run_cmd) = @_;
	my @parts = (ref $cmd eq 'ARRAY') ? ('list', @$cmd) : ('string', $cmd);
	push @parts, 'env', map { (defined $r->{env}{$_}) ? "$_=$r->{env}{$_}" : $_ } sort keys %{ $r->{env} };
	push @parts, 'wrapped', $r->{'wrapped.cmd'};
	if ($r->{'wrapped.cmd'} ne '') {
		# a string command is the last word, after the shell and its -c
		my $own_words = (ref $cmd eq 'ARRAY') ? scalar @$cmd : 1;
		my @layers = @{ $run_cmd }[0 .. $#$run_cmd - $own_words];
		push @parts, 'layers', @layers if grep { / / } @layers;
	}
	push @parts, 'threads', $r->{threads} if ($r->{threads} > 0) && ($r->{executor} ne 'slurm');
	my $joined = join "\0", @parts;
	utf8::encode($joined) if utf8::is_utf8($joined); # md5_hex takes bytes
	return md5_hex($joined);
}
# Where the command that made a set of outputs is kept: .simpleflow/cmd/ in
# the working directory, as the lock files are, one file per set of outputs,
# named for their absolute paths.
sub _signature_file {
	my @absolute = sort map { File::Spec->rel2abs($_) } @_;
	my $joined = join "\0", @absolute;
	utf8::encode($joined) if utf8::is_utf8($joined);
	return File::Spec->catfile('.simpleflow', 'cmd', md5_hex($joined));
}
sub _read_signature {
	my $file = shift;
	# not through a symbolic link; see _metadata_dir
	foreach my $dir ('.simpleflow', File::Spec->catdir('.simpleflow', 'cmd')) {
		die "\"$dir\" in " . getcwd() . ' is a symbolic link, which is not followed for the command records of "stale_cmd"; make it a directory'
			if -l $dir;
	}
	sysopen(my $fh, $file, Fcntl::O_RDONLY() | $O_NOFOLLOW) or return undef; # none on record
	my $signature = <$fh>;
	close $fh;
	return undef if not defined $signature;
	chomp $signature;
	return $signature;
}
sub _write_signature {
	my ($file, $signature) = @_;
	my ($volume, $dirs) = File::Spec->splitpath($file);
	# canonpath, to drop the trailing slash, through which -l would follow a link
	my $dir = File::Spec->canonpath(File::Spec->catpath($volume, $dirs, ''));
	_metadata_dir('.simpleflow', 'the command records of "stale_cmd"');
	_metadata_dir($dir, 'the command records of "stale_cmd"');
	# Written under another name and renamed into place, so that a run killed
	# part-way through never leaves half a signature, which would read as a
	# changed command. The other name is File::Temp's, made with O_EXCL: until
	# 0.192 it was "<file>.<pid>", opened with truncation, which followed a
	# link planted under that predictable name. rename() replaces a link at
	# $file itself, rather than following it.
	my $partial = File::Temp->new(DIR => $dir, TEMPLATE => 'partial-XXXXXXXX', UNLINK => 0);
	my $partial_name = $partial->filename;
	my $ok = (print {$partial} "$signature\n") && (close $partial) && (rename $partial_name, $file);
	if (not $ok) {
		my $error = $!;
		unlink $partial_name;
		die "cannot record the command for \"stale_cmd\" in \"$file\": $error";
	}
	return;
}

# The last lines of a failed command's stderr, for the end of the message
# that reports it: the lines that usually say what went wrong. Six, because
# that is what the failures measured needed, run here: a make over a failing
# compile puts the compiler's "error:" line 5th from the end, after the source
# line, the caret and a note, with make's own "Error 1" last; a Python
# traceback needs its last 4 for the failing frame and the exception; perl's
# die, sort and R's stop() need 1 or 2. Each is clipped at 300 characters: the
# longest line in those, a traceback's "File ..." line, was 130. Blank lines
# are skipped. Read back from stderr_file when that is where stderr went, from
# its last 64 KiB, far more than 6 lines of 300 need.
my $STDERR_TAIL_LINES = 6;
my $STDERR_TAIL_WIDTH = 300;
sub _stderr_tail {
	my $r = shift;
	my $text = $r->{stderr};
	if ($r->{'stderr_file'} ne '') {
		$text = '';
		if (open my $fh, '<', $r->{'stderr_file'}) {
			my $size = -s $fh;
			seek $fh, (($size > 65536) ? $size - 65536 : 0), 0;
			local $/;
			$text = <$fh> // '';
			close $fh;
		}
	}
	my @lines = grep { /\S/ } split /\r?\n/, $text;
	@lines = @lines[-$STDERR_TAIL_LINES .. -1] if scalar @lines > $STDERR_TAIL_LINES;
	return map {
		(length $_ > $STDERR_TAIL_WIDTH) ? substr($_, 0, $STDERR_TAIL_WIDTH) . '...' : $_
	} @lines;
}

# Every reason a run failed, for the one message that reports it. Until 0.19
# the reasons were tried in turn and the missing-output one came first, so a
# step that exited non-zero, or timed out, and left an output missing died
# saying only that the output was missing.
sub _why_failed {
	my ($r, $interrupted, $launch_error, @missing) = @_;
	my @why;
	if ($r->{'timed.out'}) {
		push @why, "was killed after exceeding its $r->{timeout}s timeout";
	} elsif (defined $interrupted) {
		push @why, "was killed when task() received SIG$interrupted";
	} elsif ($r->{signal}) {
		push @why, "was killed by signal $r->{signal}";
	}
	if ($r->{'exit'} == -1) {
		push @why, 'exited -1: it could not be launched' . (($launch_error ne '') ? " ($launch_error)" : '');
	} elsif ($r->{'exit'} != 0) {
		push @why, "exited $r->{'exit'}";
	}
	if (scalar @missing > 0) {
		push @why, 'these output files should have been made but are missing: ' . join(', ', @missing);
	}
	return @why;
}

sub task {
	# Devel::Confess for this call and nothing after it: see _confess_here.
	# First, so that even the argument errors below carry a trace.
	local $SIG{__DIE__}  = $SIG{__DIE__};
	local $SIG{__WARN__} = $SIG{__WARN__};
	local $Devel::Confess::OLD_SIG{__DIE__}  = $Devel::Confess::OLD_SIG{__DIE__};
	local $Devel::Confess::OLD_SIG{__WARN__} = $Devel::Confess::OLD_SIG{__WARN__};
	local $Devel::Confess::OPTIONS{color}    = $Devel::Confess::OPTIONS{color};
	_confess_here();
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	# Accept either a single hash ref -- task({ cmd => ... }) -- or a flat
	# key/value list -- task(cmd => ...). A lone non-hashref scalar, or an
	# odd-length list, can't be read either way and is fatal.
	my $given;
	if (@_ == 1 && ref $_[0] eq 'HASH') {
		$given = $_[0];
	} elsif (@_ % 2 == 0) {
		$given = { @_ };
	} else {
		die "args to $current_sub must be a hash ref (e.g. $current_sub({ cmd => ... })) or a flat key/value list (e.g. $current_sub(cmd => ...)); got an odd-length list";
	}
	# parallel() runs each task in a child of its own, where the caller would
	# be parallel() itself; it sets $CALLER to its own caller instead
	my @c = (defined $CALLER) ? ('main', @$CALLER) : caller;
	my @reqd_args = (
		'cmd', # the shell command
	);
	my @undef_args = grep { !defined $given->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args, output => 'STDERR';
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args,
		'conda_env',   # name or path of a conda environment to run the command in
		'container',   # container image to run the command in
		'container_args',   # array ref: more arguments for the container engine, before the image
		'container_engine', # 'docker' (the default), 'podman', 'singularity' or 'apptainer'
		'die',			# die if not successful; 0 or 1
		'dir',         # directory to run the step in; its file names are relative to it
		'dry_run',     # dry run or not
		'env',         # hash ref: environment variables for the command; undef removes one
		'env_secret',  # array ref: names in "env" whose values are never printed, logged or traced
		'executor',    # 'local' (the default) or 'slurm': where the command runs
		'executor_args', # array ref: more arguments for the executor (srun)
		'input_dir',   # a single input directory; the convenience form of "input_dirs"
		'input_dirs',  # directories that must exist before running; SCALAR or ARRAY
		'input_file',  # a single input file; the convenience form of "input_files"
		'input_files', # check for input files; SCALAR or ARRAY
		'lock',        # bool; hold a lock on the outputs, so a second run waits for this one
		'log_fh',
		'mem',         # memory to ask the executor for: a number, and K, M, G or T
		'note',        # a note for the log
		'on_failure',  # code ref, called with the record when the command ran and failed
		'on_success',  # code ref, called with the record when the command ran and succeeded
		'output_dir',  # a single output directory; the convenience form of "output_dirs"
		'output_dirs', # directories the step makes; SCALAR or ARRAY
		'output_file', # for a single file, gets pushed into output_files anyway
		'output_files',# product files that need to be checked; can be scalar or array
		'overwrite',   # bool
		'protect',     # bool; make the outputs read-only once the step succeeds
		'quiet',       # bool; suppress the terminal record, but never the log or STDERR
		'retries',     # whole number; run a FAILED step again up to this many times
		'retry_delay', # seconds, may be fractional; the wait before each retry
		'stale',       # bool; also re-run when an input is newer than an output
		'stale_cmd',   # bool; also re-run when the command differs from the one that made the outputs
		'stderr_file', # file to write the command's stderr to, instead of the record
		'stdin',       # 'devnull' (the default) or 'inherit'; what the command sees on fd 0
		'stdout_file', # file to write the command's stdout to, instead of the record
		'threads',     # whole number: CPUs the command uses; told to it, and asked of the executor
		'timeout',     # whole seconds of wall clock; 0 means no limit
		'trace_fh',    # filehandle; one line of JSON per task is appended to it
		'walltime',    # time to ask the executor for, as SLURM writes it: [days-]hours:minutes:seconds
		'wrapper',     # array ref: a command the command is run inside, as its arguments
	);
	# Keys that name one particular step, and so make no sense in %DEFAULTS:
	# every task would then run the same command, or claim the same files.
	my @PER_STEP_KEYS = qw(cmd input_dir input_dirs input_file input_files output_dir
		output_dirs output_file output_files stderr_file stdout_file);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $given };
	if (scalar @bad_args > 0) {
		p @bad_args, array_max => scalar @bad_args, output => 'STDERR';
		say STDERR "the above arguments are not recognized by $current_sub";
		p @defined_args, array_max => scalar @defined_args, output => 'STDERR';
		die "The above args are accepted by $current_sub";
	}
	my @bad_defaults = grep {
		my $key = $_;
		(not grep { $_ eq $key } @defined_args) || (grep { $_ eq $key } @PER_STEP_KEYS)
	} sort keys %DEFAULTS;
	if (scalar @bad_defaults > 0) {
		_dump_args(\%DEFAULTS);
		die '%SimpleFlow::DEFAULTS holds ' . join(', ', map { "\"$_\"" } @bad_defaults)
			. ', which it cannot: a default must be a key task() accepts, and not one that names a particular step ('
			. join(', ', @PER_STEP_KEYS) . ')';
	}
	# The arguments this call runs with: its own, then %DEFAULTS for any it
	# left undefined. A copy, so that the caller's hash is never written to.
	my $args = { %$given };
	foreach my $key (keys %DEFAULTS) {
		$args->{$key} = $DEFAULTS{$key} if not defined $args->{$key};
	}
	if ((ref $DEFAULTS{env} eq 'HASH') && (ref $given->{env} eq 'HASH')) {
		$args->{env} = { %{ $DEFAULTS{env} }, %{ $given->{env} } }; # the task's own win
	}
	# and a secret of the pipeline's stays one in a task that names its own
	if ((ref $DEFAULTS{'env_secret'} eq 'ARRAY') && (ref $given->{'env_secret'} eq 'ARRAY')) {
		$args->{'env_secret'} = [@{ $DEFAULTS{'env_secret'} }, @{ $given->{'env_secret'} }];
	}
	foreach my $key ('log_fh', 'trace_fh') {
		if ((defined $args->{$key}) && (not openhandle($args->{$key}))) {
			_dump_args($args);
			die "the \"$key\" given to $current_sub isn't actually a filehandle";
		}
		_autoflush($args->{$key}) if defined $args->{$key};
	}

	# "cmd" is either a string handed to the shell, or an array ref that is
	# run without a shell (so no quoting or metacharacter surprises). Until
	# 0.16 only definedness was checked, and any other reference was
	# stringified straight into the shell: task(cmd => ['echo','hi']) ran the
	# literal command "ARRAY(0x5ed9d076e618)".
	my $cmd_ref = ref $args->{cmd};
	if (($cmd_ref ne '') && ($cmd_ref ne 'ARRAY')) {
		_dump_args($args);
		die "\"cmd\" must be a string or an array ref, not a $cmd_ref";
	}
	if ($cmd_ref eq 'ARRAY') {
		if (scalar @{ $args->{cmd} } == 0) {
			_dump_args($args);
			die '"cmd" is an empty array ref; there is no command to run';
		}
		my @undefined_words = grep { not defined $args->{cmd}[$_] } 0 .. $#{ $args->{cmd} };
		if (scalar @undefined_words > 0) {
			_dump_args($args);
			die '"cmd" array ref holds undefined elements at index/indices ' . join(', ', @undefined_words);
		}
	} elsif (length $args->{cmd} == 0) {
		_dump_args($args);
		die '"cmd" is the empty string; there is no command to run';
	}
	# The printable form of the command, used in every message and stored as
	# the record's "cmd". An array-ref command is shown space-joined, which is
	# readable but is NOT a shell-quoted round trip: it was never passed to a
	# shell in the first place.
	my $cmd_string = ($cmd_ref eq 'ARRAY') ? join(' ', @{ $args->{cmd} }) : $args->{cmd};

	if (defined $args->{timeout}) {
		# ASCII digits to the very end: /^\d+$/, until 0.19, let through a
		# trailing newline, which $ matches before, and any Unicode digit,
		# which then died "isn't numeric" instead of with this message
		if ($args->{timeout} !~ /\A[0-9]+\z/) {
			_dump_args($args);
			die '"timeout" must be a whole number of seconds (0 means no limit)';
		}
		if (($args->{timeout} > 0) && ($^O eq 'MSWin32')) {
			_dump_args($args);
			die '"timeout" is not supported on MSWin32: it needs fork() and POSIX process groups to kill the command';
		}
	}
	if ((defined $args->{retries}) && ($args->{retries} !~ /\A[0-9]+\z/)) {
		_dump_args($args);
		die '"retries" must be a whole number (0 means no retries)';
	}
	if ((defined $args->{'retry_delay'}) && ($args->{'retry_delay'} !~ /\A[0-9]+(?:\.[0-9]+)?\z/)) {
		_dump_args($args);
		die '"retry_delay" must be a number of seconds, 0 or more';
	}
	if (defined $args->{stdin}) {
		if (($args->{stdin} ne 'devnull') && ($args->{stdin} ne 'inherit')) {
			_dump_args($args);
			die "\"stdin\" must be \"devnull\" (the default) or \"inherit\", not \"$args->{stdin}\"";
		}
	}
	if (defined $args->{env}) {
		if (ref $args->{env} ne 'HASH') {
			_dump_args($args);
			die '"env" must be a hash ref of variable names and values';
		}
		# no '=' or NUL in a name, since the environment is "NAME=value\0"
		# strings; a value is a string, or undef to remove the variable
		my @bad_names  = grep { ($_ eq '') || /[=\0]/ } sort keys %{ $args->{env} };
		my @bad_values = grep { ref $args->{env}{$_} ne '' } sort keys %{ $args->{env} };
		if ((scalar @bad_names > 0) || (scalar @bad_values > 0)) {
			_dump_args($args);
			die '"env" can hold only names without "=" and string (or undef) values; these cannot be set: '
				. join(', ', map { "\"$_\"" } @bad_names, @bad_values);
		}
	}
	if (defined $args->{'env_secret'}) {
		my $names = $args->{'env_secret'};
		if ((ref $names ne 'ARRAY') || (grep { (not defined $_) || (ref $_ ne '') || ($_ eq '') || /[=\0]/ } @$names)) {
			_dump_args($args);
			die '"env_secret" must be an array ref of the names of environment variables';
		}
	}
	foreach my $key ('on_success', 'on_failure') {
		if ((defined $args->{$key}) && (ref $args->{$key} ne 'CODE')) {
			_dump_args($args);
			die "\"$key\" must be a code ref, which is called with the record";
		}
	}
	foreach my $key ('wrapper', 'container_args', 'executor_args') {
		next if not defined $args->{$key};
		my $list = $args->{$key};
		if ((ref $list ne 'ARRAY')
				|| (($key eq 'wrapper') && (scalar @$list == 0))
				|| (grep { (not defined $_) || (ref $_ ne '') } @$list)) {
			_dump_args($args);
			die "\"$key\" must be an array ref of words"
				. (($key eq 'wrapper') ? ', at least one, the program that runs the command' : '');
		}
	}
	# the values SLURM itself accepts: sbatch(1), "--mem" and "--time"
	my %pattern = (
		threads    => [qr/\A[1-9][0-9]*\z/, 'a whole number of CPUs, 1 or more'],
		mem        => [qr/\A[0-9]+[KMGT]?\z/, 'an amount of memory: a number, then K, M, G or T'],
		walltime   => [qr/\A(?:[0-9]+-)?[0-9]+(?::[0-9]{1,2}){0,2}\z/, 'a time limit, [days-]hours:minutes:seconds or minutes'],
		executor   => [qr/\A(?:local|slurm)\z/, '"local" or "slurm"'],
		'container_engine' => [qr/\A(?:docker|podman|singularity|apptainer)\z/, '"docker", "podman", "singularity" or "apptainer"'],
		container  => [qr/\A\S+\z/, 'the name of an image'],
		'conda_env' => [qr/\A\S+\z/, 'the name or path of a conda environment'],
	);
	foreach my $key (sort keys %pattern) {
		next if not defined $args->{$key};
		if ((ref $args->{$key} ne '') || ($args->{$key} !~ $pattern{$key}[0])) {
			_dump_args($args);
			die "\"$key\" must be $pattern{$key}[1]";
		}
	}
	if ((defined $args->{'executor_args'}) && (($args->{executor} // 'local') eq 'local')) {
		_dump_args($args);
		die '"executor_args" needs an executor other than "local" to be given to';
	}
	if ((defined $args->{'container_args'}) && (not defined $args->{container})) {
		_dump_args($args);
		die '"container_args" needs a "container" to be given to';
	}
	foreach my $key ('dir', 'stdout_file', 'stderr_file') {
		next if not defined $args->{$key};
		if ((ref $args->{$key} ne '') || (length $args->{$key} == 0)) {
			_dump_args($args);
			die "\"$key\" must be a path, not " . ((ref $args->{$key} ne '') ? 'a reference' : 'the empty string');
		}
	}
	# "dir": the step runs there, and every name it declares is relative to
	# it, as a command run there would see it. The caller is put back where it
	# was when this call returns, however it returns.
	my $back_to_caller_dir;
	if (defined $args->{dir}) {
		my $caller_dir = getcwd();
		if (not chdir $args->{dir}) {
			my $error = $!;
			_dump_args($args);
			die "cannot run in \"dir\" \"$args->{dir}\": $error";
		}
		$back_to_caller_dir = SimpleFlow::Guard->new(sub {
			chdir $caller_dir or warn "cannot go back to \"$caller_dir\" after running in \"dir\": $!";
		});
	}

	# The file and directory lists are normalised, and their names validated,
	# before any filetest touches them.
	my @input_files  = _normalise_files($args, 'input');
	my @input_dirs   = _normalise_files($args, 'input', 'dir');
	my @output_files = _normalise_files($args, 'output');
	my @output_dirs  = _normalise_files($args, 'output', 'dir');
	my @outputs = (@output_files, @output_dirs);

	my %r = (
		cmd            => $cmd_string,
		dir				=> getcwd(),
		'source.file'  => $c[1],
		'source.line'  => $c[2],
		'output_files' => [@output_files],
		'output_dirs'  => [@output_dirs],
		'input_dirs'   => [@input_dirs],
	);
	$r{'die'}     = $args->{'die'}     // 1; # by default, true
	$r{'dry_run'} = $args->{'dry_run'} // 0; # by default, false
	# The environment the command is given; the record's "env" is this with
	# the values "env_secret" names hidden, since the record is printed,
	# logged and traced. Until 0.192 every value was written out in full.
	my %command_env = %{ $args->{env} // {} }; # by default, no changes; a copy, not the caller's hash
	$r{'env_secret'} = [_secret_names($args)]; # by default, none
	$r{env}       = _shown_args({ env => \%command_env, 'env_secret' => $r{'env_secret'} })->{env};
	$r{lock}      = ($args->{lock}    // 0) ? 1 : 0; # by default, false
	$r{note}      = $args->{note}      // '';# by default, no note
	$r{overwrite} = $args->{overwrite} // 0; # by default, false
	$r{protect}   = ($args->{protect} // 0) ? 1 : 0; # by default, false
	$r{quiet}     = $args->{quiet}     // 0; # by default, false
	$r{retries}   = $args->{retries}   // 0; # by default, one attempt only
	$r{'retry_delay'} = $args->{'retry_delay'} // 0; # by default, retry at once
	$r{stale}     = $args->{stale}     // 0; # by default, false
	$r{'stderr_file'} = $args->{'stderr_file'} // ''; # '' = captured into the record's "stderr"
	$r{stdin}     = $args->{stdin}     // 'devnull'; # by default, the null device
	$r{'stdout_file'} = $args->{'stdout_file'} // ''; # '' = captured into the record's "stdout"
	$r{timeout}   = $args->{timeout}   // 0; # by default, no limit
	$r{'stale_cmd'} = ($args->{'stale_cmd'} // 0) ? 1 : 0; # by default, false
	$r{wrapper}   = [@{ $args->{wrapper} // [] }]; # by default, none
	$r{container} = $args->{container} // ''; # '' = no container
	$r{'container_engine'} = $args->{'container_engine'} // (($r{container} ne '') ? 'docker' : ''); # '' = no container
	$r{'container_args'} = [@{ $args->{'container_args'} // [] }];
	$r{'conda_env'} = $args->{'conda_env'} // ''; # '' = no conda environment
	$r{executor}  = $args->{executor}  // 'local'; # by default, run here
	$r{'executor_args'} = [@{ $args->{'executor_args'} // [] }];
	$r{threads}   = $args->{threads}   // 0; # 0 = not said
	$r{mem}       = $args->{mem}       // ''; # '' = not said
	$r{walltime}  = $args->{walltime}  // ''; # '' = not said
	# The hooks are the one kind of option not on the record: they are code,
	# which neither the printed record, the log nor the trace can hold.
	my %hook = ('on_success' => $args->{'on_success'}, 'on_failure' => $args->{'on_failure'});
	# the command that is actually run: "cmd" itself, or "cmd" inside the
	# executor, container, conda environment and wrapper asked for
	my $run_cmd = _wrapped_cmd(\%r, $args->{cmd});
	$r{'wrapped.cmd'} = (defined $run_cmd) ? join(' ', @$run_cmd) : ''; # '' = run as it is
	$run_cmd //= $args->{cmd};
	my $run_cmd_ref = ref $run_cmd;
	my $log_fh   = $args->{'log_fh'};
	my $trace_fh = $args->{'trace_fh'};

	# Checked after "dry_run" is resolved, not before, as it was until 0.19:
	# a dry run makes nothing, so the input of a pipeline's second step --
	# the first step's output -- is legitimately absent, and dying over it
	# meant no dry run could get past step 2. A dry run reports the missing
	# inputs instead, further down.
	my %input_file_size;
	my @missing_inputs = ((grep {not -f -r $_ } @input_files), (grep { not ((-d $_) && (-r $_)) } @input_dirs));
	if (scalar @missing_inputs > 0) {
		if (!$r{'dry_run'}) {
			say STDERR 'this list of arguments:';
			_dump_args($args);
			say STDERR 'Cannot run because these files are either missing or unreadable in: ' . getcwd();
			p @missing_inputs, output => 'STDERR';
			die 'the above files are missing or are not readable';
		}
	}
	%input_file_size = map { $_ => -s $_ } @input_files; # undef for an input a dry run is missing
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
	$r{attempts}    = 0; # how many times the command was run; 0 = not at all
	$r{'cpu.user'}   = 0;
	$r{'cpu.system'} = 0;
	$r{'start.time'} = 0; # epoch seconds when the last attempt started; 0 = none did
	$r{'failed.outputs'} = []; # where a failed step's outputs were moved; see _move_aside
	$r{'cmd.changed'} = 0; # 1 = stale_cmd found a different command on record for the outputs
	$r{'will.do'} = 'yes';
	$r{'will.do'} = 'no: dry run'  if $r{'dry_run'};
	if (scalar @input_files > 0) {
		$r{'input_files'}     = [@input_files];
		$r{'input_file.size'} = \%input_file_size;
	}

	my $msg = "\@ $c[1] line $c[2] The command is:\n" . colored(['blue on_bright_red'], $cmd_string);
	say $msg unless $r{quiet};
	say {$log_fh} "\@ $c[1] line $c[2] The command is:\n$cmd_string" if defined $log_fh;

	# Taken before the outputs are looked at, so that a run which waited for
	# another to finish the step sees what that one made. A dry run touches
	# nothing, and so takes no lock. Held until this call returns.
	my @locks = ($r{lock} && !$r{'dry_run'}) ? _lock_outputs($cmd_string, @outputs) : ();

	# The same test as the post-run check further down (-f -r, not a bare -f).
	# A file that exists but cannot be read is not a usable result, and
	# counting it as "already done" would skip the very step that could
	# replace it.
	my @existing = ((grep {-f -r $_} @output_files), (grep { -d $_ } @output_dirs));

	# Staleness, as make and snakemake understand it: outputs that already
	# exist are still out of date if any input is newer than any of them.
	# Off by default, because switching it on unconditionally would silently
	# start re-running steps in pipelines written against 0.15 and earlier.
	my $is_stale = 0;
	if (($r{stale}) && (scalar(@input_files) + scalar(@input_dirs) > 0) && (scalar @outputs > 0)) {
		my $newest_input  = _newest_mtime(@input_files, @input_dirs);
		my $oldest_output = _oldest_mtime(@outputs);
		if (
				(defined $newest_input)  &&
				(defined $oldest_output) &&
				($newest_input > $oldest_output)
			) {
			$is_stale = 1;
		}
	}
	$r{'out.of.date'} = $is_stale;

	# "stale_cmd": the outputs are out of date if the command on record for
	# them is not this one; see _command_signature. Outputs with no command on
	# record -- made before stale_cmd was used, or by hand -- are taken as
	# made by this one, which is recorded, so that the next change is seen.
	#
	# A step run without stale_cmd still replaces the outputs, so when there
	# is a command on record for them, this one's is written over it after a
	# successful run, further down. Until 0.192 it was left, and a later
	# stale_cmd run of the command on record took the other one's outputs as
	# its own. With nothing on record, nothing is written: a pipeline that
	# never asks for stale_cmd gets no .simpleflow/ from it.
	my ($signature, $signature_file, $recorded_signature);
	if (($r{'stale_cmd'}) && (scalar @outputs > 0)) {
		$signature = _command_signature(\%r, $args->{cmd}, $run_cmd);
		$signature_file = _signature_file(@outputs);
		$recorded_signature = _read_signature($signature_file);
		$r{'cmd.changed'} = ((defined $recorded_signature) && ($recorded_signature ne $signature)) ? 1 : 0;
	} elsif ((scalar @outputs > 0) && (-e _signature_file(@outputs))) {
		$signature = _command_signature(\%r, $args->{cmd}, $run_cmd);
		$signature_file = _signature_file(@outputs);
	}

	if (
			(!$r{overwrite})   &&
			(!$is_stale)       &&
			(!$r{'cmd.changed'}) &&
			(scalar @outputs > 0) &&
			(scalar @existing == scalar @outputs)
		) { # this has been done before
		$r{done} = 'before';
		$r{'will.do'} = 'no';
		say colored(['black on_green'], "\"$cmd_string\"\n") . ' has been done before' unless $r{quiet};
		$r{'output_file.size'} = { map {$_ => -s $_} @output_files };
		_write_signature($signature_file, $signature)
			if $r{'stale_cmd'} && (defined $signature) && (not defined $recorded_signature) && (!$r{'dry_run'});
		_report(\%r, $log_fh, $r{quiet}, $trace_fh);
		return \%r;
	} else {
		$r{done} = 'not yet';
	}
	if ($is_stale) {
		say colored(['red on_black'], "\"$cmd_string\"")
			. ' is being re-run: an input file is newer than an output file' unless $r{quiet};
	}
	if ($r{'cmd.changed'}) {
		say colored(['red on_black'], "\"$cmd_string\"")
			. ' is being re-run: its command has changed since its outputs were made' unless $r{quiet};
	}
	if ($r{'dry_run'}) {
		unless ($r{quiet}) {
			say "\@ $c[1] line $c[2] in $r{dir} the command was going to be:";
			say colored(['red on_black'], "\"$cmd_string\"");
			say "run as: $r{'wrapped.cmd'}" if $r{'wrapped.cmd'} ne '';
			say 'But this is a dry run';
		}
		if (scalar @missing_inputs > 0) {
			my $missing = "these inputs do not exist yet, which a dry run allows:\n"
				. join("\n", map { "\t$_" } @missing_inputs);
			say $missing unless $r{quiet};
			say {$log_fh} $missing if defined $log_fh;
		}
		# Until 0.19 a dry run returned with neither: its record lacked
		# output_file.size, and the log held only the command line.
		$r{'output_file.size'} = { map {$_ => -s $_} @output_files };
		_report(\%r, $log_fh, $r{quiet}, $trace_fh);
		say '-------------' unless $r{quiet};
		return \%r;
	}
	# A protected output is one a step made and finished with: re-running
	# over it is refused, as Snakemake refuses, rather than left to fail in
	# the command with an error that does not say why the file is read-only.
	if ($r{protect}) {
		my @protected = grep { (-e $_) && (not -w $_) } @outputs;
		if (scalar @protected > 0) {
			p @protected, output => 'STDERR';
			die "cannot re-run \"$cmd_string\": the above outputs are write-protected, as \"protect\" left them; "
				. 'remove them, or make them writable, to run it again';
		}
	}
	# "stdout_file" and "stderr_file" hold this call's output, from every
	# attempt: emptied once, here, and appended to by each attempt.
	foreach my $path (grep { $_ ne '' } $r{'stdout_file'}, $r{'stderr_file'}) {
		open my $fh, '>', $path or die "cannot empty \"$path\" before running \"$cmd_string\": $!";
		close $fh;
	}

	my ($interrupted, $launch_error, @missing_outputs, %output_file_size, @stderr_tail);
	my %moved; # every .failed name, over all the attempts
	my $attempts = $r{retries} + 1;
	foreach my $attempt (1 .. $attempts) {
		$r{attempts} = $attempt;
		($interrupted, $launch_error) = _run_once(\%r, $run_cmd, $run_cmd_ref, $cmd_string, \%command_env);
		# A command that timed out, exited non-zero, was killed by a signal, or
		# failed to produce its declared outputs has failed, whether or not
		# "die" is set. Until 0.16 the FAILED assignment for a non-zero exit
		# lived inside the "die" branch, so under die => 0 -- the very mode in
		# which the caller is expected to read will.do -- a failing command was
		# reported as "done". Until 0.19 the signal was not tested at all: a
		# death by signal leaves exit at 0, so an OOM kill or a Ctrl-C was
		# "done" too.
		@missing_outputs = ((grep {not -f -r $_} @output_files), (grep { not -d $_ } @output_dirs));
		$r{'will.do'} = (
				(scalar @missing_outputs > 0) ||
				($r{'exit'} != 0) ||
				($r{signal}) ||
				($r{'timed.out'})
			) ? 'FAILED' : 'done';
		# Measured before the move below, so the record says what the command
		# wrote rather than that the declared names are now empty.
		%output_file_size = map {$_ => -s $_} @output_files;
		$r{'output_file.size'} = { %output_file_size };
		# Not retried: success, the last attempt, or an interrupt, which is
		# the caller asking for the whole program to stop.
		my $retrying = (($attempt < $attempts) && (not defined $interrupted)) ? 1 : 0;
		if ($r{'will.do'} eq 'FAILED') {
			# Read now, while the file is where stderr_file says: when it is
			# also an output it is about to be moved, and until 0.192 the
			# message then went without it.
			@stderr_tail = _stderr_tail(\%r);
			# An output that is, or holds, stdout_file or stderr_file stays
			# where it is until the last attempt, since those files are to
			# hold every attempt, in order. Until 0.192 it was moved aside
			# with the rest, and the retry began a new file -- or, inside a
			# moved directory, could not open one.
			my @to_move = @outputs;
			if ($retrying) {
				my @streams = map { _canonical($_) } grep { $_ ne '' } $r{'stdout_file'}, $r{'stderr_file'};
				@to_move = grep {
					my $output = _canonical($_);
					not grep { ($_ eq $output) || _is_within($_, $output) } @streams;
				} @outputs;
			}
			my @moved_now = _move_aside(@to_move);
			$moved{$_} = 1 foreach @moved_now;
			$r{'failed.outputs'} = [sort keys %moved];
			if (scalar @moved_now > 0) {
				my $moved = "the outputs of the failed \"$cmd_string\" were moved aside, so that the next run does not take them as done:\n"
					. join("\n", map { "\t$_" } @moved_now);
				say STDERR $moved;
				say {$log_fh} $moved if defined $log_fh;
			}
		}
		last if ($r{'will.do'} ne 'FAILED') || (not $retrying);
		my $retry = "\"$cmd_string\" " . join('; ', _why_failed(\%r, $interrupted, $launch_error, @missing_outputs))
			. "; attempt $attempt of $attempts, retrying"
			. (($r{'retry_delay'} > 0) ? " in $r{'retry_delay'}s" : '');
		say STDERR $retry;
		say {$log_fh} $retry if defined $log_fh;
		Time::HiRes::sleep($r{'retry_delay'}) if $r{'retry_delay'} > 0;
	}
	$r{done} = 'now';
	if (scalar @missing_outputs > 0) {
		my $clipped_args = _clipped(_shown_args($args));
		say STDERR "this input to $current_sub:";
		p $clipped_args, output => 'STDERR';
		say {$log_fh} "this input to $current_sub:" if defined $log_fh;
		p($clipped_args, output => $log_fh, string_max => 0) if defined $log_fh;
		say STDERR 'has these output files missing:';
		say {$log_fh} 'has these output files missing:' if defined $log_fh;
		p @missing_outputs, output => 'STDERR';
		p(@missing_outputs, output => $log_fh) if defined $log_fh;
	}
	# Only outputs that exist: a missing one has an undef size, which until
	# 0.19 was defaulted to 0 here, so a file never made was reported twice.
	my @files_with_zero_size = grep {
		(defined $output_file_size{$_}) && ($output_file_size{$_} == 0)
	} @output_files;
	if (scalar @files_with_zero_size > 0) {
		p @files_with_zero_size, output => 'STDERR';
		warn 'the above output files have 0 size.';
	}
	my @empty_dirs = grep { (-d $_) && _is_empty_dir($_) } @output_dirs;
	if (scalar @empty_dirs > 0) {
		p @empty_dirs, output => 'STDERR';
		warn 'the above output directories are empty.';
	}
	_protect(@outputs) if $r{protect} && ($r{'will.do'} eq 'done');
	# with or without stale_cmd; see where $signature is set
	_write_signature($signature_file, $signature) if (defined $signature) && ($r{'will.do'} eq 'done');
	# The record is printed once, whatever happened. Until 0.19 each kind of
	# failure had its own branch with its own _report, and the missing-output
	# one fell through into the next under die => 0, logging the record twice.
	_report(\%r, $log_fh, $r{quiet}, $trace_fh);
	# An interrupt that arrived while a timed command ran has been held back
	# until now, so that the capture files are gone, STDIN is restored and the
	# record is in the log; see _run_forked. It goes to the caller's own
	# handler, or, with none, ends the program as it would have without
	# task() in the way.
	kill $interrupted, $$ if defined $interrupted;
	# After the record is written, and before task() dies: a hook sees the
	# step as the log does, and a pipeline's on_failure runs even under the
	# default die => 1. An exception from a hook propagates as it is.
	if ($r{'will.do'} ne 'FAILED') {
		$hook{'on_success'}->(\%r) if defined $hook{'on_success'};
		return \%r;
	}
	$hook{'on_failure'}->(\%r) if defined $hook{'on_failure'};
	my $failure = "\"$cmd_string\" " . join('; ', _why_failed(\%r, $interrupted, $launch_error, @missing_outputs))
		. (($r{attempts} > 1) ? " (after $r{attempts} attempts)" : '')
		. ", from $c[1] line $c[2]";
	$failure .= "; stderr ended with:\n" . join('', map { "\t$_\n" } @stderr_tail) if scalar @stderr_tail > 0;
	die $failure if $r{'die'}; # the resolved value (defaults to 1), not the raw arg
	# die => 0 asks task not to stop the pipeline, not to keep quiet: a warning
	# is the only signal a caller gets that did not look at will.do.
	warn $failure;
	return \%r;
}
# Run several tasks at the same time, at most "jobs" at once, and return
# their records in the order given. Each runs in a child of its own, forked
# from here, which runs task() in full -- its checks, its log and its record --
# and hands the record back through a file, with Storable, so that a record of
# any size never has to fit in a pipe. The first task to die stops any more
# from starting; those already running are let finish, and then parallel()
# dies with every failure. With "keep_going", every task runs regardless, and
# parallel() dies at the end if any did. POSIX-only for jobs > 1, like
# "timeout": perl's fork() on MSWin32 is an emulation with threads, and the
# children would share one working directory and one %ENV.
sub parallel {
	# Devel::Confess for this call only, as in task(): see _confess_here
	local $SIG{__DIE__}  = $SIG{__DIE__};
	local $SIG{__WARN__} = $SIG{__WARN__};
	local $Devel::Confess::OLD_SIG{__DIE__}  = $Devel::Confess::OLD_SIG{__DIE__};
	local $Devel::Confess::OLD_SIG{__WARN__} = $Devel::Confess::OLD_SIG{__WARN__};
	local $Devel::Confess::OPTIONS{color}    = $Devel::Confess::OPTIONS{color};
	_confess_here();
	my @c = caller;
	die 'parallel() takes a flat key/value list: parallel(jobs => 4, tasks => [...])' if scalar(@_) % 2 != 0;
	my %opt = @_;
	my @accepted = (
		'jobs',       # whole number, 1 or more: how many tasks may run at once
		'keep_going', # bool; run every task even after one has failed
		'tasks',      # array ref of hash refs, each the arguments of one task()
	);
	my @unknown = grep { my $key = $_; not grep { $_ eq $key } @accepted } sort keys %opt;
	die 'parallel() does not accept ' . join(', ', map { "\"$_\"" } @unknown)
		. '; it accepts ' . join(', ', map { "\"$_\"" } @accepted) if scalar @unknown > 0;
	if ((not defined $opt{jobs}) || ($opt{jobs} !~ /\A[1-9][0-9]*\z/)) {
		die '"jobs" must be a whole number, 1 or more: how many tasks parallel() may run at once';
	}
	if (ref $opt{tasks} ne 'ARRAY') {
		die '"tasks" must be an array ref of hash refs, each the arguments of one task()';
	}
	my @tasks = @{ $opt{tasks} };
	my @not_hashes = grep { ref $tasks[$_] ne 'HASH' } 0 .. $#tasks;
	if (scalar @not_hashes > 0) {
		die '"tasks" must hold only hash refs of task() arguments; it does not at index '
			. join(', ', @not_hashes);
	}
	if (($opt{jobs} > 1) && ($^O eq 'MSWin32')) {
		die '"jobs" above 1 is not supported on MSWin32: it needs a real fork(), and perl emulates one there with threads';
	}
	my $keep_going = $opt{'keep_going'} ? 1 : 0;
	# each task's source.file and source.line are the parallel() call's
	local $CALLER = [$c[1], $c[2]];
	my (@records, @failures); # @failures: [index, error]
	if ($opt{jobs} == 1) { # one at a time, here, with nothing to fork
		foreach my $i (0 .. $#tasks) {
			my $record = eval { task(%{ $tasks[$i] }) };
			if (defined $record) {
				$records[$i] = $record;
			} else {
				push @failures, [$i, $@];
				last if not $keep_going;
			}
		}
		return @records if scalar @failures == 0;
		die _parallel_failure(\@tasks, \@failures, \@c);
	}
	# Anything already written but still in a buffer is written now, before
	# the fork, or each child would inherit a copy and write it again.
	my %handles = map { ($_ => $_) } grep { defined openhandle($_) } \*STDOUT, \*STDERR,
		map { ($_->{'log_fh'}, $_->{'trace_fh'}) } @tasks, \%DEFAULTS;
	_flush($_) foreach values %handles;
	# An interrupt to parallel() goes to every running task, as TERM, which
	# each passes to its command before it ends; see _run_forked. It is then
	# re-raised here once every child is gone. One the caller ignores stays
	# ignored.
	my %running; # pid => [index, the File::Temp its record comes back in]
	my $report_lock = File::Temp->new; # see $REPORT_LOCK
	my $interrupted;
	my @interrupts = grep { not ((defined $SIG{$_}) && ($SIG{$_} eq 'IGNORE')) } qw(HUP INT QUIT TERM);
	my %caller_sig = map { $_ => $SIG{$_} } @interrupts;
	{
		local @SIG{@interrupts} = (sub {
			$interrupted //= shift;
			kill 'TERM', keys %running;
		}) x @interrupts;
		my $next = 0;
		while (1) {
			while ((not defined $interrupted) && ($next <= $#tasks) && (scalar keys %running < $opt{jobs})
					&& ($keep_going || (scalar @failures == 0))) {
				my $i = $next++;
				my $result = File::Temp->new;
				my $pid = fork();
				die "fork() failed, so parallel() cannot start task $i: $!" if not defined $pid;
				if ($pid == 0) { # the child: one task, its record to the file, and out
					# Everything up to the _exit is in the eval. Until 0.192
					# only task() was, and a failure to store the record or
					# flush a handle unwound into the caller's own evals as a
					# second copy of the caller's program. The parent then
					# reports that it got no record.
					eval {
						$SIG{$_} = $caller_sig{$_} // 'DEFAULT' foreach @interrupts;
						local $REPORT_LOCK = $report_lock->filename;
						my $record = eval { task(%{ $tasks[$i] }) };
						my $error = $@;
						Storable::nstore({ record => $record, error => (defined $record) ? '' : $error }, $result->filename);
						_flush($_) foreach values %handles;
						1;
					} or eval { print STDERR "parallel() could not return the record of task $i: $@" };
					# _exit, not exit: exit would run END blocks and the
					# destructors of the parent's objects, File::Temp's among them
					POSIX::_exit(0);
				}
				$running{$pid} = [$i, $result];
			}
			last if scalar keys %running == 0;
			# Each child is waited for by its own pid, never with waitpid(-1),
			# which would reap -- and so steal the status of -- any other child
			# the caller has. Polled every 20 ms: half the time perl took to
			# start here (29-44 ms), so a slot is refilled before its next task
			# could have started anyway.
			#
			# -1 is a child that is no longer ours to wait for: a caller whose
			# SIGCHLD is ignored has its children reaped by the kernel, and a
			# caller's own SIGCHLD handler may reap them first. Either way it
			# has ended, and its record, if it wrote one, is in its file.
			# Until 0.192 only its pid counted, and parallel() waited for ever.
			my @finished = grep {
				my $waited = waitpid($_, POSIX::WNOHANG());
				($waited == $_) || ($waited == -1);
			} keys %running;
			if (scalar @finished == 0) {
				Time::HiRes::sleep(0.02);
				next;
			}
			foreach my $pid (@finished) {
				my ($i, $result) = @{ delete $running{$pid} };
				my $got = eval { Storable::retrieve($result->filename) };
				if ((defined $got) && (defined $got->{record})) {
					$records[$i] = $got->{record};
				} elsif ((defined $got) && ($got->{error} ne '')) {
					push @failures, [$i, $got->{error}];
				} else {
					push @failures, [$i, 'the process running it ended before it could return a record'];
				}
			}
		}
	}
	kill $interrupted, $$ if defined $interrupted; # the caller's handler is back in place
	return @records if scalar @failures == 0;
	die _parallel_failure(\@tasks, \@failures, \@c);
}
sub _parallel_failure {
	my ($tasks, $failures, $c) = @_;
	my @sorted = sort { $a->[0] <=> $b->[0] } @$failures;
	return scalar(@sorted) . ' of ' . scalar(@$tasks) . " tasks failed in parallel() from $c->[1] line $c->[2]:\n"
		. join('', map {
			my ($i, $error) = @$_;
			my $cmd = $tasks->[$i]{cmd};
			$cmd = join(' ', @$cmd) if ref $cmd eq 'ARRAY';
			"task $i (" . ($cmd // 'no cmd') . "): $error" . (($error =~ /\n\z/) ? '' : "\n")
		} @sorted);
}

# An HTML page of a pipeline's trace: every task in the order it was
# traced, with its status, command, timing and exit, a timeline of when each
# ran, and a count of each status at the top. The trace is what "trace_fh"
# wrote, one JSON object a line; the page is a single file, with no scripts
# and nothing fetched, so that it can be mailed or archived as it is.
# Returns how many tasks it read.
sub report {
	# Devel::Confess for this call only, as in task(): see _confess_here
	local $SIG{__DIE__}  = $SIG{__DIE__};
	local $SIG{__WARN__} = $SIG{__WARN__};
	local $Devel::Confess::OLD_SIG{__DIE__}  = $Devel::Confess::OLD_SIG{__DIE__};
	local $Devel::Confess::OLD_SIG{__WARN__} = $Devel::Confess::OLD_SIG{__WARN__};
	local $Devel::Confess::OPTIONS{color}    = $Devel::Confess::OPTIONS{color};
	_confess_here();
	die 'report() takes a flat key/value list: report(trace => ..., html => ...)' if scalar(@_) % 2 != 0;
	my %opt = @_;
	my @accepted = (
		'html',  # the file to write the page to
		'title', # the page's title; by default, "SimpleFlow report"
		'trace', # the trace file to read, as "trace_fh" wrote it
	);
	my @unknown = grep { my $key = $_; not grep { $_ eq $key } @accepted } sort keys %opt;
	die 'report() does not accept ' . join(', ', map { "\"$_\"" } @unknown) if scalar @unknown > 0;
	foreach my $key ('trace', 'html') {
		die "report() needs \"$key\", a file name" if (not defined $opt{$key}) || (ref $opt{$key} ne '') || ($opt{$key} eq '');
	}
	my $title = $opt{title} // 'SimpleFlow report';
	# A title of UTF-8 bytes -- read from a file or the command line, say --
	# is taken as the characters it encodes, as _json_string takes a byte
	# string. Until 0.192 it was encoded again with the page, and the two bytes
	# of the e in "caf\xc3\xa9" came out as two characters. Bytes that are not
	# UTF-8 are Latin-1 characters, as perl itself treats them.
	if (not utf8::is_utf8($title)) {
		my $decoded = $title;
		$title = $decoded if utf8::decode($decoded);
	}
	open my $in, '<', $opt{trace} or die "cannot read the trace \"$opt{trace}\": $!";
	my @tasks;
	while (my $line = <$in>) {
		next if $line !~ /\S/;
		my $task = eval { _json_decode($line) };
		if ((not defined $task) || (ref $task ne 'HASH')) {
			my $why = $@ || 'it is not a JSON object';
			$why =~ s/ at \S+ line \d+.*//s;
			die "line $. of the trace \"$opt{trace}\" is not a task's record: $why";
		}
		my $bad = _bad_trace_field($task);
		die "line $. of the trace \"$opt{trace}\" is not a task's record: $bad" if defined $bad;
		push @tasks, $task;
	}
	close $in;
	my %label = ('done' => 'done', 'no' => 'skipped', 'no: dry run' => 'dry run', 'FAILED' => 'FAILED');
	my %class = ('done' => 'done', 'skipped' => 'skipped', 'dry run' => 'dry', 'FAILED' => 'failed');
	my %count;
	foreach my $task (@tasks) {
		$task->{_status} = $label{ $task->{'will.do'} // '' } // ($task->{'will.do'} // 'unknown');
		$count{ $task->{_status} }++;
	}
	my @summary = map { ($count{$_} // 0) . ' ' . (($_ eq 'dry run') ? 'dry runs' : lc $_) }
		grep { ($_ ne 'dry run') || $count{$_} } 'done', 'skipped', 'FAILED', 'dry run';
	my $summary = scalar(@tasks) . ' tasks: ' . join(', ', @summary);
	# the timeline spans the first start to the last end among tasks that ran
	my @ran = grep { ($_->{'start.time'} // 0) > 0 } @tasks;
	my $first = min(map { $_->{'start.time'} } @ran) // 0;
	my $last  = max(map { $_->{'start.time'} + ($_->{duration} // 0) } @ran) // 0;
	my $span  = ($last > $first) ? ($last - $first) : 1;
	my @rows;
	foreach my $i (0 .. $#tasks) {
		my $t = $tasks[$i];
		my $cmd = $t->{cmd} // '';
		my $started = (($t->{'start.time'} // 0) > 0)
			? POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime int $t->{'start.time'}) : '';
		my $bar = '';
		if (($t->{'start.time'} // 0) > 0) {
			my $left  = sprintf '%.2f', 100 * ($t->{'start.time'} - $first) / $span;
			# a bar of at least half a percent, so that a quick task is seen
			my $width = sprintf '%.2f', max(0.5, 100 * ($t->{duration} // 0) / $span);
			my $bar_class = $class{ $t->{_status} } // 'other';
			$bar = qq{<div class="bar $bar_class" style="margin-left:$left%;width:$width%"></div>};
		}
		my $cpu = sprintf '%.2f', ($t->{'cpu.user'} // 0) + ($t->{'cpu.system'} // 0);
		push @rows, '<tr class="' . ($class{ $t->{_status} } // 'other') . '">'
			. join('', map { "<td>$_</td>" }
				$i + 1,
				'<span class="status">' . _html($t->{_status}) . '</span>',
				'<code>' . _html($cmd) . '</code>'
					. ((($t->{note} // '') ne '') ? '<div class="note">' . _html($t->{note}) . '</div>' : ''),
				_html($started),
				sprintf('%.3f', $t->{duration} // 0),
				$cpu,
				_html($t->{'exit'} // ''),
				_html($t->{signal} // ''),
				_html($t->{attempts} // ''),
				_html(($t->{'source.file'} // '') . ':' . ($t->{'source.line'} // '')),
				qq{<div class="lane">$bar</div>})
			. '</tr>';
	}
	my $html = <<"HTML";
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@{[ _html($title) ]}</title>
<style>
:root { --bg: #ffffff; --fg: #1f2328; --muted: #656d76; --line: #d0d7de; --done: #1a7f37; --skipped: #8c959f; --failed: #cf222e; --dry: #9a6700; }
\@media (prefers-color-scheme: dark) { :root { --bg: #0d1117; --fg: #e6edf3; --muted: #8d96a0; --line: #30363d; --done: #3fb950; --skipped: #6e7681; --failed: #f85149; --dry: #d29922; } }
body { background: var(--bg); color: var(--fg); font: 14px/1.4 system-ui, sans-serif; margin: 16px; }
h1 { font-size: 20px; margin: 0 0 4px; }
p.summary { color: var(--muted); margin: 0 0 16px; }
.table { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; }
th, td { border-bottom: 1px solid var(--line); padding: 4px 8px; text-align: left; vertical-align: top; }
th { color: var(--muted); font-weight: 600; white-space: nowrap; }
td code { white-space: pre-wrap; word-break: break-all; }
.note { color: var(--muted); }
.status { font-weight: 600; }
tr.done .status { color: var(--done); } tr.skipped .status { color: var(--skipped); }
tr.failed .status { color: var(--failed); } tr.dry .status { color: var(--dry); }
.lane { position: relative; min-width: 160px; height: 10px; margin-top: 4px; }
.bar { height: 10px; border-radius: 2px; }
.bar.done { background: var(--done); } .bar.failed { background: var(--failed); }
</style>
</head>
<body>
<h1>@{[ _html($title) ]}</h1>
<p class="summary">@{[ _html($summary) ]}</p>
<div class="table">
<table>
<thead><tr><th>#</th><th>status</th><th>command</th><th>started</th><th>seconds</th><th>CPU s</th><th>exit</th><th>signal</th><th>attempts</th><th>source</th><th>timeline</th></tr></thead>
<tbody>
@{[ join("\n", @rows) ]}
</tbody>
</table>
</div>
</body>
</html>
HTML
	my $bytes = $html;
	utf8::encode($bytes); # the page says it is UTF-8, and the trace's strings are characters
	open my $out, '>', $opt{html} or die "cannot write the report \"$opt{html}\": $!";
	binmode $out;
	print {$out} $bytes;
	close $out or die "cannot write the report \"$opt{html}\": $!";
	return scalar @tasks;
}
# Why a decoded trace line cannot be shown, or undef if it can. The page does
# arithmetic with the times and puts the rest in its cells, and until 0.192 a
# line with a string for a time died "isn't numeric", deep inside report(),
# and one with a list for a command showed "ARRAY(0x...)". A start time is
# epoch seconds below 1e15, the year 31690708: past 1e16 perl's localtime
# dies on 5.44.0 ("too large", at 1e17) and returns nothing on 5.10.1.
my @TRACE_TIMES = ('start.time', 'duration', 'cpu.user', 'cpu.system');
my @TRACE_TEXTS = ('cmd', 'note', 'will.do', 'exit', 'signal', 'attempts', 'source.file', 'source.line');
sub _bad_trace_field {
	my $task = shift;
	foreach my $field (@TRACE_TIMES) {
		my $value = $task->{$field};
		next if not defined $value;
		return "its \"$field\" is not a number of seconds, 0 or more"
			if (ref $value ne '') || ($value !~ $JSON_NUMBER) || ($value < 0); # "Inf" fails the pattern
	}
	return "its \"start.time\" is not a time since the epoch, in seconds"
		if (defined $task->{'start.time'}) && ($task->{'start.time'} >= 1e15);
	foreach my $field (@TRACE_TEXTS) {
		return "its \"$field\" is not a single value" if ref $task->{$field} ne '';
	}
	return undef;
}

sub _html {
	my $text = shift;
	$text = '' if not defined $text;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	$text =~ s/'/&#39;/g;
	return $text;
}

# Read one JSON value, as report() needs to read a trace. JSON::PP, which could
# do it, is core only from perl 5.14. The text is UTF-8 bytes, as _json writes
# them; true and false are read as 1 and 0, null as undef.
#
# Until 0.192 it took more than JSON: bytes that were not UTF-8, raw control
# characters in a string, an unpaired UTF-16 surrogate, and whitespace beyond
# JSON's four; and it nested without limit, so a line of "[[[[..." recursed as
# deep as it was long. Each is now refused, nesting past $JSON_MAX_DEPTH -- 512,
# JSON::PP's own default max_depth (JSON::PP 4.16, "max_depth") -- among them.
# A trace line is at most 3 deep: the record, a hash or array in it, and the
# values of that. There is no limit on a line's length, as JSON::PP has none by
# default: a trace holds each task's whole "note".
my $JSON_MAX_DEPTH = 512;
sub _json_decode {
	my $text = shift;
	utf8::decode($text) or die "it is not UTF-8\n"; # bytes of UTF-8 in, characters out
	my $value = _json_value(\$text, 0);
	$text =~ /\G[ \t\n\r]*/gc;
	die 'unexpected text after the JSON value, at character ' . (pos($text) // 0) . "\n"
		if (pos($text) // 0) != length $text;
	return $value;
}
my %JSON_ESCAPE = ('"' => '"', '\\' => '\\', '/' => '/', b => "\b", f => "\f", n => "\n", r => "\r", t => "\t");
sub _json_value {
	my ($t, $depth) = @_;
	# "Deep recursion" warns at 100 levels, and is fatal here; $JSON_MAX_DEPTH
	# is the limit, as JSON::PP turns the warning off for its own
	no warnings 'recursion';
	$$t =~ /\G[ \t\n\r]*/gc;
	if ($$t =~ /\G([\{\[])/gc) {
		die "the JSON nests deeper than $JSON_MAX_DEPTH, at character " . (pos($$t) // 0) . "\n"
			if $depth >= $JSON_MAX_DEPTH;
		if ($1 eq '{') {
			my %hash;
			$$t =~ /\G[ \t\n\r]*/gc;
			return \%hash if $$t =~ /\G\}/gc;
			while (1) {
				$$t =~ /\G[ \t\n\r]*"/gc or die 'expected a string for a key, at character ' . (pos($$t) // 0) . "\n";
				my $key = _json_string_body($t);
				$$t =~ /\G[ \t\n\r]*:/gc or die 'expected ":" after a key, at character ' . (pos($$t) // 0) . "\n";
				$hash{$key} = _json_value($t, $depth + 1);
				$$t =~ /\G[ \t\n\r]*/gc;
				next if $$t =~ /\G,/gc;
				return \%hash if $$t =~ /\G\}/gc;
				die 'expected "," or "}" in an object, at character ' . (pos($$t) // 0) . "\n";
			}
		}
		my @array;
		$$t =~ /\G[ \t\n\r]*/gc;
		return \@array if $$t =~ /\G\]/gc;
		while (1) {
			push @array, _json_value($t, $depth + 1);
			$$t =~ /\G[ \t\n\r]*/gc;
			next if $$t =~ /\G,/gc;
			return \@array if $$t =~ /\G\]/gc;
			die 'expected "," or "]" in an array, at character ' . (pos($$t) // 0) . "\n";
		}
	}
	return _json_string_body($t) if $$t =~ /\G"/gc;
	return $1 + 0 if $$t =~ /\G(-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?)/gc;
	return 1     if $$t =~ /\Gtrue/gc;
	return 0     if $$t =~ /\Gfalse/gc;
	return undef if $$t =~ /\Gnull/gc;
	die 'expected a JSON value, at character ' . (pos($$t) // 0) . "\n";
}
# The rest of a string, its opening quote already read.
sub _json_string_body {
	my $t = shift;
	my $string = '';
	while (1) {
		if ($$t =~ /\G([^"\\\x00-\x1f]+)/gc) {
			$string .= $1;
		} elsif ($$t =~ /\G"/gc) {
			return $string;
		} elsif ($$t =~ /\G\\(["\\\/bfnrt])/gc) {
			$string .= $JSON_ESCAPE{$1};
		} elsif ($$t =~ /\G\\u([0-9a-fA-F]{4})/gc) {
			my $code = hex $1;
			# a character beyond U+FFFF is written as a UTF-16 surrogate pair,
			# and half of one is not a character
			if (($code >= 0xD800) && ($code <= 0xDBFF)) {
				$$t =~ /\G\\u([dD][c-fC-F][0-9a-fA-F]{2})/gc
					or die 'an unpaired UTF-16 surrogate, at character ' . (pos($$t) // 0) . "\n";
				$code = 0x10000 + (($code - 0xD800) << 10) + (hex($1) - 0xDC00);
			} elsif (($code >= 0xDC00) && ($code <= 0xDFFF)) {
				die 'an unpaired UTF-16 surrogate, at character ' . (pos($$t) // 0) . "\n";
			}
			$string .= chr $code;
		} elsif ($$t =~ /\G(?=[\x00-\x1f])/gc) {
			die 'a raw control character in a string, at character ' . (pos($$t) // 0) . "\n";
		} else {
			die 'a string is not closed, or has a bad escape, at character ' . (pos($$t) // 0) . "\n";
		}
	}
}

# the end of this file's code: see $CALLER_PERLDB_FLAGS at the top
BEGIN { $^P = $CALLER_PERLDB_FLAGS }
1;

=encoding utf8

=head1 NAME

SimpleFlow - easy, simple workflow manager (and logger); for keeping track of and debugging large and complex shell command workflows

=head1 VERSION

version 0.193

=head1 DESCRIPTION

A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to B<debug> and B<reproduce>.

Every step is a single C<task()> call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its C<stdout>,
C<stderr>, exit code and signal, optionally logs a full structured record, and
skips work that has already been done. It can also bound a step with a
L<timeout|/"Timeouts">, L<retry|/"Retries"> it, rebuild
L<out-of-date outputs|/"Out-of-date outputs">, run it in its own
L<directory and environment|/"Environment and directory">, make its outputs
L<read-only|/"Protected outputs">, keep a L<trace|/"Tracing"> of the whole run,
L<lock|/"Locking"> a step against a second copy of the pipeline, run it in a
L<container, a conda environment or on a SLURM cluster|/"Containers, conda and clusters">,
and L<run independent steps at once|/"Running steps in parallel">. A trace
becomes an L<HTML report|/"Reports">.

Two subroutines are exported by default: L</"task"> and L</"say2">.
Two more are exported on request:
L<parallel|/"Running steps in parallel"> and L<report|/"Reports">.

 use SimpleFlow qw(task say2 parallel report);

=head1 Install

With a CPAN client:

 cpanm SimpleFlow

Or from a release tarball, unpacked:

 perl Makefile.PL
 make
 make test
 make install

A git checkout has no C<Makefile.PL>: it is written by
L<Dist::Zilla>, so run C<dzil build> there
first and install from the tarball it makes, or run the tests in place with
C<prove -Ilib t/>.

=head1 Synopsis

The simplest useful case: run a command and confirm it produced its output:

 use SimpleFlow qw(task say2);

 my $t = task(
     cmd           => 'echo hello > hello.txt',
     'output_file' => 'hello.txt',
 );

C<task> returns a hash reference describing exactly what happened, and prints
it (here from a script called C<example.pl>, run in C</home/you/project>):

 {
     attempts           1,
     cmd                "echo hello > hello.txt",
     cmd.changed        0,
     conda_env          "",
     container          "",
     container_args     [],
     container_engine   "",
     cpu.system         0,
     cpu.user           0,
     die                1,
     dir                "/home/you/project",
     done               "now",
     dry_run            0,
     duration           0.00192999839782715,
     env                {},
     env_secret         [],
     executor           "local",
     executor_args      [],
     exit               0,
     failed.outputs     [],
     input_dirs         [],
     lock               0,
     mem                "",
     note               "",
     out.of.date        0,
     output_dirs        [],
     output_file.size   {
         hello.txt   6
     },
     output_files       [
         [0] "hello.txt"
     ],
     overwrite          0,
     protect            0,
     quiet              0,
     retries            0,
     retry_delay        0,
     signal             0,
     source.file        "example.pl",
     source.line        3,
     stale              0,
     stale_cmd          0,
     start.time         1790446630.13174,
     stderr             "",
     stderr_file        "",
     stdin              "devnull",
     stdout             "",
     stdout_file        "",
     threads            0,
     timed.out          0,
     timeout            0,
     walltime           "",
     will.do            "done",
     wrapped.cmd        "",
     wrapper            []
 }

Run it a second time and C<hello.txt> is already there, so the step is skipped:
C<done> is C<"before"> and C<will.do> is C<"no">.

 > B<Portability note.> SimpleFlow runs whatever shell command you give it via
 > C<system()>, so the I<commands themselves> are your responsibility to keep
 > cross-platform (e.g. C<which ls> is Unix-only). SimpleFlow's own behaviour —
 > exit/signal decoding and coloured output — is cross-platform; see the
 > C<Changes> file for what was done to make it so.

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
  <td><code>conda_env</code></td>
  <td>name or path</td>
  <td><code>undef</code></td>
  <td>Run the command in this conda environment. See Containers, conda and clusters.</td>
</tr>
<tr>
  <td><code>container</code></td>
  <td>image</td>
  <td><code>undef</code></td>
  <td>Run the command in a container made from this image.</td>
</tr>
<tr>
  <td><code>container_args</code></td>
  <td>array ref</td>
  <td><code>[]</code></td>
  <td>More arguments for the container engine, before the image.</td>
</tr>
<tr>
  <td><code>container_engine</code></td>
  <td>name</td>
  <td><code>'docker'</code></td>
  <td><code>'docker'</code>, <code>'podman'</code>, <code>'singularity'</code> or <code>'apptainer'</code>.</td>
</tr>
<tr>
  <td><code>die</code></td>
  <td>bool (<code>0</code>/<code>1</code>)</td>
  <td><code>1</code></td>
  <td>Die if the command fails (non-zero exit, a kill by signal, a timeout, or a missing output file). Set to <code>0</code> to warn and continue instead.</td>
</tr>
<tr>
  <td><code>dir</code></td>
  <td>directory</td>
  <td><code>undef</code></td>
  <td>Run the step in this directory; every file it declares is relative to it. See Environment and directory.</td>
</tr>
<tr>
  <td><code>dry_run</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Print the command (and log it) but do not execute it.</td>
</tr>
<tr>
  <td><code>env</code></td>
  <td>hash ref</td>
  <td><code>{}</code></td>
  <td>Environment variables for the command only; a value of <code>undef</code> removes one. See Environment and directory.</td>
</tr>
<tr>
  <td><code>env_secret</code></td>
  <td>array ref</td>
  <td><code>[]</code></td>
  <td>Names in <code>env</code> whose values are never printed, logged or traced. See Secrets.</td>
</tr>
<tr>
  <td><code>executor</code></td>
  <td><code>'local'</code>/<code>'slurm'</code></td>
  <td><code>'local'</code></td>
  <td>Where the command runs: here, or as a SLURM job step through <code>srun</code>.</td>
</tr>
<tr>
  <td><code>executor_args</code></td>
  <td>array ref</td>
  <td><code>[]</code></td>
  <td>More arguments for the executor (<code>srun</code>).</td>
</tr>
<tr>
  <td><code>input_dirs</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>Directories that must exist before running, as <code>input_files</code> must.</td>
</tr>
<tr>
  <td><code>input_dir</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>input_dirs</code> for a <b>single</b> directory.</td>
</tr>
<tr>
  <td><code>input_files</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>File(s) that must exist and be readable <b>before</b> running; otherwise <code>task</code> dies (except in a dry run, which lists them instead).</td>
</tr>
<tr>
  <td><code>input_file</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>input_files</code> for a <b>single</b> file. Must be a plain filename (not a reference). Cannot be combined with <code>input_files</code>.</td>
</tr>
<tr>
  <td><code>on_failure</code></td>
  <td>code ref</td>
  <td><code>undef</code></td>
  <td>Called with the record when the command ran and failed, before <code>task</code> dies. See Hooks.</td>
</tr>
<tr>
  <td><code>on_success</code></td>
  <td>code ref</td>
  <td><code>undef</code></td>
  <td>Called with the record when the command ran and succeeded.</td>
</tr>
<tr>
  <td><code>output_dirs</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>Directories the step makes, checked like <code>output_files</code>. See Directory outputs.</td>
</tr>
<tr>
  <td><code>output_dir</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>output_dirs</code> for a <b>single</b> directory. Cannot be combined with <code>output_dirs</code>.</td>
</tr>
<tr>
  <td><code>output_files</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>File(s) expected to exist <b>after</b> running; used both for the missing-output check and for skip detection.</td>
</tr>
<tr>
  <td><code>output_file</code></td>
  <td>scalar</td>
  <td><code>undef</code></td>
  <td>Convenience form of <code>output_files</code> for a <b>single</b> file. Must be a plain filename (not a reference). Cannot be combined with <code>output_files</code>.</td>
</tr>
<tr>
  <td><code>lock</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Hold a lock on the outputs while the step runs, so that a second copy of the pipeline waits for this one. See Locking.</td>
</tr>
<tr>
  <td><code>log_fh</code></td>
  <td>open filehandle</td>
  <td><code>undef</code></td>
  <td>If given, the full result record is also written here. Must be a real, open filehandle; <code>task</code> switches it to autoflush.</td>
</tr>
<tr>
  <td><code>mem</code></td>
  <td>e.g. <code>'16G'</code></td>
  <td><code>undef</code></td>
  <td>Memory to ask the executor for.</td>
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
  <td>If false and all <code>output_files</code> already exist, the command is skipped. Set true to always run.</td>
</tr>
<tr>
  <td><code>protect</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Make the outputs read-only once the step succeeds. See Protected outputs.</td>
</tr>
<tr>
  <td><code>quiet</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Suppress the record printed to the terminal. The log and error messages on <code>STDERR</code> are unaffected. See Quiet runs.</td>
</tr>
<tr>
  <td><code>retries</code></td>
  <td>whole number</td>
  <td><code>0</code></td>
  <td>Run a failed step again, up to this many more times. See Retries.</td>
</tr>
<tr>
  <td><code>retry_delay</code></td>
  <td>seconds</td>
  <td><code>0</code></td>
  <td>How long to wait before each retry; may be fractional.</td>
</tr>
<tr>
  <td><code>stale</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Also re-run when an input file is newer than an output file. See Out-of-date outputs.</td>
</tr>
<tr>
  <td><code>stale_cmd</code></td>
  <td>bool</td>
  <td><code>0</code></td>
  <td>Also re-run when the command differs from the one that made the outputs. See Re-running a changed command.</td>
</tr>
<tr>
  <td><code>stderr_file</code></td>
  <td>path</td>
  <td><code>undef</code></td>
  <td>Write the command's standard error to this file instead of the record. See Output to files.</td>
</tr>
<tr>
  <td><code>stdin</code></td>
  <td><code>'devnull'</code>/<code>'inherit'</code></td>
  <td><code>'devnull'</code></td>
  <td>What the command sees on its standard input. The default is the null device; <code>'inherit'</code> hands it the caller's own. See Standard input.</td>
</tr>
<tr>
  <td><code>stdout_file</code></td>
  <td>path</td>
  <td><code>undef</code></td>
  <td>Write the command's standard output to this file instead of the record.</td>
</tr>
<tr>
  <td><code>threads</code></td>
  <td>whole number</td>
  <td><code>undef</code></td>
  <td>CPUs the command uses: given to it as <code>SIMPLEFLOW_THREADS</code>, and asked of the executor.</td>
</tr>
<tr>
  <td><code>timeout</code></td>
  <td>whole seconds</td>
  <td><code>0</code></td>
  <td>Kill the command if it runs longer than this. <code>0</code> means no limit. See Timeouts.</td>
</tr>
<tr>
  <td><code>trace_fh</code></td>
  <td>open filehandle</td>
  <td><code>undef</code></td>
  <td>Append one line of JSON per task to this filehandle. See Tracing.</td>
</tr>
<tr>
  <td><code>walltime</code></td>
  <td>e.g. <code>'2:00:00'</code></td>
  <td><code>undef</code></td>
  <td>Time to ask the executor for, as SLURM writes it.</td>
</tr>
<tr>
  <td><code>wrapper</code></td>
  <td>array ref</td>
  <td><code>undef</code></td>
  <td>A command to run the command inside, e.g. <code>['nice', '-n', '10']</code>.</td>
</tr>
</tbody>
</table>

=end html

=begin :text

=over

=item C<cmd>

Type: scalar or array; Default: C<undef>.

B<Required.> The command to run. A string is handed to the shell; an array ref is run L<without a shell|/"Running without a shell">.

=item C<conda_env>

Type: name or path; Default: C<undef>.

Run the command in this conda environment. See L</"Containers, conda and clusters">.

=item C<container>

Type: image; Default: C<undef>.

Run the command in a container made from this image.

=item C<container_args>

Type: array ref; Default: C<[]>.

More arguments for the container engine, before the image.

=item C<container_engine>

Type: name; Default: C<'docker'>.

C<'docker'>, C<'podman'>, C<'singularity'> or C<'apptainer'>.

=item C<die>

Type: bool (C<0>/C<1>); Default: C<1>.

Die if the command fails (non-zero exit, a kill by signal, a timeout, or a missing output file). Set to C<0> to warn and continue instead.

=item C<dir>

Type: directory; Default: C<undef>.

Run the step in this directory; every file it declares is relative to it. See L</"Environment and directory">.

=item C<dry_run>

Type: bool; Default: C<0>.

Print the command (and log it) but do not execute it.

=item C<env>

Type: hash ref; Default: C<{}>.

Environment variables for the command only; a value of C<undef> removes one. See L</"Environment and directory">.

=item C<env_secret>

Type: array ref; Default: C<[]>.

Names in C<env> whose values are never printed, logged or traced. See L</"Secrets">.

=item C<executor>

Type: C<'local'>/C<'slurm'>; Default: C<'local'>.

Where the command runs: here, or as a SLURM job step through C<srun>.

=item C<executor_args>

Type: array ref; Default: C<[]>.

More arguments for the executor (C<srun>).

=item C<input_dirs>

Type: scalar or array; Default: C<undef>.

Directories that must exist before running, as C<input_files> must.

=item C<input_dir>

Type: scalar; Default: C<undef>.

Convenience form of C<input_dirs> for a B<single> directory.

=item C<input_files>

Type: scalar or array; Default: C<undef>.

File(s) that must exist and be readable B<before> running; otherwise C<task> dies (except in a L<dry run|/"Dry runs">, which lists them instead).

=item C<input_file>

Type: scalar; Default: C<undef>.

Convenience form of C<input_files> for a B<single> file. Must be a plain filename (not a reference). Cannot be combined with C<input_files>.

=item C<on_failure>

Type: code ref; Default: C<undef>.

Called with the record when the command ran and failed, before C<task> dies. See L</"Hooks">.

=item C<on_success>

Type: code ref; Default: C<undef>.

Called with the record when the command ran and succeeded.

=item C<output_dirs>

Type: scalar or array; Default: C<undef>.

Directories the step makes, checked like C<output_files>. See L</"Directory outputs">.

=item C<output_dir>

Type: scalar; Default: C<undef>.

Convenience form of C<output_dirs> for a B<single> directory. Cannot be combined with C<output_dirs>.

=item C<output_files>

Type: scalar or array; Default: C<undef>.

File(s) expected to exist B<after> running; used both for the missing-output check and for L<skip detection|/"Skipping completed work">.

=item C<output_file>

Type: scalar; Default: C<undef>.

Convenience form of C<output_files> for a B<single> file. Must be a plain filename (not a reference). Cannot be combined with C<output_files>.

=item C<lock>

Type: bool; Default: C<0>.

Hold a lock on the outputs while the step runs, so that a second copy of the pipeline waits for this one. See L</"Locking">.

=item C<log_fh>

Type: open filehandle; Default: C<undef>.

If given, the full result record is also written here. Must be a real, open filehandle; C<task> switches it to autoflush.

=item C<mem>

Type: e.g. C<'16G'>; Default: C<undef>.

Memory to ask the executor for.

=item C<note>

Type: scalar; Default: C<''>.

Free-text note copied into the result and the log.

=item C<overwrite>

Type: bool; Default: C<0>.

If false and all C<output_files> already exist, the command is skipped. Set true to always run.

=item C<protect>

Type: bool; Default: C<0>.

Make the outputs read-only once the step succeeds. See L</"Protected outputs">.

=item C<quiet>

Type: bool; Default: C<0>.

Suppress the record printed to the terminal. The log and error messages on C<STDERR> are unaffected. See L</"Quiet runs">.

=item C<retries>

Type: whole number; Default: C<0>.

Run a failed step again, up to this many more times. See L</"Retries">.

=item C<retry_delay>

Type: seconds; Default: C<0>.

How long to wait before each retry; may be fractional.

=item C<stale>

Type: bool; Default: C<0>.

Also re-run when an input file is newer than an output file. See L</"Out-of-date outputs">.

=item C<stale_cmd>

Type: bool; Default: C<0>.

Also re-run when the command differs from the one that made the outputs. See L</"Re-running a changed command">.

=item C<stderr_file>

Type: path; Default: C<undef>.

Write the command's standard error to this file instead of the record. See L</"Output to files">.

=item C<stdin>

Type: C<'devnull'>/C<'inherit'>; Default: C<'devnull'>.

What the command sees on its standard input. The default is the null device; C<'inherit'> hands it the caller's own. See L</"Standard input">.

=item C<stdout_file>

Type: path; Default: C<undef>.

Write the command's standard output to this file instead of the record.

=item C<threads>

Type: whole number; Default: C<undef>.

CPUs the command uses: given to it as C<SIMPLEFLOW_THREADS>, and asked of the executor.

=item C<timeout>

Type: whole seconds; Default: C<0>.

Kill the command if it runs longer than this. C<0> means no limit. See L</"Timeouts">.

=item C<trace_fh>

Type: open filehandle; Default: C<undef>.

Append one line of JSON per task to this filehandle. See L</"Tracing">.

=item C<walltime>

Type: e.g. C<'2:00:00'>; Default: C<undef>.

Time to ask the executor for, as SLURM writes it.

=item C<wrapper>

Type: array ref; Default: C<undef>.

A command to run the command inside, e.g. C<['nice', '-n', '10']>.

=back

=end :text

=begin :man

=over

=item C<cmd>

Type: scalar or array; Default: C<undef>.

B<Required.> The command to run. A string is handed to the shell; an array ref is run L<without a shell|/"Running without a shell">.

=item C<conda_env>

Type: name or path; Default: C<undef>.

Run the command in this conda environment. See L</"Containers, conda and clusters">.

=item C<container>

Type: image; Default: C<undef>.

Run the command in a container made from this image.

=item C<container_args>

Type: array ref; Default: C<[]>.

More arguments for the container engine, before the image.

=item C<container_engine>

Type: name; Default: C<'docker'>.

C<'docker'>, C<'podman'>, C<'singularity'> or C<'apptainer'>.

=item C<die>

Type: bool (C<0>/C<1>); Default: C<1>.

Die if the command fails (non-zero exit, a kill by signal, a timeout, or a missing output file). Set to C<0> to warn and continue instead.

=item C<dir>

Type: directory; Default: C<undef>.

Run the step in this directory; every file it declares is relative to it. See L</"Environment and directory">.

=item C<dry_run>

Type: bool; Default: C<0>.

Print the command (and log it) but do not execute it.

=item C<env>

Type: hash ref; Default: C<{}>.

Environment variables for the command only; a value of C<undef> removes one. See L</"Environment and directory">.

=item C<env_secret>

Type: array ref; Default: C<[]>.

Names in C<env> whose values are never printed, logged or traced. See L</"Secrets">.

=item C<executor>

Type: C<'local'>/C<'slurm'>; Default: C<'local'>.

Where the command runs: here, or as a SLURM job step through C<srun>.

=item C<executor_args>

Type: array ref; Default: C<[]>.

More arguments for the executor (C<srun>).

=item C<input_dirs>

Type: scalar or array; Default: C<undef>.

Directories that must exist before running, as C<input_files> must.

=item C<input_dir>

Type: scalar; Default: C<undef>.

Convenience form of C<input_dirs> for a B<single> directory.

=item C<input_files>

Type: scalar or array; Default: C<undef>.

File(s) that must exist and be readable B<before> running; otherwise C<task> dies (except in a L<dry run|/"Dry runs">, which lists them instead).

=item C<input_file>

Type: scalar; Default: C<undef>.

Convenience form of C<input_files> for a B<single> file. Must be a plain filename (not a reference). Cannot be combined with C<input_files>.

=item C<on_failure>

Type: code ref; Default: C<undef>.

Called with the record when the command ran and failed, before C<task> dies. See L</"Hooks">.

=item C<on_success>

Type: code ref; Default: C<undef>.

Called with the record when the command ran and succeeded.

=item C<output_dirs>

Type: scalar or array; Default: C<undef>.

Directories the step makes, checked like C<output_files>. See L</"Directory outputs">.

=item C<output_dir>

Type: scalar; Default: C<undef>.

Convenience form of C<output_dirs> for a B<single> directory. Cannot be combined with C<output_dirs>.

=item C<output_files>

Type: scalar or array; Default: C<undef>.

File(s) expected to exist B<after> running; used both for the missing-output check and for L<skip detection|/"Skipping completed work">.

=item C<output_file>

Type: scalar; Default: C<undef>.

Convenience form of C<output_files> for a B<single> file. Must be a plain filename (not a reference). Cannot be combined with C<output_files>.

=item C<lock>

Type: bool; Default: C<0>.

Hold a lock on the outputs while the step runs, so that a second copy of the pipeline waits for this one. See L</"Locking">.

=item C<log_fh>

Type: open filehandle; Default: C<undef>.

If given, the full result record is also written here. Must be a real, open filehandle; C<task> switches it to autoflush.

=item C<mem>

Type: e.g. C<'16G'>; Default: C<undef>.

Memory to ask the executor for.

=item C<note>

Type: scalar; Default: C<''>.

Free-text note copied into the result and the log.

=item C<overwrite>

Type: bool; Default: C<0>.

If false and all C<output_files> already exist, the command is skipped. Set true to always run.

=item C<protect>

Type: bool; Default: C<0>.

Make the outputs read-only once the step succeeds. See L</"Protected outputs">.

=item C<quiet>

Type: bool; Default: C<0>.

Suppress the record printed to the terminal. The log and error messages on C<STDERR> are unaffected. See L</"Quiet runs">.

=item C<retries>

Type: whole number; Default: C<0>.

Run a failed step again, up to this many more times. See L</"Retries">.

=item C<retry_delay>

Type: seconds; Default: C<0>.

How long to wait before each retry; may be fractional.

=item C<stale>

Type: bool; Default: C<0>.

Also re-run when an input file is newer than an output file. See L</"Out-of-date outputs">.

=item C<stale_cmd>

Type: bool; Default: C<0>.

Also re-run when the command differs from the one that made the outputs. See L</"Re-running a changed command">.

=item C<stderr_file>

Type: path; Default: C<undef>.

Write the command's standard error to this file instead of the record. See L</"Output to files">.

=item C<stdin>

Type: C<'devnull'>/C<'inherit'>; Default: C<'devnull'>.

What the command sees on its standard input. The default is the null device; C<'inherit'> hands it the caller's own. See L</"Standard input">.

=item C<stdout_file>

Type: path; Default: C<undef>.

Write the command's standard output to this file instead of the record.

=item C<threads>

Type: whole number; Default: C<undef>.

CPUs the command uses: given to it as C<SIMPLEFLOW_THREADS>, and asked of the executor.

=item C<timeout>

Type: whole seconds; Default: C<0>.

Kill the command if it runs longer than this. C<0> means no limit. See L</"Timeouts">.

=item C<trace_fh>

Type: open filehandle; Default: C<undef>.

Append one line of JSON per task to this filehandle. See L</"Tracing">.

=item C<walltime>

Type: e.g. C<'2:00:00'>; Default: C<undef>.

Time to ask the executor for, as SLURM writes it.

=item C<wrapper>

Type: array ref; Default: C<undef>.

A command to run the command inside, e.g. C<['nice', '-n', '10']>.

=back

=end :man



Any key but those naming a particular step can also be given once for the whole
program; see L</"Defaults for a whole pipeline">.

Passing an unrecognised key, an undefined or empty filename, a C<cmd> that is
neither a string nor an array ref, or a non-filehandle C<log_fh> causes C<task>
to die: these are usually mistakes worth catching early. Giving both
C<output_file> and C<output_files> (or both C<input_file> and C<input_files>), or a
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
  <td>Working directory at execution time: the absolute path of <code>dir</code>, if it was given.</td>
</tr>
<tr>
  <td><code>done</code></td>
  <td><code>"now"</code> (just ran), <code>"before"</code> (skipped, outputs already existed), or <code>"not yet"</code> (dry run).</td>
</tr>
<tr>
  <td><code>will.do</code></td>
  <td><code>"done"</code>, <code>"no"</code> (skipped), <code>"no: dry run"</code>, or <code>"FAILED"</code>. <code>"FAILED"</code> is set whenever the command exited non-zero, was killed by a signal, timed out, or left a declared output file missing — <b>whether or not <code>die</code> is set</b>.</td>
</tr>
<tr>
  <td><code>duration</code></td>
  <td>Wall-clock seconds the command took (<code>0</code> for skips/dry runs). With retries, the last attempt's.</td>
</tr>
<tr>
  <td><code>attempts</code></td>
  <td>How many times the command was run: <code>0</code> for a skip or a dry run, <code>1</code> without retries.</td>
</tr>
<tr>
  <td><code>start.time</code></td>
  <td>When the last attempt started, in epoch seconds with a fractional part; <code>0</code> if none did.</td>
</tr>
<tr>
  <td><code>cpu.user</code>, <code>cpu.system</code></td>
  <td>CPU seconds the command, and everything it waited for, spent in user and system mode. The clock counts in ticks of 1/100 s on Linux. Not known to be filled in on Windows.</td>
</tr>
<tr>
  <td><code>exit</code></td>
  <td>Exit code of the command, or <code>-1</code> if it could not be launched at all (<code>stderr</code> then says why).</td>
</tr>
<tr>
  <td><code>signal</code></td>
  <td>Signal number if the command process was killed by a signal, else <code>0</code>. A non-zero <code>signal</code> makes the step <code>"FAILED"</code>, even though <code>exit</code> is then <code>0</code>. Always <code>0</code> on Windows (no POSIX signals).</td>
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
  <td>Captured output, with trailing whitespace stripped; <code>''</code> for a stream sent to <code>stdout_file</code> or <code>stderr_file</code>. When the command could not be launched at all (<code>exit</code> is <code>-1</code>), <code>stderr</code> says why, e.g. <code>cannot run "x": No such file or directory</code>.</td>
</tr>
<tr>
  <td><code>conda_env</code>, <code>container</code>, <code>container_args</code>, <code>container_engine</code>, <code>die</code>, <code>dry_run</code>, <code>env</code>, <code>env_secret</code>, <code>executor</code>, <code>executor_args</code>, <code>lock</code>, <code>mem</code>, <code>note</code>, <code>overwrite</code>, <code>protect</code>, <code>quiet</code>, <code>retries</code>, <code>retry_delay</code>, <code>stale</code>, <code>stale_cmd</code>, <code>stderr_file</code>, <code>stdin</code>, <code>stdout_file</code>, <code>threads</code>, <code>timeout</code>, <code>walltime</code>, <code>wrapper</code></td>
  <td>The (defaulted) argument values used. A string option not given is <code>''</code>, a list <code>[]</code>, <code>env</code> is <code>{}</code>, and <code>threads</code> is <code>0</code>. The values <code>env_secret</code> names are <code>(secret)</code> in <code>env</code>. The hooks are not recorded: they are code.</td>
</tr>
<tr>
  <td><code>output_files</code></td>
  <td>Array ref of the output files (a scalar argument, or an <code>output_file</code>, is normalised to a one-element array).</td>
</tr>
<tr>
  <td><code>output_dirs</code></td>
  <td>Array ref of the output directories, normalised as <code>output_files</code> is.</td>
</tr>
<tr>
  <td><code>input_dirs</code></td>
  <td>Array ref of the input directories, normalised the same way; <code>[]</code> if none.</td>
</tr>
<tr>
  <td><code>cmd.changed</code></td>
  <td><code>1</code> if <code>stale_cmd</code> was set and the command on record for the outputs was a different one, else <code>0</code>.</td>
</tr>
<tr>
  <td><code>wrapped.cmd</code></td>
  <td>The command as actually run, inside its executor, container, conda environment and wrapper, space-joined; <code>''</code> if it ran as it is.</td>
</tr>
<tr>
  <td><code>output_file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the outputs, as the command left them (measured before a failed step's outputs are moved aside).</td>
</tr>
<tr>
  <td><code>failed.outputs</code></td>
  <td>Array ref of the names a failed step's outputs were moved to, each the output's own name with <code>.failed</code> appended; <code>[]</code> on every other path.</td>
</tr>
<tr>
  <td><code>input_files</code></td>
  <td>Array ref of the input files, normalised the same way (present only if you passed <code>input_files</code> or <code>input_file</code>).</td>
</tr>
<tr>
  <td><code>input_file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the inputs (present only if you passed <code>input_files</code> or <code>input_file</code>). In a dry run, an input that does not exist yet has <code>undef</code>.</td>
</tr>
<tr>
  <td><code>source.file</code>, <code>source.line</code></td>
  <td>Where in <i>your</i> code the <code>task</code> was called: handy when debugging a long pipeline.</td>
</tr>
</tbody>
</table>

=end html

=begin :text

=over

=item C<cmd>

The command that was run. An array-ref C<cmd> is recorded space-joined for readability; that is not a shell-quoted round trip, since it never went near a shell.

=item C<dir>

Working directory at execution time: the absolute path of C<dir>, if it was given.

=item C<done>

C<"now"> (just ran), C<"before"> (skipped, outputs already existed), or C<"not yet"> (dry run).

=item C<will.do>

C<"done">, C<"no"> (skipped), C<"no: dry run">, or C<"FAILED">. C<"FAILED"> is set whenever the command exited non-zero, was killed by a signal, timed out, or left a declared output file missing — B<whether or not C<die> is set>.

=item C<duration>

Wall-clock seconds the command took (C<0> for skips/dry runs). With L<retries|/"Retries">, the last attempt's.

=item C<attempts>

How many times the command was run: C<0> for a skip or a dry run, C<1> without retries.

=item C<start.time>

When the last attempt started, in epoch seconds with a fractional part; C<0> if none did.

=item C<cpu.user>, C<cpu.system>

CPU seconds the command, and everything it waited for, spent in user and system mode. The clock counts in ticks of 1/100 s on Linux. Not known to be filled in on Windows.

=item C<exit>

Exit code of the command, or C<-1> if it could not be launched at all (C<stderr> then says why).

=item C<signal>

Signal number if the command process was killed by a signal, else C<0>. A non-zero C<signal> makes the step C<"FAILED">, even though C<exit> is then C<0>. Always C<0> on Windows (no POSIX signals).

=item C<timed.out>

C<1> if the command was killed for exceeding its C<timeout>, else C<0>.

=item C<out.of.date>

C<1> if C<stale> was set and an input was newer than an output, else C<0>.

=item C<stdout>, C<stderr>

Captured output, with trailing whitespace stripped; C<''> for a stream sent to C<stdout_file> or C<stderr_file>. When the command could not be launched at all (C<exit> is C<-1>), C<stderr> says why, e.g. C<cannot run "x": No such file or directory>.

=item C<conda_env>, C<container>, C<container_args>, C<container_engine>, C<die>, C<dry_run>, C<env>, C<env_secret>, C<executor>, C<executor_args>, C<lock>, C<mem>, C<note>, C<overwrite>, C<protect>, C<quiet>, C<retries>, C<retry_delay>, C<stale>, C<stale_cmd>, C<stderr_file>, C<stdin>, C<stdout_file>, C<threads>, C<timeout>, C<walltime>, C<wrapper>

The (defaulted) argument values used. A string option not given is C<''>, a list C<[]>, C<env> is C<{}>, and C<threads> is C<0>. The values C<env_secret> names are C<(secret)> in C<env>. The hooks are not recorded: they are code.

=item C<output_files>

Array ref of the output files (a scalar argument, or an C<output_file>, is normalised to a one-element array).

=item C<output_dirs>

Array ref of the output directories, normalised as C<output_files> is.

=item C<input_dirs>

Array ref of the input directories, normalised the same way; C<[]> if none.

=item C<cmd.changed>

C<1> if C<stale_cmd> was set and the command on record for the outputs was a different one, else C<0>.

=item C<wrapped.cmd>

The command as actually run, inside its executor, container, conda environment and wrapper, space-joined; C<''> if it ran as it is.

=item C<output_file.size>

Hash of C<filename =E<gt> size in bytes> for the outputs, as the command left them (measured before a failed step's outputs are moved aside).

=item C<failed.outputs>

Array ref of the names a failed step's outputs were L<moved to|/"Failure behaviour">, each the output's own name with C<.failed> appended; C<[]> on every other path.

=item C<input_files>

Array ref of the input files, normalised the same way (present only if you passed C<input_files> or C<input_file>).

=item C<input_file.size>

Hash of C<filename =E<gt> size in bytes> for the inputs (present only if you passed C<input_files> or C<input_file>). In a dry run, an input that does not exist yet has C<undef>.

=item C<source.file>, C<source.line>

Where in I<your> code the C<task> was called: handy when debugging a long pipeline.

=back

=end :text

=begin :man

=over

=item C<cmd>

The command that was run. An array-ref C<cmd> is recorded space-joined for readability; that is not a shell-quoted round trip, since it never went near a shell.

=item C<dir>

Working directory at execution time: the absolute path of C<dir>, if it was given.

=item C<done>

C<"now"> (just ran), C<"before"> (skipped, outputs already existed), or C<"not yet"> (dry run).

=item C<will.do>

C<"done">, C<"no"> (skipped), C<"no: dry run">, or C<"FAILED">. C<"FAILED"> is set whenever the command exited non-zero, was killed by a signal, timed out, or left a declared output file missing — B<whether or not C<die> is set>.

=item C<duration>

Wall-clock seconds the command took (C<0> for skips/dry runs). With L<retries|/"Retries">, the last attempt's.

=item C<attempts>

How many times the command was run: C<0> for a skip or a dry run, C<1> without retries.

=item C<start.time>

When the last attempt started, in epoch seconds with a fractional part; C<0> if none did.

=item C<cpu.user>, C<cpu.system>

CPU seconds the command, and everything it waited for, spent in user and system mode. The clock counts in ticks of 1/100 s on Linux. Not known to be filled in on Windows.

=item C<exit>

Exit code of the command, or C<-1> if it could not be launched at all (C<stderr> then says why).

=item C<signal>

Signal number if the command process was killed by a signal, else C<0>. A non-zero C<signal> makes the step C<"FAILED">, even though C<exit> is then C<0>. Always C<0> on Windows (no POSIX signals).

=item C<timed.out>

C<1> if the command was killed for exceeding its C<timeout>, else C<0>.

=item C<out.of.date>

C<1> if C<stale> was set and an input was newer than an output, else C<0>.

=item C<stdout>, C<stderr>

Captured output, with trailing whitespace stripped; C<''> for a stream sent to C<stdout_file> or C<stderr_file>. When the command could not be launched at all (C<exit> is C<-1>), C<stderr> says why, e.g. C<cannot run "x": No such file or directory>.

=item C<conda_env>, C<container>, C<container_args>, C<container_engine>, C<die>, C<dry_run>, C<env>, C<env_secret>, C<executor>, C<executor_args>, C<lock>, C<mem>, C<note>, C<overwrite>, C<protect>, C<quiet>, C<retries>, C<retry_delay>, C<stale>, C<stale_cmd>, C<stderr_file>, C<stdin>, C<stdout_file>, C<threads>, C<timeout>, C<walltime>, C<wrapper>

The (defaulted) argument values used. A string option not given is C<''>, a list C<[]>, C<env> is C<{}>, and C<threads> is C<0>. The values C<env_secret> names are C<(secret)> in C<env>. The hooks are not recorded: they are code.

=item C<output_files>

Array ref of the output files (a scalar argument, or an C<output_file>, is normalised to a one-element array).

=item C<output_dirs>

Array ref of the output directories, normalised as C<output_files> is.

=item C<input_dirs>

Array ref of the input directories, normalised the same way; C<[]> if none.

=item C<cmd.changed>

C<1> if C<stale_cmd> was set and the command on record for the outputs was a different one, else C<0>.

=item C<wrapped.cmd>

The command as actually run, inside its executor, container, conda environment and wrapper, space-joined; C<''> if it ran as it is.

=item C<output_file.size>

Hash of C<filename =E<gt> size in bytes> for the outputs, as the command left them (measured before a failed step's outputs are moved aside).

=item C<failed.outputs>

Array ref of the names a failed step's outputs were L<moved to|/"Failure behaviour">, each the output's own name with C<.failed> appended; C<[]> on every other path.

=item C<input_files>

Array ref of the input files, normalised the same way (present only if you passed C<input_files> or C<input_file>).

=item C<input_file.size>

Hash of C<filename =E<gt> size in bytes> for the inputs (present only if you passed C<input_files> or C<input_file>). In a dry run, an input that does not exist yet has C<undef>.

=item C<source.file>, C<source.line>

Where in I<your> code the C<task> was called: handy when debugging a long pipeline.

=back

=end :man



=head2 Skipping completed work

If C<overwrite> is false (the default) and every file in C<output_files> already
exists, C<task> does B<not> re-run the command. This makes pipelines
restartable: re-running the script picks up where it left off.

 open my $log, '>', 'logfile.txt';
 my $t = task(
     cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
     'input_files'  => ['em.mdp', 'box.gro', 'topol.top'],
     'output_files' => 'em.tpr',
     'log_fh'       => $log,
 );
 close $log;

On the first run C<done> is C<"now">; on a re-run (with C<em.tpr> present) C<done>
is C<"before"> and C<will.do> is C<"no">. Pass C<< overwrite =E<gt> 1 >> to force it.

An output file that exists but cannot be B<read> does not count as done: it is
not a usable result, and treating it as one would skip the very step that could
replace it. Nor does the output of a step that failed: that is moved aside to
C<< E<lt>fileE<gt>.failed >> (see L</"Failure behaviour">), so a re-run runs
the step again instead of taking a half-written file as its result.

=head2 Out-of-date outputs

Existence alone is a weak test. If an input file has been edited since the
output was built, the output is stale even though it is present, and by
default C<task> will still skip the step, exactly as earlier versions did.

Pass C<< stale =E<gt> 1 >> to get the rule C<make> and C<snakemake> use: re-run whenever
the newest C<input_files> mtime is later than the oldest C<output_files> mtime.
The mtimes are compared to the sub-second, where the filesystem records that,
so an input rewritten in the same second as its output still counts as newer.

 my $t = task(
     cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
     'input_files'  => ['em.mdp', 'box.gro', 'topol.top'],
     'output_files' => 'em.tpr',
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

Because the command has a process group of its own, a Ctrl-C at the terminal
reaches only your script, not the command. C<task> therefore catches C<INT>,
C<TERM>, C<HUP> and C<QUIT> while a timed command runs, kills the command's group,
writes the record, and then passes the signal on: to your own handler if you
have one, and otherwise it ends the script as it would have without C<task> in
the way. A signal your script ignores stays ignored.

With C<< stdin =E<gt> 'inherit' >> and a terminal on standard input, the command is
given the terminal's foreground for the duration, as a shell gives it to a job,
so that it can read from the terminal; your script takes it back afterwards.
A Ctrl-Z then suspends the command and your script together, as a shell
suspends a job, with the timeout's clock stopped, and C<fg> carries on with
both. The same holds without a C<timeout>.

Without a C<timeout> the command has a process group of its own as well, so
that a signal reaches the whole of it, not just the shell at its head. A
C<TERM> or C<HUP> sent to your script, by a batch scheduler or C<kill>, is passed
on to the command's group, which is waited for; then the record is written and
the signal passed on to your script, as with a timeout. A Ctrl-C (C<INT>) or
C<QUIT> is passed on to the group in the same way, but, as under C<system>, not
to your script afterwards: the step fails, killed by the signal, and C<die>
decides what happens next. A Ctrl-Z stops the command and your script together,
and C<fg> or C<bg> carries on with both. A command that opens the terminal
itself, as C<ssh> or C<sudo> do to ask for a password, is given its foreground
while your script has it to give.

If one of your own signal handlers dies while a command runs, the command's
group is killed and waited for before the exception reaches your code.
Before 0.192 the command was left running.

An C<alarm> your script already had pending is kept: it is put back when the
command finishes, less the time the command took, and if it fell due while the
command ran it is delivered then.

C<timeout> needs C<fork()> and POSIX process groups, so it is refused on
C<MSWin32>. Leaving it at C<0> (the default) changes nothing anywhere.

=head2 Retries

A step that fails for a reason outside its control, such as a flaky network or
a busy licence server, can be run again automatically:

 my $t = task(
     cmd           => 'fetch-data --to data.csv',
     'output_file' => 'data.csv',
     retries       => 3,
     'retry_delay' => 30,
 );

A failed attempt, for any of the reasons in
L</"Failure behaviour">, has its outputs moved aside and is
reported on C<STDERR> and in the log (C<attempt 1 of 4, retrying in 30s>); then
the command runs again. Only when the last attempt fails does the step fail,
and C<die> apply. The record describes the last attempt, and C<attempts> says how
many there were. An interrupt under a C<timeout> is never retried, since it is a
request for the whole program to stop. This is Nextflow's C<errorStrategy
'retry'> and Snakemake's C<--retries>.

=head2 Environment and directory

C<env> sets environment variables for the command alone, and C<dir> runs the step
in another directory:

 my $t = task(
     cmd           => 'make all',
     dir           => 'build',
     env           => { CFLAGS => '-O2', MAKEFLAGS => undef },
     'output_file' => 'a.out',            # that is, build/a.out
 );

A value of C<undef> in C<env> removes the variable for the command. Your script's
own C<%ENV> is untouched: it is put back as soon as the command finishes.

Under C<dir> the whole step happens in that directory, the input and output
checks as well as the command, so every name it declares is relative to it, as
the command itself sees it. Your script is back in its own directory when
C<task> returns, however it returns, dying included. The record's C<dir> is the
absolute path the step ran in.

=head2 Secrets

The record holds the C<env> a step was given, and the record is printed, written
to the log and written to the trace. A credential passed in C<env> would be
written out with it. C<env_secret> names the variables whose values must not be:

 my $t = task(
     cmd          => 'fetch-data --to data.csv',
     env          => { API_TOKEN => $token },
     'env_secret' => ['API_TOKEN'],
 );

The command is given the real value; everywhere else, the record included, it
is C<(secret)>, and so it is in the arguments printed with an error. A secret's
value is not part of what L<stalecmd|/"Re-running a changed command">
compares, so a new token does not re-run every step. C<env_secret> in
L<%SimpleFlow::DEFAULTS|/"Defaults for a whole pipeline"> is combined with a
step's own, as C<env> is.

Nothing else is hidden: the command line, C<note> and every other C<env> value
are written out in full. Pass a credential through C<env>, never on the command
line.

=head2 Output to files

A command that prints a great deal is better written to a file than held in
memory and printed in the record:

 my $t = task(
     cmd           => 'aligner --verbose reads.fq',
     'stdout_file' => 'align.out',
     'stderr_file' => 'align.log',
 );

The files are emptied when the step starts and receive the output of every
attempt, in order; the record's C<stdout> and C<stderr> are then C<''>. That holds
even when the file is also a declared output, or is inside one: a failed
attempt that is to be retried leaves such an output where it is, and only a
step that has failed for good moves it aside. Naming the
same file for both puts the two streams in it interleaved, as a terminal would
show them. A step that is skipped, or dry-run, leaves the files alone, so they
still hold the output of the run that made the step's outputs. This is
Snakemake's C<log:> directive.

=head2 Directory outputs

A step whose result is a directory declares it with C<output_dir> (or a list,
C<output_dirs>), as Snakemake's C<directory()> does:

 my $t = task(
     cmd          => 'split-by-sample input.bam samples',
     'input_file' => 'input.bam',
     'output_dir' => 'samples',
 );

A declared directory counts as made if it exists, and the step is skipped when
all its outputs, files and directories alike, exist already. A directory that
exists but is empty is warned about, as an empty output file is. When the step
fails, the directory is moved aside to C<samples.failed> like any other output.
Under C<stale>, a directory is as new as the newest thing in it.

A directory can be an input, too: C<input_dir> and C<input_dirs> must exist, and
be readable, before the step runs, just as C<input_files> must, and under
C<stale> an output is out of date if anything in an input directory is newer
than it.

=head2 Protected outputs

C<< protect =E<gt> 1 >> makes a step's outputs read-only once it succeeds, and, for a
directory output, everything in it, as Snakemake's C<protected()> does:

 my $t = task(
     cmd           => 'expensive-simulation > result.dat',
     'output_file' => 'result.dat',
     protect       => 1,
 );

Re-running such a step over its outputs, with C<overwrite> or C<stale>, is then
refused with a message naming them, instead of failing inside the command with
an error that does not say why the file is read-only. Remove them, or make them
writable, to run it again. Symbolic links are left alone. C<root> can write to a
read-only file, so for C<root> this protects nothing.

=head2 Tracing

C<trace_fh> takes a filehandle and appends one line of JSON to it for every
task, on every path (run, skipped, dry-run or failed), in the spirit of
Nextflow's C<trace.txt>:

 open my $trace, '>>', 'trace.jsonl' or die $!;
 local %SimpleFlow::DEFAULTS = ('trace_fh' => $trace);

Each line holds every field of the record except C<stdout> and C<stderr>, which
can be any size, plus C<time>, when the line was written: the command line and
C<env> included, so see L</"Secrets">. Open the file without an encoding
layer: the lines are UTF-8 already.

=head2 Locking

C<< lock =E<gt> 1 >> protects a step against a second copy of the same pipeline running
it at the same time. The first run to reach the step takes a lock on its
outputs; a second run that reaches it meanwhile says it is waiting, waits, and
then finds the outputs made and skips the step:

 my $t = task(
     cmd           => 'long-step > out.txt',
     'output_file' => 'out.txt',
     lock          => 1,
 );

The lock files are kept in C<.simpleflow/> in the working directory (the one
C<dir> names, if it is given), as Snakemake keeps its locks in C<.snakemake/>,
so two runs see each other only when they share a working directory. The files
are left there afterwards, since removing one that another process is waiting
on would let two runs through. A step with no declared outputs has nothing to
lock, and a dry run takes no lock. The locks are C<flock> locks, which some
network filesystems do not honour.

An output is locked under its real directory and its own name, so C<out> and
C<sub/../out>, or a name reached through a linked directory, are one output
here; an output that is itself a symbolic link is locked under what it points
at as well. A step also takes a shared lock on every directory above each of
its outputs, so that a step whose output is a directory, and one whose output
is a file inside it, do not run at once. Two hard links to one file are still
two outputs.

C<.simpleflow/>, and C<.simpleflow/cmd/> under it, must be directories, not
symbolic links: C<task> refuses a link there, and opens nothing inside them
through one. These guard against a link planted by someone else; they do not
make a working directory others can write to safe to run a pipeline in.

=head2 Re-running a changed command

By default a step whose outputs exist is skipped even if its command has been
edited since they were made. C<< stale_cmd =E<gt> 1 >> re-runs it, as Snakemake's
C<params> and C<code> rerun triggers do:

 my $t = task(
     cmd           => 'bwa mem -t 8 -k 19 ref.fa reads.fq > aln.sam',
     'output_file' => 'aln.sam',
     'stale_cmd'   => 1,
 );

Changing the command, its C<env>, its C<threads>, or what it runs inside (its
container, conda environment, executor or wrapper) makes C<cmd.changed> C<1> and
the step run again. What made each set of outputs is kept, as a digest, in
C<.simpleflow/cmd/> in the working directory, and written only after a
successful run. Outputs that exist with nothing on record, made before
C<stale_cmd> was used, or by hand, are not re-run: the command is recorded
against them, so that the next change is seen.

A step run I<without> C<stale_cmd> over outputs that have a command on record
still replaces them, so after it succeeds its own command is recorded in place
of the old one, and a later C<stale_cmd> run of the old command runs again
rather than taking the other's outputs as its own. With nothing on record, a
step without C<stale_cmd> records nothing.

=head2 Hooks

C<on_success> and C<on_failure> are called with the record once a command has
run, after the record is printed and logged:

 local %SimpleFlow::DEFAULTS = (
     'on_failure' => sub { my $r = shift; notify("$r->{cmd} failed: exit $r->{exit}") },
 );

C<on_failure> runs before C<task> dies, so it runs under the default C<< die =E<gt> 1 >>
as well. Neither is called for a step that is skipped or dry-run. A hook that
dies stops C<task> there, with its own exception. Set in C<%SimpleFlow::DEFAULTS>,
they are the pipeline-wide C<onsuccess> and C<onerror> of Snakemake.

=head2 Containers, conda and clusters

A command can be run inside a container, a conda environment, a SLURM job
step, or any wrapper you name:

 my $t = task(
     cmd       => ['samtools', 'index', 'x.bam'],
     container => 'biocontainers/samtools:1.19',   # with docker, by default
 );
 my $u = task(
     cmd         => 'python train.py',
     'conda_env' => 'analysis',
     executor    => 'slurm',
     threads     => 8,
     mem         => '16G',
     walltime    => '2:00:00',
 );

C<container> runs C<docker run --rm> (or C<podman run>) with the working directory
mounted at its own path and used as the container's working directory, and,
for docker, with your own user and group, so that the files the command makes
are yours. C<< container_engine =E<gt> 'singularity' >> or C<'apptainer'> runs
C<singularity exec> with the working directory bound instead. The variables
C<env> sets are passed into a docker or podman container by name; singularity
and apptainer pass the whole environment through themselves.

C<conda_env> runs C<< conda run -n E<lt>nameE<gt> >>, or C<< -p E<lt>pathE<gt> >> for a path.

C<< executor =E<gt> 'slurm' >> runs the command through C<srun>, which waits for the job
step and passes its exit status back, asking for C<threads> CPUs, C<mem> memory
and C<walltime> time; C<executor_args> adds any other C<srun> arguments. With
L<parallel|/"Running steps in parallel">, several steps run on the cluster at
once. C<threads> is also given to the command, wherever it runs, as
C<SIMPLEFLOW_THREADS>, for it to pass to its own option for threads.

C<wrapper> runs the command inside any other command, given as an array ref,
such as C<['nice', '-n', '10']> or C<['env', 'LC_ALL=C']>.

These nest, outermost first, as executor, container, conda environment,
wrapper. A string C<cmd> is run by C</bin/sh -c> (C<cmd.exe /c> on MSWin32) inside
all of them, so it keeps its pipes and redirections. The record's C<wrapped.cmd>
is what was actually run, and a dry run prints it.

=head2 Running without a shell

Giving C<cmd> an array ref runs the command directly, with no shell in between:

 my $t = task(
     cmd           => ['gzip', '-9', $file],   # $file needs no quoting
     'output_file' => "$file.gz",
 );

This is the form to reach for when an argument comes from data — a filename
with a space, a quote, or a C<$> in it is passed through untouched instead of
being re-parsed by the shell. You lose shell features (C<< E<gt> >>, C<|>, C<*>, C<&&>) in
exchange; use the string form when you want them.

This holds for a one-element array ref too: C<< cmd =E<gt> ['gzip -9 x'] >> looks for a
program literally named C<gzip -9 x>, and fails, rather than handing the string
to the shell as Perl's own C<system> does with a list of one.

=head2 Quiet runs

Every C<task> prints its record to the terminal. Error diagnostics — the
arguments and file lists printed before C<task> dies or warns — go to C<STDERR>,
so redirecting standard output does not hide them. Over a hundred-step pipeline
that is a lot of scrollback, so C<< quiet =E<gt> 1 >> suppresses it:

 my $t = task(
     cmd      => 'one of very many steps',
     'log_fh' => $log,
     quiet    => 1,
 );

The log filehandle still receives the full record, and error messages still go
to C<STDERR>: asking for less noise is not the same as asking to be kept in the
dark about a failure.

=head2 Standard input

The command is run with its standard input on the null device, so a command
that stops to ask a question gets an immediate end-of-file and carries on
instead of waiting for an answer:

 my $t = task(cmd => 'rm -r some/tree');   # "remove write-protected file?"

This matters because C<task> captures the command's output. A prompt is written
to standard error, which has been redirected into the capture, so nothing
reaches the terminal: before 0.17 such a command hung with no visible reason —
for ever with no C<timeout>, and with one it was killed and reported as
C<timed.out>, blaming the clock for what was really an unanswered question.

Shell redirection inside the command is unaffected, since that is the shell's
business rather than C<task>'s:

 my $t = task(cmd => 'sort < unsorted.txt > sorted.txt');

To hand the command the caller's own standard input instead — a pipeline step
that really does read the data your script was given — ask for it:

 my $t = task(cmd => 'sort > sorted.txt', stdin => 'inherit');

C<'inherit'> is the behaviour of 0.162 and earlier, and comes with its hazards:
the command consumes input your own script can then no longer read, and a
command that prompts will hang exactly as it used to. The caller's standard
input is saved and restored around every run either way, including when the
command dies, and a caller that had closed it keeps it closed. A C<STDIN> that
is not descriptor 0, such as one opened on an in-memory scalar, is not the
command's standard input in any case: it is left alone, and descriptor 0 is
pointed at the null device and put back instead.

=head2 Dry runs

Useful for inspecting a pipeline without executing anything expensive:

 my $t = task(
     cmd       => 'a long-running, time-consuming command',
     'dry_run' => 1,
     'log_fh'  => $fh,
 );

The command is printed (and logged) but not run; C<will.do> is C<"no: dry run">.
The record is printed and logged as for any other step.

A dry run makes nothing, so a later step's input — an earlier step's output —
is legitimately absent. A dry run therefore does not die over a missing
C<input_files> entry, as a real run does; it lists it under "these input files
do not exist yet", and the dry run of the whole pipeline carries on.

=head2 Failure behaviour

By default (C<< die =E<gt> 1 >>) C<task> dies if the command exits non-zero, is killed by
a signal, exceeds its C<timeout>, or leaves any declared C<output_files> missing
afterwards, so a broken step stops the pipeline immediately. The message names
every one of those that happened, for instance
C<"make all" exited 2; these output files should have been made but are missing:
a.out, from build.pl line 12>. When the command wrote anything to standard
error, the message ends with its last six lines, which is where a compiler, a
traceback or C<make> says what went wrong.

Whichever of those happened, every declared output that I<does> exist is moved to
C<< E<lt>fileE<gt>.failed >> (replacing any C<.failed> left from before), and the new names are
listed in the record's C<failed.outputs> and on C<STDERR>. A name declared twice
is moved once; a file inside a declared directory moves with the directory,
under its own name; and when one output is named like another's C<.failed>, as
C<out> and C<out.failed> are, the longer name is moved first, so that neither is
lost. When the message quotes standard error from a C<stderr_file> that was one
of the outputs, it is read before the file is moved. A command that fails
part-way often leaves a truncated file behind; left under its own name, it would
pass the L<skip test|/"Skipping completed work"> on the next run and become the
result for good. Snakemake deletes a failed job's outputs for the same reason;
moving them keeps the partial contents for debugging.

With C<< die =E<gt> 0 >>, C<task> instead warns and returns its result hash with
C<< will.do =E<gt> "FAILED" >>, letting you decide what to do:

 my $t = task(cmd => 'a step that may fail', die => 0);
 if ($t->{'will.do'} eq 'FAILED') {
     ...   # $t->{'exit'}, $t->{signal}, $t->{stderr} and $t->{'timed.out'} say why
 }

=head2 Defaults for a whole pipeline

C<%SimpleFlow::DEFAULTS> gives a value to any key a C<task> call leaves undefined:

 local %SimpleFlow::DEFAULTS = (
     'dry_run'  => 1,          # dry-run the whole pipeline
     'log_fh'   => $log,
     quiet      => 1,
     env        => { LC_ALL => 'C' },
 );

A task that sets a key itself keeps its own value. C<env> is the one exception:
a task's own C<env> is merged with the default one, its own entries winning, and its own C<env_secret> is added to the default one.
Keys that name a particular step (C<cmd>, the C<input.*> and C<output.*> lists,
C<stdout_file> and C<stderr_file>) are refused in C<%DEFAULTS>, since every step
would then run the same command or claim the same files, and so is any key
C<task> does not accept.

=head2 C<say2>

 say2($message, $filehandle);

"Say to two places": prints C<$message> to standard output B<and> to the given
log filehandle, prefixed with the calling file and line number so log entries
are traceable. The filehandle must be open, or C<say2> dies.

 open my $log, '>', 'run.log';
 say2('starting equilibration', $log);   # -> STDOUT and run.log
 close $log;

=head1 Running steps in parallel

C<parallel> runs independent steps at the same time, at most C<jobs> at once,
and returns their records in the order given:

 my @records = parallel(
     jobs  => 4,
     tasks => [
         map { { cmd => "gzip -9 $_", 'input_file' => $_, 'output_file' => "$_.gz" } } @samples
     ],
 );

Each entry of C<tasks> is the arguments of one C<task>, which runs in full, in a
child process of its own: its checks, its log, its record, its options, and
C<%SimpleFlow::DEFAULTS>. Each record's C<source.file> and C<source.line> are the
C<parallel> call's. Output from several steps at once interleaves, a record at
a time, on the terminal, in a shared log and in a shared L<trace|/"Tracing">:
each step writes its record holding a lock, so that no two records are mixed
within a line.

When a step fails, and C<task> would die, no further step is started; those
already running are left to finish, and then C<parallel> dies with every
failure. C<< 'keep_going' =E<gt> 1 >> runs every step regardless, and dies at the end if
any failed, as Snakemake's C<--keep-going> does. Under C<< die =E<gt> 0 >> a failed step
is only a record with C<< will.do =E<gt> "FAILED" >>, and C<parallel> returns.

A C<TERM>, C<HUP>, C<INT> or C<QUIT> sent to your script while C<parallel> runs is
passed to every running step as C<TERM>, which each passes to its command; once
they have ended, the signal is passed on to your script.

C<jobs> above 1 needs a real C<fork()>, so it is refused on C<MSWin32>, where perl
emulates one with threads. C<< jobs =E<gt> 1 >> runs the steps one after another, and
works everywhere.

The order of steps that depend on each other is still yours: C<parallel> runs
the ones it is given at once, so give it only steps that can run together, and
call it again for the next stage.

=head1 Reports

C<report> turns a L<trace|/"Tracing"> into a single HTML page:

 report(trace => 'trace.jsonl', html => 'report.html', title => 'RNA-seq, batch 3');

The page counts the tasks by status, and lists each with its status, command,
note, start time, duration, CPU time, exit code, signal, attempts and where in
your script it was called, alongside a timeline of when each ran. It is one
self-contained file, with no scripts and nothing fetched, which follows the
reader's light or dark setting, so that it can be mailed or archived as it
is. C<report> returns the number of tasks it read, and dies naming the line of
the trace it could not read: one that is not strict JSON in UTF-8, nests more
than 512 deep, or has a time that is not a number of seconds or a command that
is not a string. A C<title> may be a character string or UTF-8 bytes.

=head1 Dependencies

Core/runtime modules used by SimpleFlow:

=over

=item * L<Data::Printer> (C<DDP>) pretty result/record printing

=item * L<Devel::Confess> stack traces, in colour on a
terminal, for errors and warnings raised inside C<task> and C<say2>. It is
switched on only for the length of each call, so your own program's C<die>
and C<warn> are left exactly as you wrote them.

=item * C<List::Util>, C<Scalar::Util>, C<Time::HiRes>, C<Cwd>, C<POSIX>, C<File::Spec>,
C<File::Temp>, C<File::Find>, C<File::Path>, C<Fcntl>, C<Digest::MD5>, C<Storable>
core utilities; C<stdout> and C<stderr> are captured with
C<POSIX::dup2> onto temporary files

=back

The test suite additionally uses C<Test::More>,
L<JSON::PP> (core from perl 5.14) and
L<Test::Exception>; it captures
output with its own small helper, C<t/lib/CaptureStd.pm>.

=head1 Changes

The release notes are in the C<Changes> file at the root of the
distribution, in the format CPAN itself reads.

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

=head1 Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI, and to Brett Estrade and Hexmeister for help.
