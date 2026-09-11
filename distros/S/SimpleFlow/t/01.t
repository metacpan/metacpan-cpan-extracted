#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception; # die_ok / lives_ok
use Capture::Tiny 'capture';
use File::Temp 'tempfile';
use Cwd 'getcwd';
use DDP;
use SimpleFlow qw(task say2);

#
# Portability: the original tests called Unix-only tools (which/ls/ln/cp) and
# hard-coded /tmp, which fails on Windows CPAN testers. Use the running Perl
# interpreter instead -- it is always present -- and let File::Temp pick the
# system temp dir. $^X is quoted in case its path contains spaces (Windows).
# NB: the $code passed to perl_cmd() must not itself contain double quotes.
#
my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

#
# task() prints the result record to the terminal unless "quiet", and its
# failure paths dump the arguments with "p" and then warn or die -- all of that
# is by design, and all of it lands on the terminal. In a test file it buries
# the TAP: a clean, wholly successful run of this file printed 696 lines of
# record dumps and four backtraces, which reads exactly like a crash.
# quietly() captures both streams for one call and hands back what the call
# returned; an exception still propagates, so dies_ok and throws_ok work
# through it.
#
# Capturing, rather than passing "quiet => 1", is what keeps the arguments the
# tests hand to task() unchanged -- t/02.fixes.t needs that, because its first
# eleven blocks have to stay runnable against 0.15, which has no "quiet" -- and
# this file uses the same helper for the same reason of symmetry.
#
# Nothing here has to assert that the record was printed: that is asserted
# positively in blocks 11 and 14 of t/02.fixes.t, so discarding it cannot hide
# a printer that stopped printing.
#
sub quietly (&) {
	my $code = shift;
	my (undef, undef, @result) = capture { $code->() };
	return wantarray ? @result : $result[0];
}

my ($simple_task, $log_write, $stopping, $dry_run, $overwrite) = (0,0,0,0,0);

# --- a simple, successful task
# Captured rather than silenced, and then asserted on: this is the one call in
# the file that exercises the default "quiet => 0" printing path, so the record
# it prints is checked instead of being thrown away.
my ($record_out, $record_err, $r) = capture { task({
	cmd => perl_cmd('exit 0')
}) };
like($record_out, qr/will\.do/, 'the result record is printed to the terminal by default');
is($record_err, '', 'a successful task says nothing on stderr');
if (
		($r->{'die'}) &&
		($r->{done} eq 'now') &&
		(!$r->{'exit'}) &&
		($r->{overwrite} == 0) &&
		(ref $r->{'output.files'} eq 'ARRAY') &&
		(scalar @{ $r->{'output.files'} } == 0)
	) {
	$simple_task = 1;
} else {
	p $r;
	die 'test failed';
}

# --- writing to a log file + say2
my ($fh, $fname) = tempfile( UNLINK => 0, SUFFIX => '.log' );
$r = quietly { task({
	cmd            => perl_cmd('exit 0'),
	'log.fh'       => $fh,
	'output.files' => $fname,
	overwrite      => 1
}) };
# say2 says to both the terminal and the log, so the terminal half is captured
# and asserted on here rather than left to print. Its return value is the line
# it wrote, which is what the log copy is compared against below.
my ($said_out, undef, $said) = capture { say2('Testing say2', $fh) };
close $fh;
is($said_out, "$said\n", 'say2 writes its line to the terminal');
like($said, qr/Testing say2$/, 'and the line ends with the message it was given');
$log_write = 1 if ((-f $fname) && (-s $fname > 0));

# --- re-run: task must notice the output already exists
$r = quietly { task({
	cmd            => perl_cmd('exit 0'),
	'output.files' => $fname,
	overwrite      => 0
}) };
if (
		($r->{done} eq 'before')
		&&
		($r->{duration} == 0)
		&&
		($r->{'will.do'} eq 'no')
	) {
	$stopping = 1;
} else {
	p $r;
	die 'Could not stop because output files were already done';
}

# --- dry run --------------------------------------------------------------
$r = quietly { task({
	cmd       => perl_cmd('exit 0'),
	'dry.run' => 1
}) };
if (
	($r->{'dry.run'})	        &&
	($r->{duration} == 0)	  &&
	((defined $r->{'will.do'}) && ($r->{'will.do'} eq 'no: dry run'))
	) {
	$dry_run = 1;
} else {
	p $r;
	die 'dry run failed';
}

# --- task dies on a non-zero exit (default die => 1) ----------------------
dies_ok {
	quietly { task({
		cmd => perl_cmd('exit 2'), # non-zero exit, like the old "ls <missing>"
	}) };
} '"task" dies when the command exits non-zero';

# --- task dies on empty filenames ----------------------------------------
dies_ok {
	quietly { task({
		'input.files' => '',
		cmd           => perl_cmd('exit 0')
	}) };
} '"task" dies when given an empty filename in "input.files"';

dies_ok {
	quietly { task({
		'output.files' => '',
		cmd           => perl_cmd('exit 0')
	}) };
} '"task" dies when given an empty filename in "output.files"';

# --- overwrite => true actually re-runs and rewrites the file ------------
sleep 1;
my $mod0 = -M $fname;
# note(), not say(): these are for whoever is reading a failure, and TAP
# comments stay out of the way of everything else the run prints.
note("\$mod0 = $mod0");
note("\$fname = $fname");
$r = quietly { task({
	cmd            => qq{$PERL -e "print 1" > "$fname"}, # portable redirect
	overwrite      => 'true',
	'output.files' => $fname
}) };
note(sprintf '%s vs %lf', $mod0, -M $fname);
if (
		($mod0 > -M $fname) # the file has been modified (mtime newer)
		&&
		(-s $fname > 0)
	) {
	$overwrite = 1;
} else {
	p $r;
	die 'output files are not overwritten when "overwrite" is true"';
}

#
# Regression tests for bugs fixed in SimpleFlow.pm
#

# --- BUG 1: exit/signal decoding -----------------------------------------
# The old code did $exit = $status >> 8 and THEN $signal = $exit & 127, so the
# low bits of the exit code leaked into the "signal" field (e.g. exit 137 was
# reported as signal 9) and a genuine kill-by-signal could never be seen.
# task() runs commands through a shell, so a child's signal shows up as the
# shell's exit code 128+N; the portable, decisive check is that the signal
# field is NEVER contaminated by the exit code.
subtest 'exit code and signal are decoded independently (regression)' => sub {
	my %expect = (0 => 0, 2 => 2, 42 => 42, 137 => 137);
	for my $code (sort { $a <=> $b } keys %expect) {
		# die => 0 warns instead of dying, which is the documented signal to a
		# caller that did not look at will.do. Captured so the warning does not
		# read as a failure of the suite, and then asserted on: a warning that
		# stopped naming the exit code would be a defect of its own.
		my (undef, $err, $t) = capture { task({ cmd => perl_cmd("exit $code"), die => 0 }) };
		is($t->{'exit'}, $expect{$code}, "exit code $code reported correctly");
		is($t->{signal}, 0, "signal is 0 for normal exit $code (old code leaked the exit bits)");
		if ($code == 0) {
			is($err, '', 'a command that exited 0 draws no warning');
		} else {
			like($err, qr/exited $code\b/, "the warning under die => 0 names exit $code");
		}
	}
};

# A real kill-by-signal of *task's own command process* (Unix only). When the
# shell itself is signalled, $? carries signal bits; signal must be that
# number and exit must be 0.
SKIP: {
	skip 'POSIX signal semantics differ on Windows', 2 if $^O eq 'MSWin32';
	# single-quote the inner code so the outer shell does not expand $$ itself
	my $cmd = qq{$PERL -e 'kill 15 => \$\$'};
	my (undef, $err, $t) = capture { task({ cmd => $cmd, die => 0 }) };
	# Note: routed through a shell this usually surfaces as exit 128+15; the
	# point of the assertion is simply that signal is decoded from the RAW
	# status and is not just (exit & 127) of a shifted value.
	ok(defined $t->{signal}, 'signal field is defined after a signalled command');
	ok($t->{signal} == 0 || $t->{signal} == 15,
		'signal field holds a sane value (0 or the actual signal), not leaked exit bits');
	# Whichever way the shell reported the kill, task() has to say so on stderr.
	# Exactly one of these two branches is the real case on any given platform;
	# both are positive assertions, so neither can pass by not running.
	if ($t->{'exit'} != 0) {
		like($err, qr/exited $t->{'exit'}\b/,
			'the warning names the 128+signal exit the shell reported');
	}
	else {
		is($t->{signal}, 15, 'the signal itself is reported when the shell passes it on');
	}
}

# --- BUG 2: missing output file with die => 0 must not crash --------------
# The old zero-size check did ( -s $missing == 0 ), i.e. ( undef == 0 ), which
# is a fatal "uninitialized value" under 'use warnings FATAL => all' whenever a
# declared output file is absent and die => 0. It must now warn, not die.
my $missing;
{
	my $tmp = File::Temp->new(SUFFIX => '.gone'); # auto-unlinked on destroy
	$missing = $tmp->filename;
}
ok(! -e $missing, 'precondition: declared output file is absent');
my ($r2, $missing_err);
lives_ok {
	(undef, $missing_err, $r2) = capture { task({
		cmd            => perl_cmd('exit 0'),
		'output.files' => $missing,
		die            => 0,
	}) };
} 'task survives a missing output file when die => 0 (regression: undef == 0 was fatal)';
ok(defined $r2 && ref $r2 eq 'HASH', 'task still returned its result hash');
# the captured diagnostic is the other half of "did not crash": it has to have
# said which files were missing, not merely have failed to die
like($missing_err, qr/should have been made but are missing/,
	'and it reported the missing output file on stderr');

#
# Additional coverage: note, *.file.size hashes, normalisation, metadata,
# captured I/O and argument validation.
#

# --- note passthrough + default -----------------------------------------
subtest 'note field' => sub {
	my $t = quietly { task({ cmd => perl_cmd('exit 0'), note => 'hello note' }) };
	is($t->{note}, 'hello note', 'note is passed through to the result');
	my $d = quietly { task({ cmd => perl_cmd('exit 0') }) };
	is($d->{note}, '', 'note defaults to the empty string');
};

# --- output.files: scalar normalisation + output.file.size ---------------
subtest 'output.files normalisation and output.file.size' => sub {
	my (undef, $o1) = tempfile(UNLINK => 0, SUFFIX => '.dat');
	my $t = quietly { task({
		cmd            => qq{$PERL -e "print 12345" > "$o1"}, # writes exactly 5 bytes
		'output.files' => $o1,                                # scalar form
		overwrite      => 'true',
	}) };
	is(ref $t->{'output.files'}, 'ARRAY', 'scalar output.files is normalised to an arrayref');
	is_deeply($t->{'output.files'}, [$o1], 'output.files arrayref holds the filename');
	is($t->{'output.file.size'}{$o1}, 5,      'output.file.size reports the byte count');
	is($t->{'output.file.size'}{$o1}, -s $o1, 'output.file.size matches -s on disk');
	unlink $o1;
};

# --- output.file: single-file convenience form ---------------------------
subtest 'output.file (single file)' => sub {
	my (undef, $o1) = tempfile(UNLINK => 0, SUFFIX => '.dat');
	my $t = quietly { task({
		cmd           => qq{$PERL -e "print 12345" > "$o1"}, # writes exactly 5 bytes
		'output.file' => $o1,
		overwrite     => 'true',
	}) };
	is(ref $t->{'output.files'}, 'ARRAY', 'output.file is folded into the output.files arrayref');
	is_deeply($t->{'output.files'}, [$o1], 'output.files arrayref holds the single filename');
	is($t->{'output.file.size'}{$o1}, 5,      'output.file.size reports the byte count');
	is($t->{'output.file.size'}{$o1}, -s $o1, 'output.file.size matches -s on disk');

	# it must drive the "already done" skip logic just like output.files does
	my $again = quietly { task({
		cmd           => qq{$PERL -e "print 12345" > "$o1"},
		'output.file' => $o1,
		overwrite     => 0,
	}) };
	is($again->{done}, 'before', 'output.file that already exists is detected as done before');

	unlink $o1;
};

# --- output.file / output.files are mutually exclusive and single-valued --
subtest 'output.file validation' => sub {
	dies_ok {
		quietly { task({
			cmd            => perl_cmd('exit 0'),
			'output.file'  => 'a.dat',
			'output.files' => 'b.dat',
		}) }
	} 'dies when both output.file and output.files are given';

	dies_ok {
		quietly { task({
			cmd           => perl_cmd('exit 0'),
			'output.file' => ['a.dat', 'b.dat'], # a list is not allowed here
		}) }
	} 'dies when output.file is given a reference instead of a single filename';

	throws_ok {
		quietly { task({
			cmd           => perl_cmd('exit 0'),
			'output.file' => '', # 0-length filename
			die           => 0,
		}) }
	} qr/0-length filenames/, 'dies on a 0-length output.file';
};

# --- input.files: scalar + array forms, and input.file.size --------------
subtest 'input.files and input.file.size' => sub {
	my ($fh1, $i1) = tempfile(UNLINK => 0); print {$fh1} 'abc';  close $fh1; # 3 bytes
	my ($fh2, $i2) = tempfile(UNLINK => 0); print {$fh2} 'wxyz'; close $fh2; # 4 bytes

	my $scalar = quietly { task({ cmd => perl_cmd('exit 0'), 'input.files' => $i1 }) };
	is($scalar->{'input.file.size'}{$i1}, 3,   'input.file.size (scalar form) reports size');
	# 0.16: input.files is normalised to an array ref on the result, exactly as
	# output.files always was. Before 0.16 a scalar argument was stored raw.
	is_deeply($scalar->{'input.files'}, [$i1], 'scalar input.files is normalised to an arrayref');

	my $array = quietly { task({ cmd => perl_cmd('exit 0'), 'input.files' => [$i1, $i2] }) };
	is($array->{'input.file.size'}{$i1}, 3, 'input.file.size (array form) reports first size');
	is($array->{'input.file.size'}{$i2}, 4, 'input.file.size (array form) reports second size');

	unlink $i1, $i2;
};

# --- metadata fields: dir, source.file, source.line ----------------------
subtest 'task metadata' => sub {
	my $t = quietly { task({ cmd => perl_cmd('exit 0') }) };
	is($t->{dir}, getcwd(),               'dir records the working directory');
	like($t->{'source.file'}, qr/01\.t$/, 'source.file points at the calling script');
	like($t->{'source.line'}, qr/^\d+$/,  'source.line is a line number');
};

# --- captured stdout / stderr (and trailing-whitespace stripping) --------
subtest 'captured output' => sub {
	my $out = quietly { task({ cmd => perl_cmd('print q{coverage}'),    die => 0 }) };
	is($out->{stdout}, 'coverage', 'stdout is captured into the result');
	my $err = quietly { task({ cmd => perl_cmd('print STDERR q{oops}'), die => 0 }) };
	is($err->{stderr}, 'oops',     'stderr is captured into the result');
};

# --- argument validation -------------------------------------------------
subtest 'argument validation' => sub {
	dies_ok { quietly { task({ note => 'no cmd here' }) } }
		'dies when the required "cmd" key is missing';
	dies_ok { quietly { task({ cmd => perl_cmd('exit 0'), bogus_key => 1 }) } }
		'dies on an unrecognised argument key';
	dies_ok { quietly { task({ cmd => perl_cmd('exit 0'), 'log.fh' => 'not a filehandle' }) } }
		'dies when log.fh is not a real filehandle';
	dies_ok { quietly { task({ cmd => perl_cmd('exit 0'), 'input.files' => 'this_file_should_not_exist_42' }) } }
		'dies when a declared input file is missing';
};

# --- summary of the original behavioural tests ---------------------------
ok($simple_task, 'Verified: Simple task works');
ok($log_write,   'Verified: Can write to log files with subroutine "say2"');
ok($stopping,    'Verified: tasks do not run when output files exist');
ok($dry_run,     'Verified: dry run works');
ok($overwrite,   'Verified: "overwrite" option overwrites files in "output.files"');

unlink $fname if -f $fname;
done_testing();
