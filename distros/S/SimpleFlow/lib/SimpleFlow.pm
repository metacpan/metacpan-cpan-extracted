# ABSTRACT: SimpleFlow - easy, simple workflow manager (and logger); for keeping track of and debugging large and complex shell command workflows
use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Cwd 'getcwd';
package SimpleFlow;
our $VERSION = 0.13;
use Time::HiRes;
use Term::ANSIColor;
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
use Scalar::Util 'openhandle';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Cwd 'getcwd';
use warnings FATAL => 'all';
use Capture::Tiny 'capture';
use List::Util 'max';
use Exporter 'import';
our @EXPORT = qw(say2 task);
our @EXPORT_OK = @EXPORT;

sub say2 { # say to both command line and log file
	my ($msg, $fh) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my @c = caller;
	if (not openhandle($fh)) {
		die "the filehandle given to $current_sub with \"$msg\" from $c[1] line $c[2] isn't actually a filehandle";
	}
	$msg = "\@ $c[1] line $c[2] $msg";
	say $msg;
	say $fh $msg;
	return $msg;
}

sub task {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
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
		'die',			  # die if not successful; 0 or 1
		'dry.run',       # dry run or not
		'input.files',   # check for input files; SCALAR or ARRAY
		'log.fh',
		'note',          # a note for the log
		'overwrite',     # 
		'output.files'	  # product files that need to be checked; can be scalar or array
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
	my (%input_file_size, @existing_files, @output_files, @empty_filenames);
	if (defined $args->{'input.files'}) {
		my $ref = ref $args->{'input.files'};
		my @missing_files;
		if ($ref eq 'ARRAY') {
			@missing_files = grep {not -f -r $_ } @{ $args->{'input.files'} };
			%input_file_size = map { $_ => -s $_ } @{ $args->{'input.files'} };
			@empty_filenames = grep {length $_ == 0} @{ $args->{'input.files'} };
		} elsif ($ref eq '') { # scalar
			@missing_files = grep {not -f -r $_ } ($args->{'input.files'});
			%input_file_size = map { $_ => -s $_ } ($args->{'input.files'} );
			@empty_filenames = grep {(defined $_) && (length $_ == 0)} ($args->{'input.files'});
		} else {
			p $args;
			die 'ref type "' . $ref . '" is not allowed for "input.files"';
		}
		if (scalar @missing_files > 0) {
			say STDERR 'this list of arguments:';
			p $args;
			say STDERR 'Cannot run because these files are either missing or unreadable in: ' . getcwd();
			p @missing_files;
			die 'the above files are missing or are not readable';
		}
	}
	if (scalar @empty_filenames > 0) {
		p $args;
		die '0-length filenames are not allowed (found in "input.files")';
	}
	my $msg = "\@ $c[1] line $c[2] The command is:\n" . colored(['blue on_bright_red'], $args->{cmd});
	say $msg;
	say {$args->{'log.fh'}} "\@ $c[1] line $c[2] The command is:\n $args->{cmd})" if defined $args->{'log.fh'};
	if (defined $args->{'output.files'}) { # avoid "uninitialized value" warning
		my $ref = ref $args->{'output.files'};
		if ($ref eq 'ARRAY') {
			@output_files = @{ $args->{'output.files'} };
		} elsif ($ref eq '') { # a scalar
			@output_files = $args->{'output.files'};
		} else {
			p $args;
			die "$ref isn't allowed for \"output.files\"";
		}
	}
	@empty_filenames = grep {length $_ == 0} @output_files; # 0-length filenames aren't allowed
	if (scalar @empty_filenames > 0) {
		p $args;
		die '0-length filenames are not allowed (found in "output.files"';
	}
	if (scalar @output_files > 0) {
		@existing_files = grep {-f $_} @output_files;
	}
	my %r = (
		cmd            => $args->{cmd},
		dir				=> getcwd(),
		'source.file'  => $c[1],
		'source.line'  => $c[2],
		'output.files' => [@output_files],
	);
	$r{'die'}     = $args->{'die'}     // 1; # by default, true
	$r{'dry.run'} = $args->{'dry.run'} // 0; # by default, false
	$r{note}      = $args->{note}      // '';# by default, false
	$r{overwrite} = $args->{overwrite} // 0; # by default, false
	$r{'will.do'} = 'yes';
	$r{'will.do'} = 'no: dry run'  if $args->{'dry.run'};
	my $string_max = 0;
	if (defined $args->{'input.files'}) {
		$r{'input.files'} = $args->{'input.files'};
		$r{'input.file.size'} = \%input_file_size;
	}
	my %output_file_size = map {$_ => -s $_} @output_files;
	foreach my $val (grep {ref $r{$_} eq ''} keys %r) {
		$string_max = max($string_max, length $r{$val});
	}
	if ((!$args->{overwrite}) && (scalar @output_files > 0) && (scalar @existing_files == scalar @output_files)) { # this has been done before
		$r{done} = 'before';
		$r{'will.do'} = 'no';
		say colored(['black on_green'], "\"$args->{cmd}\"\n") . ' has been done before';
		$r{'output.file.size'} = \%output_file_size;
		$r{duration} = 0;
		p(%r, output => $args->{'log.fh'}, string_max => $string_max) if defined $args->{'log.fh'};
		p %r, string_max => $string_max;
		return \%r;
	} else {
		$r{done} = 'not yet';
	}
	if ($r{'dry.run'}) {
		say "\@ $c[1] line $c[2] in $r{dir} the command was going to be:";
		say colored(['red on_black'], "\"$args->{cmd}\"");
		say 'But this is a dry run';
		say '-------------';
		$r{duration} = 0;
		return \%r;
	}
	my $t0 = Time::HiRes::time();
	my $status;
	($r{stdout}, $r{stderr}, $status) = capture {
		system( $args->{cmd} );
	};
	my $t1 = Time::HiRes::time();
	$r{duration} = $t1-$t0;
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
		$string_max = max($string_max, length $r{$std});
	}
	$r{done} = 'now';
	$r{'will.do'} = 'done';
	my @missing_output_files = grep {not -f -r $_} @output_files;
	if (scalar @missing_output_files > 0) {
		$r{'will.do'} = 'FAILED';
		say STDERR "this input to $current_sub:";
		p $args;
		say {$args->{'log.fh'}} "this input to $current_sub:" if defined $args->{'log.fh'};
		p($args, output => $args->{'log.fh'}, string_max => $string_max) if defined $args->{'log.fh'};
		say STDERR 'has these output files missing:';
		say {$args->{'log.fh'}} 'has these output files missing:' if defined $args->{'log.fh'};
		p @missing_output_files;
		p(@missing_output_files, output => $args->{'log.fh'}, string_max => $string_max) if defined $args->{'log.fh'};
		p %r, string_max => $string_max;
		p(%r, output => $args->{'log.fh'}, string_max => $string_max) if defined $args->{'log.fh'};
		if ($args->{'die'}) {
			die 'those above files should have been made but are missing';
		} else {
			say STDERR 'those above files should have been made but are missing';
		}
	}
	%output_file_size = map {$_ => -s $_} @output_files;
	$r{'output.file.size'} = \%output_file_size;
#	p %output_file_size;
	my @files_with_zero_size = grep { ($output_file_size{$_} // 0) == 0 } @output_files;
	if (scalar @files_with_zero_size > 0) {
		p @files_with_zero_size;
		warn 'the above output files have 0 size.';
	}
	p(%r, output => $args->{'log.fh'}) if defined $args->{'log.fh'};
	if (($r{'die'}) && ($r{'exit'} != 0)) {
		$r{'will.do'} = 'FAILED';
		p %r, string_max => $string_max;
		die "\"$args->{cmd}\" failed from $c[1] line $c[2]"
	}
	p %r, string_max => $string_max;
	return \%r;
}
1;

=encoding utf8

A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to B<debug> and B<reproduce>.

Every step is a single C<task()> call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its C<stdout>,
C<stderr>, exit code and signal, optionally logs a full structured record, and
skips work that has already been done.

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
 
 my $t = task({
     cmd            => 'which ls',
     'output.files' => '/tmp/AFK3mnEK8L.log',
 });

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
 > L<change log|/"Change log">.

=head1 C<task>

 my $result = task(\%args);

Runs one shell command with checking, timing, capture and logging. Takes a
B<single hash reference>; the only required key is C<cmd>.

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
  <td>scalar</td>
  <td><code>undef</code></td>
  <td><b>Required.</b> The shell command to run.</td>
</tr>
<tr>
  <td><code>die</code></td>
  <td>bool (<code>0</code>/<code>1</code>)</td>
  <td><code>1</code></td>
  <td>Die if the command fails (non-zero exit) or an output file is missing. Set to <code>0</code> to warn and continue instead.</td>
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
  <td><code>output.files</code></td>
  <td>scalar or array</td>
  <td><code>undef</code></td>
  <td>File(s) expected to exist <b>after</b> running; used both for the missing-output check and for skip detection.</td>
</tr>
<tr>
  <td><code>log.fh</code></td>
  <td>open filehandle</td>
  <td><code>undef</code></td>
  <td>If given, the full result record is also written here. Must be a real, open filehandle.</td>
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
</tbody>
</table>

=end html



Passing an unrecognised key, an empty filename, or a non-filehandle C<log.fh>
causes C<task> to die: these are usually mistakes worth catching early.

=head2 Return value

C<task> always returns a hash reference. The fields below are present after a
normal run; the L<skip|/"Skipping completed work"> and L<dry-run|/"Dry runs"> paths
omit the execution-only fields (C<exit>, C<signal>, C<stdout>, C<stderr>).



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
  <td>The command that was run.</td>
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
  <td><code>"done"</code>, <code>"no"</code> (skipped), <code>"no: dry run"</code>, or <code>"FAILED"</code>.</td>
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
  <td><code>stdout</code>, <code>stderr</code></td>
  <td>Captured output, with trailing whitespace stripped.</td>
</tr>
<tr>
  <td><code>die</code>, <code>dry.run</code>, <code>overwrite</code>, <code>note</code></td>
  <td>The (defaulted) argument values used.</td>
</tr>
<tr>
  <td><code>output.files</code></td>
  <td>Array ref of the output files (a scalar argument is normalised to a one-element array).</td>
</tr>
<tr>
  <td><code>output.file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the outputs.</td>
</tr>
<tr>
  <td><code>input.files</code></td>
  <td>The input argument, as given (present only if you passed <code>input.files</code>).</td>
</tr>
<tr>
  <td><code>input.file.size</code></td>
  <td>Hash of <code>filename => size in bytes</code> for the inputs (present only if you passed <code>input.files</code>).</td>
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
 my $t = task({
     cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
     'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
     'output.files' => 'em.tpr',
     'log.fh'       => $log,
 });
 close $log;

On the first run C<done> is C<"now">; on a re-run (with C<em.tpr> present) C<done>
is C<"before"> and C<will.do> is C<"no">. Pass C<< overwrite =E<gt> 1 >> to force it.

=head2 Dry runs

Useful for inspecting a pipeline without executing anything expensive:

 my $t = task({
     cmd       => 'a long-running, time-consuming command',
     'dry.run' => 1,
     'log.fh'  => $fh,
 });

The command is printed (and logged) but not run; C<will.do> is C<"no: dry run">.

=head2 Failure behaviour

By default (C<< die =E<gt> 1 >>) C<task> dies if the command exits non-zero or if any
declared C<output.files> are missing afterwards, so a broken step stops the
pipeline immediately. With C<< die =E<gt> 0 >>, C<task> instead warns and returns its
result hash (with C<< will.do =E<gt> "FAILED" >>), letting you decide what to do.

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

=item * L<Term::ANSIColor> coloured terminal output

=item * C<List::Util>, C<Scalar::Util>, C<Time::HiRes>, C<Cwd> core utilities

=back

The test suite additionally uses C<Test::More> and
L<Test::Exception>.

=head1 Change log

=head2 0.13 (2026-06-11)

=head3 Fixed (Claude Opus 4.8 helped)

=over

=item * B<Exit status and signal are now decoded correctly.> C<task()> previously
computed the exit code (C<< $status E<gt>E<gt> 8 >>) and I<then> derived the signal as
C<$exit & 127>. Because the signal lives in the low byte of the raw wait
status, which C<< E<gt>E<gt> 8 >> discards the C<signal> field was always wrong: a clean
C<exit 42> was reported as C<signal 42>, and a process actually killed by a
signal reported C<signal 0>. The signal is now read from the raw status before
shifting, so C<exit> and C<signal> are independent and accurate.

=item * B<< No longer dies on a missing output file when C<< die =E<gt> 0 >>. >> The zero-size
check did C<(-s $file) == 0>, which is C<undef == 0> when a declared output file
is absent. Under C<< use warnings FATAL =E<gt> 'all' >> that "uninitialized value"
warning was fatal, so a task that was meant to I<warn> about missing output
(with C<< die =E<gt> 0 >>) crashed instead. Missing sizes are now treated as C<0>, so
the task warns and returns its result hash as intended.

=item * B<< The "already done" result is now logged with its C<duration>. >> In the
short-circuit path (output files already exist), C<duration> was set I<after>
the record was written to the log, so the logged hash was missing it; the
duplicate C<< done =E<gt> 'before' >> assignment was also removed.

=back

=head3 Changed / Windows support

=over

=item * B<Portable exit-status handling.> Decoding now branches on C<$^O>: Windows has
no POSIX signals (C<signal> is reported as C<0> there), and a C<system()> that
fails to launch the command (C<-1>) yields C<< exit =E<gt> -1 >> instead of a garbage
value from shifting C<-1>.

=item * B<ANSI colour is disabled on the legacy Windows console.> C<Term::ANSIColor>
output is suppressed on C<MSWin32> unless an ANSI-capable terminal is detected
(Windows Terminal, ConEmu, or ANSICON), so C<cmd.exe> no longer prints raw
escape sequences and redirected logs stay clean. Unix and modern Windows
terminals are unaffected.

=back

=head3 Tests

=over

=item * Rewrote C<t/01.t> to be cross-platform: shell commands now invoke the running
Perl interpreter (C<"$^X" -e ...>) instead of Unix-only tools (C<which>, C<ls>,
C<ln>, C<cp>), and temp files use the system temp directory instead of a
hard-coded C</tmp>.

=item * Added regression tests for both fixed bugs (exit/signal decoding; surviving a
missing output file with C<< die =E<gt> 0 >>).

=item * Added coverage for the C<note> field, the C<input.file.size> / C<output.file.size>
hashes, scalar-vs-array normalisation of C<input.files> / C<output.files>, the
C<dir> / C<source.file> / C<source.line> metadata, captured C<stdout> / C<stderr>
(including trailing-whitespace stripping), and argument validation (missing
C<cmd>, unknown keys, bad C<log.fh>, missing input files).

=back

=head2 0.12

exit code now matches what shell would show it as; signal now appears

=head2 0.11

max string length now corresponds to max of output strings, no more truncated output
added List::Util dependency for string length maxes
memory size now shows when output
directory is now output during dry runs
