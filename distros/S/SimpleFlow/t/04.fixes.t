#!/usr/bin/env perl

#
# Regression tests for the defects fixed in 0.19. Each block names the
# behaviour that was wrong before, so that a re-break is recognisable from the
# failure message alone.
#
# Blocks 1-15 and 17 were each confirmed to FAIL against 0.182 (the working copy as
# committed in e3a705d, which was never released) before the fix went in. They use no argument 0.182 did not accept; "quiet"
# and "timeout" make them 0.16 or later.
#
# Block 16 covers the one field added with those fixes, "failed.outputs", and
# cannot run against 0.182 at all. Block 18 is for a defect introduced, and
# fixed, during 0.19's own development; its comment says what it was checked
# against.
#
# One fix has no test here: under "timeout" with stdin => 'inherit', a
# command reading a terminal is now given the terminal's foreground, where
# before it was stopped by SIGTTIN and then reported as timed out. Showing
# that needs a pseudo-terminal, and nothing in core provides one.
#
# Every command is a list run by the perl already running ($^X), not a shell
# string, so that no path here is re-parsed by a shell and none of the code
# handed to it needs a double quote (see t/03.fixes.t's header for why that
# matters on MSWin32).
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Cwd ();
use File::Spec;
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use File::Temp 'tempdir';
use POSIX ();
use Time::HiRes ();
use SimpleFlow qw(task);

my $dir = tempdir(CLEANUP => 1);

# The same copy of the module this file loaded, not whatever is installed.
(my $lib_dir = $INC{'SimpleFlow.pm'}) =~ s{[/\\]SimpleFlow\.pm$}{};

# The calling program for blocks 10 and 17: one task(), under a timeout of
# $ARGV[1] seconds (0 for none), whose command writes its pid to $ARGV[0] and
# then waits to be interrupted.
my $INTERRUPTED = <<'CODE';
use strict; use warnings FATAL => 'all'; use SimpleFlow;
task(cmd => [$^X, '-e', 'open my $f, q{>}, $ARGV[0] or die; print $f $$; close $f; sleep 30', $ARGV[0]],
	timeout => $ARGV[1], quiet => 1, die => 0);
CODE

# Start $INTERRUPTED in a child perl with the given timeout, wait for its
# command to start, send the child perl $signal, and return the child perl's
# wait status and whether its command was still alive once it had gone.
sub interrupt_probe {
	my ($signal, $timeout) = @_;
	my $pid_file = fresh_path();
	my $child = fork();
	die "fork() failed: $!" if not defined $child;
	if ($child == 0) {
		open STDOUT, '>', File::Spec->devnull;
		open STDERR, '>', File::Spec->devnull;
		# The probe needs INT and TERM to end the child perl, but this file
		# may have inherited them ignored -- a background job of a
		# non-interactive shell starts with INT and QUIT ignored -- and task()
		# rightly leaves an ignored signal ignored. A default disposition
		# survives exec. Until 0.194 it was inherited, and 0.193 failed to
		# install from a cpanm run in the background.
		$SIG{$_} = 'DEFAULT' foreach qw(HUP INT QUIT TERM);
		no warnings 'exec';
		exec($^X, "-I$lib_dir", '-e', $INTERRUPTED, $pid_file, $timeout)
			or POSIX::_exit(127); # "or": a statement after exec drew "Statement unlikely to be reached" on a 5.16.3 smoker, "no warnings" notwithstanding
	}
	# Loading perl and SimpleFlow took 29-44 ms here (5.10.1 and 5.44.0,
	# five runs); 10 s is headroom for a loaded smoker, and is only ever
	# spent if the probe never starts.
	my $cmd_pid;
	foreach (1 .. 500) {
		my $text = slurp($pid_file);
		if ($text =~ /\A([0-9]+)\z/) { $cmd_pid = $1; last }
		Time::HiRes::sleep(0.02);
	}
	kill $signal, $child;
	waitpid $child, 0;
	my $status = $?;
	my $alive = (defined $cmd_pid) && kill(0, $cmd_pid);
	kill 'KILL', $cmd_pid if $alive; # so that a failure here leaves nothing behind
	return ($cmd_pid, $status, $alive);
}

my $n = 0;
sub fresh_path { return File::Spec->catfile($dir, 'out' . ++$n . '.txt') }

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or return '(unreadable)';
	local $/;
	return scalar <$fh>;
}
sub spew {
	my ($file, $text) = @_;
	open my $fh, '>', $file or die "cannot write $file: $!";
	print {$fh} $text;
	close $fh;
	return;
}

# perl code that writes "half" to the file named in $ARGV[0], then ends as
# $end says: an exit code, a signal, or a sleep for a timeout to cut short
sub writes_half_then {
	my $end = shift;
	return q{open my $f, '>', $ARGV[0] or die; print $f 'half'; close $f; } . $end;
}

# --- 1. a command killed by a signal is FAILED ------------------------------
# A death by signal leaves the high byte of the wait status 0, so exit is 0,
# and until 0.19 the FAILED test looked only at exit, timed.out and missing
# outputs: an OOM kill (9) or a Ctrl-C (2, which system() ignores in the
# parent) came back will.do "done", with no warning, and under the default
# die => 1 the pipeline carried on to its next step. The signal reaches perl
# directly here because the command is a list, as it does for a string with
# no shell metacharacters or one the shell execs.
SKIP: {
	skip 'MSWin32 has no POSIX signals; "signal" is always 0 there', 2 if $^O eq 'MSWin32';
	subtest 'a command killed by a signal is FAILED under die => 0' => sub {
		my $t;
		my (undef, $err) = capture {
			$t = task(cmd => [$^X, '-e', 'kill 9, $$'], die => 0, quiet => 1);
		};
		# positive sentinel: the kill really happened and was decoded
		is($t->{signal},  9,        'signal is 9');
		is($t->{'exit'},  0,        'exit is 0, as a death by signal leaves it');
		is($t->{'will.do'}, 'FAILED', 'will.do is FAILED (0.182: "done")');
		like($err, qr/killed by signal 9/, 'and a warning names the signal (0.182: none)');
	};
	subtest 'a command killed by a signal dies under the default die => 1' => sub {
		my ($lived, $error);
		capture {
			# TERM set to its default first: the command inherits this
			# file's dispositions, which may have TERM ignored (see
			# interrupt_probe)
			$lived = eval { task(cmd => [$^X, '-e', q{$SIG{TERM} = q{DEFAULT}; kill 'TERM', $$}], quiet => 1); 1 };
			$error = $@;
		};
		ok(!$lived, 'task() died (0.182: returned "done")');
		like($error, qr/killed by signal 15/, 'and the message names the signal');
	};
}

# --- 2. a dry run of a chain of steps ---------------------------------------
# The inputs were checked before "dry_run" was looked at, so the second step
# of any pipeline -- whose input is the first step's output, which a dry run
# never makes -- died "the above files are missing or are not readable".
# A dry run could not get past step 1.
subtest 'a dry run does not die on an input an earlier step would make' => sub {
	my ($first, $second) = (fresh_path(), fresh_path());
	my ($t1, $t2, $error);
	my ($out) = capture {
		$t1 = task(cmd => 'make a', 'output_file' => $first, 'dry_run' => 1);
		$t2 = eval { task(cmd => 'make b from a', 'input_file' => $first,
			'output_file' => $second, 'dry_run' => 1) };
		$error = $@;
	};
	is($t1->{'will.do'}, 'no: dry run', 'step 1 is a dry run');
	ok(defined $t2, 'step 2 returned (0.182: died on its missing input)')
		or diag("died with: $error");
	is(($t2 ? $t2->{'will.do'} : 'died'), 'no: dry run', 'step 2 is a dry run too');
	like($out, qr/do not exist yet.*\Q$first\E/s,
		'and the dry run says the input does not exist yet, and names it');
	ok(!-e $first && !-e $second, 'nothing was made');
};
subtest 'a missing input still dies when it is not a dry run' => sub {
	my $missing = fresh_path();
	my ($lived, $error);
	capture {
		$lived = eval { task(cmd => [$^X, '-e', '1'], 'input_file' => $missing, quiet => 1); 1 };
		$error = $@;
	};
	ok(!$lived, 'task() died');
	like($error, qr/missing or are not readable/, 'with the missing-input message');
};

# --- 3. a failed step's output is not taken as done on the next run ---------
# An output left behind by a failed command -- partly written before a
# non-zero exit, a kill or a timeout -- was a file like any other, so the next
# run of the pipeline found it, reported done => "before", and skipped the
# step for good: the truncated file became the result. Snakemake deletes a
# failed job's outputs for the same reason; task() moves them to
# "<file>.failed" so the partial contents stay available for debugging.
subtest 'a non-zero exit moves its output aside, and the re-run runs' => sub {
	my $out = fresh_path();
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', writes_half_then('exit 3'), $out],
			'output_file' => $out, die => 0, quiet => 1);
	};
	is($t->{'will.do'}, 'FAILED', 'the first run failed');
	ok(!-e $out, 'its output is gone from the declared name (0.182: left in place)');
	is(slurp("$out.failed"), 'half', 'and is kept as <file>.failed');
	my $again;
	capture {
		$again = task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die; print $f 'full'}, $out],
			'output_file' => $out, quiet => 1);
	};
	is($again->{done}, 'now', 'the re-run ran (0.182: done => "before", skipped)');
	is(slurp($out), 'full', 'and wrote the whole output');
};
subtest 'a non-zero exit under die => 1 moves its output aside before dying' => sub {
	my $out = fresh_path();
	my $lived;
	capture {
		$lived = eval { task(cmd => [$^X, '-e', writes_half_then('exit 4'), $out],
			'output_file' => $out, quiet => 1); 1 };
	};
	ok(!$lived, 'task() died');
	ok(!-e $out, 'the output is gone from the declared name (0.182: left in place)');
	is(slurp("$out.failed"), 'half', 'and is kept as <file>.failed');
};
SKIP: {
	skip 'MSWin32 has no POSIX signals', 1 if $^O eq 'MSWin32';
	subtest 'a command killed by a signal moves its output aside' => sub {
		my $out = fresh_path();
		capture {
			task(cmd => [$^X, '-e', writes_half_then('kill 9, $$'), $out],
				'output_file' => $out, die => 0, quiet => 1);
		};
		ok(!-e $out, 'the output is gone from the declared name (0.182: left in place)');
		is(slurp("$out.failed"), 'half', 'and is kept as <file>.failed');
	};
}
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 1 if $^O eq 'MSWin32';
	subtest 'a command killed by its timeout moves its output aside' => sub {
		my $out = fresh_path();
		my $t;
		# 1 s is the shortest timeout there is, and the write before the sleep
		# took 2-3 ms here, perl start-up included (perl-5.44.0, three runs timed
		# with Time::HiRes), so the file
		# exists long before the kill; the 30 s sleep is never reached.
		capture {
			$t = task(cmd => [$^X, '-e', writes_half_then('sleep 30'), $out],
				'output_file' => $out, timeout => 1, die => 0, quiet => 1);
		};
		is($t->{'timed.out'}, 1, 'the command was killed by its timeout');
		ok(!-e $out, 'the output is gone from the declared name (0.182: left in place)');
		is(slurp("$out.failed"), 'half', 'and is kept as <file>.failed');
	};
}

# --- 4. a declared output that never appeared -------------------------------
# A step that exits 0 but makes only some of its outputs has failed too; the
# ones it did make are moved aside with the rest, so a failed step never
# leaves half a result under the names a later step reads.
subtest 'the outputs a step did make are moved aside when another is missing' => sub {
	my ($made, $never) = (fresh_path(), fresh_path());
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die; print $f 'half'}, $made],
			'output_files' => [$made, $never], die => 0, quiet => 1);
	};
	is($t->{'will.do'}, 'FAILED', 'the step failed on its missing output');
	ok(!-e $made, 'the output it made is gone from the declared name (0.182: left in place)');
	is(slurp("$made.failed"), 'half', 'and is kept as <file>.failed');
	ok(!-e "$never.failed", 'nothing is invented for the output that never appeared');
};

# --- 5. a dry run's record ---------------------------------------------------
# A dry run returned before output_file.size was set, breaking the promise
# that every field but the two input.* ones is present on every path, and it
# never wrote its record to log_fh: the log held the command line alone.
subtest 'a dry run returns the whole record, and logs it' => sub {
	my $out = fresh_path();
	my $log_file = fresh_path();
	open my $log, '>', $log_file or die "cannot write $log_file: $!";
	my $t;
	capture {
		$t = task(cmd => 'a command never run', 'output_file' => $out,
			'dry_run' => 1, 'log_fh' => $log, quiet => 1);
	};
	close $log;
	my $logged = slurp($log_file);
	like($logged, qr/a command never run/, 'the command line was logged');
	like($logged, qr/will\.do/, 'and so was the record (0.182: only the command line)');
	ok(exists $t->{'output_file.size'}, 'output_file.size is in the record (0.182: absent)');
};

# --- 6. a failed step's record is logged once --------------------------------
# Under die => 0 the missing-output branch printed the record and then fell
# through to the exit, timeout or final branch, which printed it again: two
# records for one task, the first of them without output_file.size.
subtest 'a step with a missing output writes its record to the log once' => sub {
	my $log_file = fresh_path();
	open my $log, '>', $log_file or die "cannot write $log_file: $!";
	capture {
		task(cmd => [$^X, '-e', '1'], 'output_file' => fresh_path(),
			die => 0, quiet => 1, 'log_fh' => $log);
	};
	close $log;
	my $records = () = slurp($log_file) =~ /will\.do/g;
	cmp_ok($records, '>=', 1, 'the record was logged');
	is($records, 1, 'exactly once (0.182: twice)');
};

# --- 7. a missing output is not also "0 size" --------------------------------
# The zero-size check defaulted a missing file's undef size to 0, so a file
# that was never made was reported twice: as missing, and as empty.
subtest 'a missing output is not reported as having 0 size' => sub {
	my (undef, $err) = capture {
		task(cmd => [$^X, '-e', '1'], 'output_file' => fresh_path(), die => 0, quiet => 1);
	};
	like($err, qr/should have been made but are missing/, 'the missing output was reported');
	unlike($err, qr/output files have 0 size/, 'and not as having 0 size as well (0.182: it was)');
	my $empty = fresh_path();
	my (undef, $empty_err) = capture {
		task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die}, $empty],
			'output_file' => $empty, quiet => 1);
	};
	like($empty_err, qr/output files have 0 size/, 'an output that exists and is empty still is');
};

# --- 8. error diagnostics go to STDERR ----------------------------------------
# The header lines before a die went to STDERR, but the dumps that explain it
# -- the arguments, the missing files, the unknown keys -- went to STDOUT,
# because the module's DDP is configured with output => 'STDOUT' for the
# record. A caller that redirected stdout lost the explanation into its file.
subtest 'the dumps explaining an error are on STDERR, not STDOUT' => sub {
	my $missing = fresh_path();
	my ($out, $err) = capture {
		eval { task(cmd => [$^X, '-e', '1'], 'input_file' => $missing, quiet => 1) };
	};
	like($err, qr/missing or unreadable/, 'the missing-input error was reported on stderr');
	like($err, qr/\Q$missing\E/, 'with the dump naming the file (0.182: that went to stdout)');
	unlike($out, qr/\Q$missing\E/, 'and none of it on stdout');
	my ($bad_out, $bad_err) = capture {
		eval { task(cmd => [$^X, '-e', '1'], 'no.such.key' => 1) };
	};
	like($bad_err, qr/no\.such\.key/, 'an unknown key is named on stderr (0.182: on stdout)');
	unlike($bad_out, qr/no\.such\.key/, 'and not on stdout');
};

# --- 9. Devel::Confess is confined to task() ---------------------------------
# "use Devel::Confess 'color'" installed global __DIE__ and __WARN__ handlers
# in every program that loaded SimpleFlow, so the caller's own
# die "message\n" came back with a stack trace appended, and any code
# comparing $@ with a string broke. task()'s own errors keep their traces.
subtest "loading SimpleFlow leaves the caller's die and warn alone" => sub {
	eval { die "plain message\n" };
	is($@, "plain message\n", "the caller's die is untouched (0.182: a stack trace was appended)");
	my @warned;
	local $SIG{__WARN__} = sub { push @warned, @_ };
	my $handler = $SIG{__WARN__};
	my $error;
	capture {
		task(cmd => [$^X, '-e', 'exit 2'], die => 0, quiet => 1);
		eval { task(cmd => [$^X, '-e', 'exit 2'], quiet => 1) };
		$error = $@;
	};
	like(join('', @warned), qr/exited 2/, "task()'s warning reached the caller's handler");
	like(join('', @warned), qr/called at/, 'with a stack trace, as before');
	like($error, qr/exited 2.*called at/s, "task()'s die still carries a stack trace");
	is($SIG{__WARN__}, $handler, "the caller's warn handler is back in place afterwards");
	ok(!defined $SIG{__DIE__}, 'and no die handler is left installed (0.182: Devel::Confess\'s)');
};

# --- 10. an interrupt during a timed command ---------------------------------
# Under "timeout" the command runs in its own process group, which is not the
# terminal's foreground group, so a Ctrl-C reached only perl: perl died and
# the command ran on as an orphan, writing to capture files nobody would read.
# The interrupt now takes the command's group down first, and then ends the
# calling program as it would have without task().
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 1 if $^O eq 'MSWin32';
	subtest 'an interrupt during a timed command kills the command too' => sub {
		my ($cmd_pid, $status, $alive) = interrupt_probe('INT', 60);
		ok(defined $cmd_pid, 'the timed command started and wrote its pid');
		is($status & 127, POSIX::SIGINT(), 'the calling program was ended by the interrupt');
		ok(!$alive, 'and the command did not outlive it (0.182: it ran on as an orphan)');
	};
}

# --- 11. the caller's own alarm ----------------------------------------------
# _run_with_timeout set "alarm $timeout" and then "alarm 0", which replaced
# and then cancelled any alarm the caller already had pending.
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 2 if $^O eq 'MSWin32';
	subtest "a timeout does not cancel the caller's pending alarm" => sub {
		my $fired = 0;
		local $SIG{ALRM} = sub { $fired++ };
		alarm 100;
		my $t;
		capture { $t = task(cmd => [$^X, '-e', '1'], timeout => 5, quiet => 1) };
		my $left = alarm 0;
		is($t->{'will.do'}, 'done', 'the timed command ran');
		# the command takes well under a second, so 100 s has barely begun
		cmp_ok($left, '>=', 90, "the caller's alarm is still pending (0.182: cancelled, 0 left)");
		is($fired, 0, 'and has not fired early');
	};
	subtest "a caller's alarm that fell due during the command is delivered" => sub {
		my $fired = 0;
		local $SIG{ALRM} = sub { $fired++ };
		# due 1 s into a command that sleeps 2 s: a second's margin either way
		alarm 1;
		capture { task(cmd => [$^X, '-e', 'sleep 2'], timeout => 10, quiet => 1) };
		alarm 0;
		is($fired, 1, "the caller's alarm fired once (0.182: it was lost)");
	};
}

# --- 12. "timeout" is ASCII digits and nothing else ---------------------------
# /^\d+$/ let through a trailing newline ($ matches before one) and any
# Unicode digit, which then died "isn't numeric" rather than with the
# argument error.
subtest '"timeout" refuses a trailing newline and non-ASCII digits' => sub {
	foreach my $case (["5\n", 'a trailing newline', 'accepted and ran'],
			["\x{663}", 'an Arabic-Indic three', 'died "isn\'t numeric"']) {
		my ($bad, $what, $old) = @$case;
		my ($lived, $error);
		capture {
			$lived = eval { task(cmd => [$^X, '-e', '1'], timeout => $bad, quiet => 1); 1 };
			$error = $@;
		};
		ok(!$lived, "task() died on $what");
		like($error, qr/must be a whole number of seconds/, "with the argument error (0.182: $old)");
	}
};

# --- 13. "stale" at sub-second resolution -------------------------------------
# The mtimes were compared as whole seconds, from core stat(), so an input
# rewritten in the same second as its output was not newer, and the stale
# output was kept.
subtest '"stale" sees an input newer by less than a second' => sub {
	my ($in, $out) = (fresh_path(), fresh_path());
	my ($m_out, $m_in) = (0, 0);
	foreach (1 .. 3) {
		my $now = Time::HiRes::time();
		Time::HiRes::sleep(1.1 - ($now - int $now)); # 0.1 s into the next second
		spew($out, 'old output');
		# 50 ms is more than ten times a 250 Hz kernel's timestamp granularity;
		# the precondition below checks what the filesystem actually recorded
		Time::HiRes::sleep(0.05);
		spew($in, 'newer input');
		# copied to an array first: Time::HiRes 1.9719 (perl 5.10.1, 5.12.5) gets
		# a direct slice of its stat wrong; see _mtime in the module
		($m_out, $m_in) = map { my @stat = Time::HiRes::stat($_); $stat[9] } $out, $in;
		last if (int($m_out) == int($m_in)) && ($m_in > $m_out);
	}
	SKIP: {
		skip 'this filesystem records only whole-second mtimes', 2
			unless (int($m_out) == int($m_in)) && ($m_in > $m_out);
		my $t;
		capture {
			$t = task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die; print $f 'rebuilt'}, $out],
				'input_file' => $in, 'output_file' => $out, stale => 1, quiet => 1);
		};
		is($t->{'out.of.date'}, 1, 'the output is out of date (0.182: 0, same second)');
		is(slurp($out), 'rebuilt', 'and was rebuilt (0.182: kept)');
	}
};

# --- 14. a failure's message gives every reason -------------------------------
# The branches were tried one at a time, and the missing-output one came
# first, so a step that exited non-zero, or timed out, and also left an
# output missing died saying only that the output was missing.
subtest 'the message for a failure names each thing that went wrong' => sub {
	my $error;
	capture {
		eval { task(cmd => [$^X, '-e', 'exit 3'], 'output_file' => fresh_path(), quiet => 1) };
		$error = $@;
	};
	like($error, qr/should have been made but are missing/, 'it names the missing output');
	like($error, qr/exited 3/, 'and the exit code (0.182: only the missing output)');
	SKIP: {
		skip 'timeout needs fork() and POSIX process groups', 2 if $^O eq 'MSWin32';
		capture {
			eval { task(cmd => [$^X, '-e', 'sleep 30'], 'output_file' => fresh_path(),
				timeout => 1, quiet => 1) };
			$error = $@;
		};
		like($error, qr/should have been made but are missing/, 'it names the missing output');
		like($error, qr/timeout/, 'and the timeout (0.182: only the missing output)');
	}
};

# --- 15. why a command could not be launched ---------------------------------
# system() returns -1 and sets $! when the command cannot be started; the
# record kept the -1 and threw $! away, so the caller could not tell a
# missing program from one without execute permission.
SKIP: {
	# a list that fails to spawn gives 255, not -1, on MSWin32 (t/03.fixes.t)
	skip 'MSWin32 reports a failed spawn of a list as exit 255', 1 if $^O eq 'MSWin32';
	subtest 'a command that cannot be launched says why, in stderr' => sub {
		my $enoent = do { local $! = POSIX::ENOENT(); "$!" }; # in this locale's words
		my $t;
		capture { $t = task(cmd => ["simpleflow-no-such-command-$$"], die => 0, quiet => 1) };
		is($t->{'exit'}, -1, 'the command could not be launched');
		like($t->{stderr}, qr/\Q$enoent\E/, "stderr says why (0.182: '')");
	};
}

# --- 17. a TERM or HUP to perl while a command runs, with no timeout --------
# system() shields its caller from INT and QUIT, which a terminal sends to the
# whole foreground group, the command included; it does nothing about a TERM
# or HUP sent to perl alone, by a batch scheduler, say, or "kill <pid>". Perl
# died of it and left the command running as an orphan. The command is now
# sent the same signal, waited for, and the signal passed on.
SKIP: {
	skip 'MSWin32 has no POSIX signals', 1 if $^O eq 'MSWin32';
	subtest 'a TERM to perl during an untimed command ends the command too' => sub {
		my ($cmd_pid, $status, $alive) = interrupt_probe('TERM', 0);
		ok(defined $cmd_pid, 'the command started and wrote its pid');
		is($status & 127, POSIX::SIGTERM(), 'the calling program was ended by the TERM');
		ok(!$alive, 'and the command did not outlive it (0.182 and 0.19 before the fix: it ran on)');
	};
}

# --- 18. names in the stack traces of SimpleFlow's own anonymous subs --------
# Devel::Confess's import() sets two bits of $^P that make perl name an
# anonymous sub for where it was written: SimpleFlow::__ANON__[<file>:<line>].
# When 0.19 stopped importing Devel::Confess globally, the bits went with it,
# and a trace through one of SimpleFlow's closures said only
# SimpleFlow::__ANON__. This defect was never released: it is confirmed to
# FAIL against the 0.19 working copy before the fix, and needs "dir", which
# 0.182 does not have.
SKIP: {
	skip 'needs rmdir of the working directory, which MSWin32 refuses', 1 if $^O eq 'MSWin32';
	subtest "a trace through one of SimpleFlow's closures names where it is" => sub {
		# The closure that goes back to the caller's directory after "dir" warns
		# when it cannot, and it cannot once that directory has been removed.
		my $gone = File::Spec->catdir($dir, 'gone' . ++$n);
		my $work = File::Spec->catdir($dir, 'work' . ++$n);
		mkdir $_ or die "cannot make $_: $!" foreach $gone, $work;
		my $back = Cwd::getcwd();
		chdir $gone or die "cannot enter $gone: $!";
		my @warned;
		{
			local $SIG{__WARN__} = sub { push @warned, @_ };
			capture {
				task(cmd => [$^X, '-e', q{rmdir $ARGV[0] or die}, $gone], dir => $work, quiet => 1);
			};
		}
		chdir $back or die "cannot go back to $back: $!";
		my $trace = join '', @warned;
		like($trace, qr/cannot go back to/, "the closure's warning was raised");
		like($trace, qr/SimpleFlow::__ANON__\[[^\]]*SimpleFlow\.pm:\d+\]/,
			'and the trace names the closure by file and line (0.19 before the fix: SimpleFlow::__ANON__ alone)');
	};
}

# --- 16. "failed.outputs", new in 0.19 --------------------------------------
# Not a regression test: 0.182 has no such field.
subtest '"failed.outputs" lists where a failed step\'s outputs went' => sub {
	my $out = fresh_path();
	spew("$out.failed", 'stale leftover'); # a .failed from an earlier failure is replaced
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', writes_half_then('exit 5'), $out],
			'output_file' => $out, die => 0, quiet => 1);
	};
	is_deeply($t->{'failed.outputs'}, ["$out.failed"], 'the new name is recorded');
	is(slurp("$out.failed"), 'half', 'and replaced the leftover from before');
	is($t->{'output_file.size'}{$out}, 4, 'output_file.size is what the command wrote, before the move');
};
subtest '"failed.outputs" is an empty list on every other path' => sub {
	my $out = fresh_path();
	my %t;
	capture {
		$t{'a success'} = task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die; print $f 'ok'}, $out],
			'output_file' => $out, quiet => 1);
		$t{'a skip'}    = task(cmd => [$^X, '-e', '1'], 'output_file' => $out, quiet => 1);
		$t{'a dry run'} = task(cmd => [$^X, '-e', '1'], 'dry_run' => 1, quiet => 1);
	};
	# positive sentinel: each path was the one intended
	is($t{'a success'}{done}, 'now',    'the success ran');
	is($t{'a skip'}{done},    'before', 'the skip skipped');
	is($t{'a dry run'}{'will.do'}, 'no: dry run', 'the dry run was one');
	is_deeply($t{$_}{'failed.outputs'}, [], "\"failed.outputs\" is [] after $_") foreach sort keys %t;
	is(slurp($out), 'ok', 'and a successful output is left where it is');
};

done_testing();
