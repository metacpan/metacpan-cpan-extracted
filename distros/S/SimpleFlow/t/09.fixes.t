#!/usr/bin/env perl

#
# Regression tests for the defects fixed in 0.192. Each block names the
# behaviour that was wrong before, so that a re-break is recognisable from the
# failure message alone.
#
# The defects were reported in an independent review of 0.191 (Joshua S. Day,
# "Astra-Review.md", commit 5e9b03d of github.com/haxmeister/SimpleFlow,
# 2026-10-02), as F01-F10, P01-P04 and S01-S04, with the report titles of
# its closing notes; the block comments give each one's number. Blocks 1-25
# were each confirmed to FAIL against 0.191 (the release, as committed in
# 4ec5053) before the fix went in, on perl 5.44.0 and 5.10.1, with two
# exceptions that their comments explain: block 4 is a race, and block 11
# fails on 5.44.0 only. They use no argument 0.191 did not accept. Blocks
# 26-29 test "env.secret", the option added for S03, and cannot run against
# 0.191 at all.
#
# Each block works in a directory of its own, given to task() as "dir", so
# that the names it declares are short and nothing is left behind.
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use Cwd ();
use Digest::MD5 'md5_hex';
use POSIX ();
use Pod::Text ();
use Time::HiRes ();
use SimpleFlow qw(task parallel report);

sub fresh_dir { return File::Temp::tempdir(CLEANUP => 1) }
sub spew {
	my ($path, $text) = @_;
	open my $fh, '>', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot close $path: $!";
	return;
}
sub slurp {
	my $path = shift;
	open my $fh, '<', $path or return undef; # undef = no such file
	local $/;
	my $text = <$fh>;
	close $fh;
	return $text;
}

# 1. F01. Two copies of one name in "output.files": the first was moved to
# out.failed, and the second pass then deleted that .failed as "left from
# before" and found nothing to move. Both names were gone, and failed.outputs
# still listed out.failed.
subtest 'a name declared twice keeps its partial output in .failed (0.191 deleted it)' => sub {
	my $d = fresh_dir();
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', q{open my $f, q{>}, q{out} or die; print {$f} q{partial}; close $f; exit 1}],
			'output.files' => ['out', 'out'], dir => $d, die => 0, quiet => 1);
	};
	is($t->{'will.do'}, 'FAILED', 'the step failed, as it should');
	is(slurp(File::Spec->catfile($d, 'out.failed')), 'partial', 'out.failed holds what the command wrote (0.191: it was deleted)');
	is_deeply($t->{'failed.outputs'}, ['out.failed'], 'failed.outputs names it once');
};

# 2. F01. An output named like another's .failed: moving "out" aside first
# deleted the declared "out.failed" to make room, and its contents were lost.
subtest 'an output named <other>.failed is not destroyed by moving the other aside (0.191 deleted it)' => sub {
	my $d = fresh_dir();
	spew(File::Spec->catfile($d, 'out'), 'first');
	spew(File::Spec->catfile($d, 'out.failed'), 'second');
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', 'exit 1'], 'output.files' => ['out', 'out.failed'],
			overwrite => 1, dir => $d, die => 0, quiet => 1);
	};
	my @contents = sort grep { defined } map { slurp(File::Spec->catfile($d, $_)) } qw(out out.failed out.failed.failed);
	is_deeply(\@contents, ['first', 'second'], 'both outputs survive (0.191: "second" was deleted)');
	is(scalar(grep { not -e File::Spec->catfile($d, $_) } @{ $t->{'failed.outputs'} }), 0, 'every name in failed.outputs exists');
	is(scalar @{ $t->{'failed.outputs'} }, 2, 'and both moves are listed');
};

# 3. F01. A file output inside a directory output: the file was renamed to
# out/item.failed, then the directory to out.failed, so the name reported for
# the file did not exist.
subtest 'a file inside a directory output moves with the directory (0.191 reported a path that did not exist)' => sub {
	my $d = fresh_dir();
	mkdir File::Spec->catdir($d, 'out') or die $!;
	spew(File::Spec->catfile($d, 'out', 'item'), 'contents');
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', 'exit 1'], 'output.file' => File::Spec->catfile('out', 'item'),
			'output.dir' => 'out', overwrite => 1, dir => $d, die => 0, quiet => 1);
	};
	cmp_ok(scalar @{ $t->{'failed.outputs'} }, '>', 0, 'something was moved aside');
	my @absent = grep { not -e File::Spec->catfile($d, $_) } @{ $t->{'failed.outputs'} };
	is_deeply(\@absent, [], 'every name in failed.outputs exists (0.191: out/item.failed did not)');
	is(slurp(File::Spec->catfile($d, 'out.failed', 'item')), 'contents', 'the file is in the moved directory, under its own name');
};

# 4. F02. parallel()'s workers wrote their trace lines through one inherited
# filehandle with nothing to keep them apart, and a long line was split into
# several write()s that interleaved with another worker's: the trace was no
# longer JSON lines, and report() refused it. The notes are ~100 KB so that
# each line takes several writes. This is a race, so 0.191 could pass it: run
# against 0.191 on perl 5.44.0 it found 5, 2 and 4 broken lines in three runs,
# and on 5.10.1 3 and 6 in two.
SKIP: {
	skip 'parallel() with jobs above 1 needs a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'parallel workers write whole trace lines (0.191 interleaved them)' => sub {
		my $d = fresh_dir();
		my $trace_file = File::Spec->catfile($d, 'trace.jsonl');
		open my $trace, '>', $trace_file or die $!;
		my @records;
		capture {
			@records = parallel(jobs => 8, tasks => [map { {
				cmd => [$^X, '-e', 'select undef, undef, undef, 0.2'], quiet => 1, dir => $d,
				note => ("worker$_-" x 12000), 'trace.fh' => $trace,
			} } 1 .. 16]);
		};
		close $trace;
		is(scalar @records, 16, 'every task returned a record');
		open my $in, '<', $trace_file or die $!;
		my @lines = <$in>;
		close $in;
		is(scalar @lines, 16, 'one line per task');
		# A whole line starts with '{"', ends with "}", and holds one note,
		# whole: twelve thousand copies of the same "workerN-". JSON::PP would
		# say more, but is core only from perl 5.14.
		my @broken = grep {
			my $line = $lines[$_];
			not (($line =~ /\A\{"/) && ($line =~ /\}\n\z/) && ($line =~ /"note":"(worker([0-9]+)-)\1{11999}"/))
		} 0 .. $#lines;
		is_deeply(\@broken, [], 'no line holds parts of two records');
	};
}

# 5. F03. A run without "stale.cmd" that replaced the outputs left the
# signature of the command before it on record, so a later stale.cmd run of
# that earlier command took the other command's output as its own.
subtest 'a run without stale.cmd updates the command on record (0.191 left the old one, and skipped)' => sub {
	my $d = fresh_dir();
	my $code = q{open my $f, q{>}, q{out} or die; print {$f} $ARGV[0]};
	my @common = ('output.file' => 'out', dir => $d, quiet => 1);
	my $t;
	capture {
		task(@common, cmd => [$^X, '-e', $code, 'A'], 'stale.cmd' => 1);
		task(@common, cmd => [$^X, '-e', $code, 'B'], overwrite => 1);
		$t = task(@common, cmd => [$^X, '-e', $code, 'A'], 'stale.cmd' => 1);
	};
	is(slurp(File::Spec->catfile($d, 'out')), 'A', 'the output is A\'s (0.191: B\'s)');
	is($t->{done}, 'now', 'A was run again (0.191: done before)');
	is($t->{'cmd.changed'}, 1, 'cmd.changed says why');
};

# 6. F04. The signature hashed the wrapped command space-joined, so a wrapper
# given one word "a b" and one given "a" and "b" looked the same to stale.cmd.
subtest 'stale.cmd tells apart wrapper words that join to the same string (0.191 did not)' => sub {
	my $d = fresh_dir();
	my $code = q{open my $f, q{>}, q{out} or die; print {$f} join q{|}, @ARGV};
	my @common = (cmd => ['tail'], 'output.file' => 'out', 'stale.cmd' => 1, dir => $d, quiet => 1);
	my $t;
	capture {
		task(@common, wrapper => [$^X, '-e', $code, 'a b']);
		$t = task(@common, wrapper => [$^X, '-e', $code, 'a', 'b']);
	};
	is(slurp(File::Spec->catfile($d, 'out')), 'a|b|tail', 'the second wrapper ran (0.191: "a b|tail" was kept)');
	is($t->{'cmd.changed'}, 1, 'cmd.changed is 1 (0.191: 0)');
};

# 7. F05. "threads" reaches the command as SIMPLEFLOW_THREADS, but was not in
# the signature, so changing it did not re-run a stale.cmd step.
subtest 'stale.cmd re-runs a step whose threads changed (0.191 did not)' => sub {
	my $d = fresh_dir();
	my $cmd = [$^X, '-e', q{open my $f, q{>}, q{out} or die; print {$f} $ENV{SIMPLEFLOW_THREADS}}];
	my $t;
	capture {
		task(cmd => $cmd, threads => 1, 'output.file' => 'out', 'stale.cmd' => 1, dir => $d, quiet => 1);
		$t = task(cmd => $cmd, threads => 2, 'output.file' => 'out', 'stale.cmd' => 1, dir => $d, quiet => 1);
	};
	is(slurp(File::Spec->catfile($d, 'out')), '2', 'the command saw threads => 2 (0.191: kept the output of 1)');
	is($t->{'cmd.changed'}, 1, 'cmd.changed is 1');
};

# 8. F06. With "lock", the output's name went to md5_hex as it was, and a
# character string with a character above 255 died "Wide character in
# subroutine entry".
subtest 'lock accepts an output name with a wide character (0.191 died)' => sub {
	my $d = fresh_dir();
	my $name = "result-\x{3bb}.txt";
	spew(File::Spec->catfile($d, $name), 'data');
	my $t;
	capture {
		$t = eval { task(cmd => [$^X, '-e', 'exit 0'], 'output.file' => $name, lock => 1, dir => $d, quiet => 1) };
	};
	is($@, '', 'task() did not die (0.191: Wide character in subroutine entry)');
	is($t->{done}, 'before', 'the existing output was found');
};

# 9. F07. With "stdout.file" also declared as an output, a failed attempt
# moved the file aside, so the retry began a new one: the documented "every
# attempt, in order" held only the last.
subtest 'stdout.file keeps every attempt even when it is also an output (0.191 kept only the last)' => sub {
	my $d = fresh_dir();
	my $code = q{my $again = -e q{attempt}; open my $f, q{>}, q{attempt} or die; close $f; print $again ? qq{second\n} : qq{first\n}; exit($again ? 0 : 1)};
	my $t;
	capture {
		$t = task(cmd => [$^X, '-e', $code], 'stdout.file' => 'out', 'output.file' => 'out',
			retries => 1, dir => $d, quiet => 1);
	};
	is($t->{attempts}, 2, 'it took two attempts');
	is(slurp(File::Spec->catfile($d, 'out')), "first\nsecond\n", 'both are in the file (0.191: only "second")');
	ok(not(-e File::Spec->catfile($d, 'out.failed')), 'nothing was moved aside');
};

# 10. F08. With "stderr.file" also declared as an output, the failed step's
# file was moved aside before the message was built, and the message's
# "stderr ended with" was quietly left out. The line is built at run time so
# that it cannot reach the message through the command itself.
subtest 'the failure message quotes stderr.file even when it was moved aside (0.191 left it out)' => sub {
	my $d = fresh_dir();
	my $error;
	capture {
		eval { task(cmd => [$^X, '-e', q{print STDERR join(q{-}, qw(fixture diagnostic)), qq{\n}; exit 7}],
			'stderr.file' => 'err', 'output.file' => 'err', dir => $d, quiet => 1) };
		$error = $@;
	};
	like($error, qr/exited 7/, 'task() died for the exit');
	is(slurp(File::Spec->catfile($d, 'err.failed')), "fixture-diagnostic\n", 'the file was moved aside');
	like($error, qr/stderr ended with:\n\tfixture-diagnostic\n/, 'and the message quotes it (0.191: it did not)');
};

# 11. F09. STDIN on an in-memory scalar has fileno -1, which is defined, so it
# was saved with "<&" and could not be reopened: task() died "cannot restore
# STDIN", after the command had succeeded, and the caller lost its input.
# That is perl 5.44.0's "<&" of such a handle; on 5.10.1 0.191 restored it, so
# this block passes there with either release. It is not run under capture {},
# since 5.44.0 restored the scalar there too, and with "quiet" and a command
# that succeeds silently there is nothing to capture.
subtest 'a caller whose STDIN is an in-memory scalar keeps it (0.191 died restoring it)' => sub {
	open my $real_stdin, '<&', \*STDIN or die "cannot save STDIN: $!";
	my $input = "first\nsecond\n";
	close STDIN;
	open STDIN, '<', \$input or die $!;
	my $t = eval { task(cmd => [$^X, '-e', 'exit 0'], quiet => 1) };
	my $error = $@;
	my $line = <STDIN>;
	close STDIN;
	open STDIN, '<&', $real_stdin or die "cannot restore the test's STDIN: $!";
	is($error, '', 'task() returned (0.191: cannot restore STDIN)');
	is($t->{'will.do'}, 'done', 'the step succeeded');
	is($line, "first\n", 'the caller can still read its input');
};

# 12. F10. The tables of arguments and of the record's fields were
# "=begin html" only, which pod2text, perldoc and man pages drop: those
# readers saw the prose round them and neither table.
subtest 'the argument and field tables reach a text rendering of the POD (0.191 had them in HTML only)' => sub {
	my $text = '';
	my $parser = Pod::Text->new;
	$parser->output_string(\$text);
	$parser->parse_file($INC{'SimpleFlow.pm'});
	like($text, qr/^ *Arguments$/m, 'the POD was rendered'); # the sentinel
	like($text, qr/Convenience form of/, 'the arguments table is in it (0.191: no)');
	like($text, qr/Wall-clock seconds the command took/, 'the record table is in it (0.191: no)');
};

# 13. P01. The pipe that reports a failed exec relied on perl's default
# close-on-exec, which only holds above $^F. A caller with $^F raised gave
# the command the pipe's write end, so _run_forked waited for the command to
# end before it set the alarm, and the timeout never fired. The command sleeps
# 5 s, against a timeout of 1 s.
SKIP: {
	skip '"timeout" needs POSIX process groups', 1 if $^O eq 'MSWin32';
	subtest 'the timeout fires when the caller has raised $^F (0.191 waited the command out)' => sub {
		local $^F = 100; # past every descriptor this test opens
		my $t;
		capture {
			$t = task(cmd => [$^X, '-e', 'sleep 5'], timeout => 1, die => 0, quiet => 1);
		};
		is($t->{'timed.out'}, 1, 'the command timed out (0.191: 0, it ran its 5 s)');
		cmp_ok($t->{duration}, '<', 4, 'and was killed long before it finished');
	};
}

# 14. P02. parallel() took a worker as finished only when waitpid returned
# its pid. A caller whose SIGCHLD is ignored has its children reaped by the
# kernel, waitpid returns -1, and 0.191 polled for ever. The alarm turns that
# hang into a failure: parallel() returned in 0.022-0.024 s in five runs here
# (perl 5.44.0), so 20 s is some eight hundred times what it needs.
SKIP: {
	skip 'parallel() with jobs above 1 needs a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'parallel() returns when SIGCHLD is ignored (0.191 waited for ever)' => sub {
		my @records;
		my $error;
		{
			local $SIG{CHLD} = 'IGNORE';
			local $SIG{ALRM} = sub { die "parallel() hung\n" };
			alarm 20;
			capture {
				@records = eval { parallel(jobs => 2, tasks => [map { { cmd => [$^X, '-e', 'exit 0'], die => 0, quiet => 1 } } 1, 2]) };
				$error = $@;
			};
			alarm 0;
		}
		is($error, '', 'parallel() returned (0.191: it hung)');
		is(scalar(grep { defined } @records), 2, 'with a record for each task');
	};
}

# 15. P04. Without a timeout, a TERM sent to task()'s process was passed to
# the command's first process alone, and anything it had started ran on.
# Here the command ignores TERM, as a shell running a pipeline may, and waits
# for a child of its own that does not; it exits with the signal that child
# died of, or 99 if the child finished its 5 s sleep, as under 0.191. The
# pipe makes sure the child is no longer ignoring TERM when it is sent.
SKIP: {
	skip 'needs POSIX signals and process groups', 1 if $^O eq 'MSWin32';
	subtest 'an untimed TERM reaches everything the command started (0.191 reached its first process only)' => sub {
		my $code = q{$SIG{TERM} = q{IGNORE}; pipe my $r, my $w or die; my $k = fork; }
			. q{if (!$k) { $SIG{TERM} = q{DEFAULT}; close $r; syswrite $w, 1; sleep 5; exit 0 } }
			. q{close $w; sysread $r, my $b, 1; kill q{TERM}, getppid; waitpid $k, 0; exit(($? & 127) || 99)};
		my $caught = 0;
		local $SIG{TERM} = sub { $caught++ };
		my $t;
		capture { $t = task(cmd => [$^X, '-e', $code], die => 0, quiet => 1) };
		is($caught, 1, 'the TERM was passed on to the caller afterwards, once');
		is($t->{'exit'}, POSIX::SIGTERM(), "the command's child died of it (0.191: it slept on, and exit was 99)");
	};
}

# 16. P04. Without a timeout, perl ignored INT while the command ran, as
# system() does, and counted on the terminal to send it to the command too.
# One sent to perl alone, by kill, was lost. The command sends it to perl and
# sleeps 5 s, which 0.191 waited out.
SKIP: {
	skip 'needs POSIX signals and process groups', 1 if $^O eq 'MSWin32';
	subtest 'an untimed INT sent to perl alone reaches the command (0.191 dropped it)' => sub {
		my $caught = 0;
		local $SIG{INT} = sub { $caught++ };
		my $t;
		capture { $t = task(cmd => [$^X, '-e', q{kill q{INT}, getppid; sleep 5}], die => 0, quiet => 1) };
		is($t->{signal}, POSIX::SIGINT(), 'the command died of it (0.191: it slept 5 s and exited 0)');
		is($caught, 0, 'and, as under system(), perl was not sent it again');
	};
}

# 17. P04. A die from one of the caller's own signal handlers, while an
# untimed command ran, unwound out of task() and left the command running,
# never waited for. The command writes its pid, then sends the signal; the
# 0.5 s before it does is margin for the parent to reach its wait, which it
# does as soon as the exec succeeds, while the command's perl is still
# starting (29-44 ms here; see t/04.fixes.t).
SKIP: {
	skip 'needs POSIX signals and process groups', 1 if $^O eq 'MSWin32';
	subtest "a die from the caller's own handler ends the command too (0.191 left it running)" => sub {
		my $d = fresh_dir();
		my $pid_file = File::Spec->catfile($d, 'pid');
		local $SIG{USR1} = sub { die "the caller's own handler\n" };
		my $code = q{open my $o, q{>}, $ARGV[0] or die; print {$o} $$; close $o; }
			. q{select undef, undef, undef, 0.5; kill q{USR1}, getppid; sleep 30};
		my $error;
		capture {
			eval { task(cmd => [$^X, '-e', $code, $pid_file], quiet => 1) };
			$error = $@;
		};
		like($error, qr/the caller's own handler/, "the caller's exception came through");
		my $cmd_pid = slurp($pid_file);
		like($cmd_pid, qr/\A[0-9]+\z/, 'the command ran'); # the sentinel
		my $alive = kill 0, $cmd_pid;
		ok(!$alive, 'and is gone, waited for (0.191: still running)');
		kill 'KILL', $cmd_pid if $alive;
	};
}

# Symbolic links, for blocks 18-20; not every system can make one.
sub make_symlink {
	my ($target, $link) = @_;
	return eval { symlink($target, $link) } ? 1 : 0;
}

# 18. S01. ".simpleflow" was used through a symbolic link, so whoever could
# write to the working directory chose where the lock files went.
SKIP: {
	my $d = fresh_dir();
	mkdir File::Spec->catdir($d, 'elsewhere') or die $!;
	skip 'cannot make a symbolic link here', 1
		if not make_symlink('elsewhere', File::Spec->catfile($d, '.simpleflow'));
	subtest 'lock refuses a .simpleflow that is a symbolic link (0.191 followed it)' => sub {
		my $error;
		capture {
			eval { task(cmd => [$^X, '-e', 'exit 0'], 'output.file' => 'out', lock => 1, dir => $d, quiet => 1) };
			$error = $@;
		};
		like($error, qr/is a symbolic link/, 'task() refused it (0.191: no)');
		opendir my $dh, File::Spec->catdir($d, 'elsewhere') or die $!;
		my @made = grep { !/\A\.\.?\z/ } readdir $dh;
		is_deeply(\@made, [], 'and made nothing where it pointed');
	};
}

# 19. S01. The same for the command records of "stale.cmd", in ".simpleflow/cmd".
SKIP: {
	my $d = fresh_dir();
	mkdir File::Spec->catdir($d, $_) or die $! foreach 'elsewhere', '.simpleflow';
	skip 'cannot make a symbolic link here', 1
		if not make_symlink(File::Spec->catdir(File::Spec->updir, 'elsewhere'), File::Spec->catfile($d, '.simpleflow', 'cmd'));
	subtest 'stale.cmd refuses a .simpleflow/cmd that is a symbolic link (0.191 followed it)' => sub {
		my $error;
		capture {
			eval { task(cmd => [$^X, '-e', q{open my $f, q{>}, q{out} or die}], 'output.file' => 'out',
				'stale.cmd' => 1, dir => $d, quiet => 1) };
			$error = $@;
		};
		like($error, qr/is a symbolic link/, 'task() refused it (0.191: no)');
		opendir my $dh, File::Spec->catdir($d, 'elsewhere') or die $!;
		my @made = grep { !/\A\.\.?\z/ } readdir $dh;
		is_deeply(\@made, [], 'and made nothing where it pointed');
	};
}

# 20. S01. A command record was written first to "<record>.<pid>", opened with
# truncation, so a symbolic link planted under that predictable name had its
# target overwritten. The record's name is _signature_file's, worked out here:
# the MD5 of the outputs' absolute paths. task() runs in this process, so the
# pid is this one.
SKIP: {
	my $d = fresh_dir();
	my $real = Cwd::realpath($d);
	mkdir File::Spec->catdir($d, '.simpleflow') or die $!;
	mkdir File::Spec->catdir($d, '.simpleflow', 'cmd') or die $!;
	my $victim = File::Spec->catfile($d, 'victim');
	spew($victim, 'precious');
	my $record = File::Spec->catfile($d, '.simpleflow', 'cmd', md5_hex(File::Spec->catfile($real, 'out')));
	skip 'cannot make a symbolic link here', 1 if not make_symlink($victim, "$record.$$");
	subtest 'a link at the old temporary name of a command record is not followed (0.191 overwrote its target)' => sub {
		capture {
			task(cmd => [$^X, '-e', q{open my $f, q{>}, q{out} or die}], 'output.file' => 'out',
				'stale.cmd' => 1, dir => $d, quiet => 1);
		};
		ok(-e $record, 'the record was written'); # the sentinel
		is(slurp($victim), 'precious', 'and the link\'s target is untouched (0.191: it held the record)');
	};
}

# Run a task in a child process that holds its lock for a while, wait until
# its command has started, and return the child's pid. Its command writes
# "started", sleeps 1 s, and makes the output; 1 s is ample for the test to
# reach its own task(), which takes milliseconds.
sub hold_lock {
	my ($d, @args) = @_;
	my $pid = fork();
	die "fork() failed: $!" if not defined $pid;
	if ($pid == 0) {
		open STDOUT, '>', File::Spec->devnull;
		open STDERR, '>', File::Spec->devnull;
		eval { task(@args, lock => 1, dir => $d, quiet => 1) };
		POSIX::_exit(0);
	}
	# perl and SimpleFlow start in 29-44 ms here; 10 s is headroom for a
	# loaded smoker, and is only ever spent if the child never starts
	foreach (1 .. 500) {
		last if -e File::Spec->catfile($d, 'started');
		Time::HiRes::sleep(0.02);
	}
	return $pid;
}
my $STARTED_THEN = q{open my $s, q{>}, q{started} or die; close $s; select undef, undef, undef, 1; };

# 21. S02. Locks were named for the path as written, so two names for one
# output -- "out" and "sub/../out" -- took two locks, and a second run of
# the step did not wait for the first.
SKIP: {
	skip 'needs a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'two names for one output share its lock (0.191 took two)' => sub {
		my $d = fresh_dir();
		mkdir File::Spec->catdir($d, 'sub') or die $!;
		my $child = hold_lock($d, cmd => [$^X, '-e', $STARTED_THEN . q{open my $f, q{>}, q{out} or die; print {$f} q{first}}],
			'output.file' => 'out');
		ok(-e File::Spec->catfile($d, 'started'), 'the first run started'); # the sentinel
		my $t;
		my (undef, $err) = capture {
			$t = task(cmd => [$^X, '-e', q{open my $f, q{>}, q{out} or die; print {$f} q{second}}],
				'output.file' => File::Spec->catfile('sub', File::Spec->updir, 'out'), lock => 1, dir => $d, quiet => 1);
		};
		waitpid $child, 0;
		like($err, qr/waiting for another run/, 'the second run waited (0.191: no)');
		is($t->{done}, 'before', 'and found the output made');
		is(slurp(File::Spec->catfile($d, 'out')), 'first', 'which the first run made');
	};
}

# 22. S02. A step whose output is a directory did not exclude one whose output
# is a file inside it.
SKIP: {
	skip 'needs a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'a file output waits for a run that holds its directory (0.191 did not)' => sub {
		my $d = fresh_dir();
		my $child = hold_lock($d, cmd => [$^X, '-e', q{mkdir q{res}; } . $STARTED_THEN
			. q{open my $f, q{>}, q{res/f} or die; print {$f} q{first}}], 'output.dir' => 'res');
		ok(-e File::Spec->catfile($d, 'started'), 'the first run started'); # the sentinel
		my $t;
		my (undef, $err) = capture {
			$t = task(cmd => [$^X, '-e', q{open my $f, q{>}, q{res/f} or die; print {$f} q{second}}],
				'output.file' => File::Spec->catfile('res', 'f'), lock => 1, dir => $d, quiet => 1);
		};
		waitpid $child, 0;
		like($err, qr/waiting for another run/, 'the second run waited (0.191: no)');
		is($t->{done}, 'before', 'and found the file made');
	};
}

# Write $line to a trace of its own, run report() over it, and return the
# error, or '' if it succeeded. Lines are bytes, as "trace.fh" writes them.
sub report_on {
	my $line = shift;
	my $d = fresh_dir();
	my $trace = File::Spec->catfile($d, 'trace.jsonl');
	open my $fh, '>', $trace or die $!;
	binmode $fh;
	print {$fh} $line, "\n";
	close $fh;
	eval { report(trace => $trace, html => File::Spec->catfile($d, 'report.html')) };
	return $@;
}

# 23. S04. The trace reader took more than JSON, and report() then failed
# deep inside, or drew a page from it.
subtest 'report() refuses a trace line that is not valid JSON (0.191 read it)' => sub {
	like(report_on(qq{{"will.do":"done","cmd":"\xff"}}), qr/line 1 .* it is not UTF-8/, 'bytes that are not UTF-8 (0.191: read as Latin-1)');
	like(report_on(qq{{"will.do":"done","cmd":"a\tb"}}), qr/raw control character/, 'a raw tab in a string (0.191: read)');
	like(report_on(q{{"will.do":"done","cmd":"\ud800"}}), qr/unpaired UTF-16 surrogate/, 'half a surrogate pair (0.191: read)');
	like(report_on('{"a":' . ('[' x 600) . (']' x 600) . '}'), qr/nests deeper than 512/, 'nesting past 512 (0.191: "Deep recursion")');
	like(report_on(q{{"will.do":"done","cmd":"a"}}), qr/\A\z/, 'while a good line is read'); # the sentinel
};

# 24. S04. A field the page computes with, or shows, of the wrong type: a
# string start time died "isn't numeric" from inside report(), and a list
# for a command was shown as "ARRAY(0x...)".
subtest 'report() names a trace field of the wrong type (0.191 died, or showed it)' => sub {
	like(report_on(q{{"will.do":"done","start.time":"soon"}}), qr/"start\.time" is not a number of seconds/, 'a time that is not a number');
	like(report_on(q{{"will.do":"done","start.time":1e20}}), qr/"start\.time" is not a time since the epoch/, 'a time past any date');
	like(report_on(q{{"will.do":"done","cmd":["a","b"]}}), qr/"cmd" is not a single value/, 'a command that is a list');
};

# 25. A title given as UTF-8 bytes was encoded a second time with the page.
subtest 'report() writes a UTF-8 byte-string title once (0.191 encoded it twice)' => sub {
	my $d = fresh_dir();
	my $trace = File::Spec->catfile($d, 'trace.jsonl');
	spew($trace, qq{{"will.do":"done","cmd":"a"}\n});
	my $html = File::Spec->catfile($d, 'report.html');
	report(trace => $trace, html => $html, title => "caf\xc3\xa9");
	open my $fh, '<', $html or die $!;
	binmode $fh;
	local $/;
	my $page = <$fh>;
	like($page, qr{<title>caf\xc3\xa9</title>}, 'the title is the UTF-8 of "cafe" with an acute e (0.191: four bytes for the e)');
};

#
# The tests above are of defects, and use only arguments 0.191 accepted. Those
# below are of "env.secret", new in 0.192, and cannot run against 0.191.
#

# 26. S03. Every "env" value went into the record, and so to the terminal,
# the log and the trace, credentials included.
subtest 'env.secret hides a value everywhere it would be printed, but the command still has it' => sub {
	my $d = fresh_dir();
	my $log = File::Spec->catfile($d, 'log');
	my $trace = File::Spec->catfile($d, 'trace.jsonl');
	open my $log_fh, '>', $log or die $!;
	open my $trace_fh, '>', $trace or die $!;
	my $t;
	my ($out, $err) = capture {
		# the command prints the value's length, not the value, which would
		# put it in the record's stdout
		$t = task(cmd => [$^X, '-e', q{print length $ENV{TOKEN}}],
			env => { TOKEN => 'hunter2', PLAIN => 'shown' },
			'env.secret' => ['TOKEN'], 'log.fh' => $log_fh, 'trace.fh' => $trace_fh);
	};
	close $log_fh;
	close $trace_fh;
	is($t->{stdout}, '7', 'the command was given the value'); # the sentinel
	is($t->{env}{TOKEN}, '(secret)', 'the record hides it');
	is($t->{env}{PLAIN}, 'shown', 'and not the variable it was not asked to');
	is_deeply($t->{'env.secret'}, ['TOKEN'], 'the record says which are hidden');
	my $trace_text = slurp($trace);
	like($trace_text, qr/"PLAIN":"shown"/, 'the trace has the env'); # the sentinel
	unlike($trace_text, qr/"TOKEN":"hunter2"/, 'but not the secret');
	like(slurp($log), qr/PLAIN/, 'the log has the env'); # the sentinel
	unlike(slurp($log), qr/hunter2/, 'but not the secret');
	like($out, qr/PLAIN/, 'the terminal has the env'); # the sentinel
	unlike($out, qr/hunter2/, 'but not the secret');
};

# 27. S03. An argument error prints the arguments; the secret stays hidden.
subtest 'an argument error does not print a secret' => sub {
	my $error;
	my (undef, $err) = capture {
		eval { task(cmd => 'true', env => { TOKEN => 'hunter2' }, 'env.secret' => ['TOKEN'], timeout => 'soon') };
		$error = $@;
	};
	like($error, qr/"timeout" must be a whole number/, 'task() refused the call'); # the sentinel
	like($err, qr/TOKEN/, 'and printed the arguments');
	unlike($err, qr/hunter2/, 'without the secret');
};

# 28. S03. What env.secret accepts, and how it combines with %DEFAULTS.
subtest 'env.secret is checked, and merged with the default one' => sub {
	my $t;
	capture {
		local %SimpleFlow::DEFAULTS = ('env.secret' => ['A']);
		$t = task(cmd => [$^X, '-e', 'exit 0'], env => { A => 'a', B => 'b', C => 'c' }, 'env.secret' => ['B'], quiet => 1);
	};
	is_deeply($t->{'env.secret'}, ['A', 'B'], "the default's names and the task's");
	is_deeply($t->{env}, { A => '(secret)', B => '(secret)', C => 'c' }, 'both hidden');
	capture {
		$t = task(cmd => [$^X, '-e', 'exit 0'], quiet => 1);
	};
	is_deeply($t->{'env.secret'}, [], 'none by default');
	foreach my $bad ('TOKEN', [undef], [''], ['A=B'], [['A']]) {
		my $error;
		capture { eval { task(cmd => [$^X, '-e', 'exit 0'], 'env.secret' => $bad, quiet => 1) }; $error = $@ };
		like($error, qr/"env\.secret" must be an array ref of the names/, 'a bad "env.secret" is refused');
	}
};

# 29. S03. A secret's value is not in the "stale.cmd" digest: it would be
# kept on disk, and a rotated credential would re-run every step.
subtest 'stale.cmd does not re-run a step whose secret changed' => sub {
	my $d = fresh_dir();
	my @common = (cmd => [$^X, '-e', q{open my $f, q{>}, q{out} or die}], 'output.file' => 'out',
		'stale.cmd' => 1, 'env.secret' => ['TOKEN'], dir => $d, quiet => 1);
	my ($first, $second);
	capture {
		$first  = task(@common, env => { TOKEN => 'old' });
		$second = task(@common, env => { TOKEN => 'new' });
	};
	is($first->{done}, 'now', 'the step ran'); # the sentinel
	is($second->{done}, 'before', 'and was not run again for a new secret');
};

done_testing();
