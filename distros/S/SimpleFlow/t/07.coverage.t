#!/usr/bin/env perl

#
# Coverage of branches the other files leave unexercised, chosen from the
# Devel::Cover report of 2026-09-26 (sh cover.sh, all of t/ on perl 5.44.0):
# argument checks with no test, the wrapped command's less common layers, the
# messages a step prints when it is not quiet, an interrupt that reaches
# task() or parallel() in this process rather than in a child perl, the ways
# report() refuses, and the trace reader's error messages. Several use options
# added in 0.19, so this file cannot run against an older module.
#
# The code left uncovered after this file is what a test here cannot reach
# honestly: fork() or pipe() failing, the MSWin32 branches, a terminal's job
# control (SIGTSTP with the command in the foreground), and the forked
# children of _run_forked and parallel(), which end with POSIX::_exit and so
# never write their coverage out.
#
# Commands are lists run by $^X, as in t/05.features.t, so that nothing goes
# through a shell and no code needs a double quote.
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
use NoDoubleQuote 'refuse_double_quotes'; # t/lib: what MSWin32 would garble in a list cmd
use File::Temp 'tempdir';
use POSIX ();
use Time::HiRes ();
use SimpleFlow qw(task say2 parallel report);

my $dir = tempdir(CLEANUP => 1);
my $n = 0;
sub fresh_path { return File::Spec->catfile($dir, 'f' . ++$n) }

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
# perl code that writes $ARGV[1] (or 'made') to the file named in $ARGV[0]
my $WRITE = q{open my $f, '>', $ARGV[0] or die; print $f (defined $ARGV[1] ? $ARGV[1] : 'made')};

# Run $code with the output captured, and return (its value, stdout, stderr, error).
sub run_captured {
	my $code = shift;
	my ($value, $error);
	my ($out, $err) = capture {
		$value = eval { $code->() };
		$error = $@;
	};
	return ($value, $out, $err, $error);
}
sub run_task {
	my @args = @_;
	refuse_double_quotes(@args);
	return run_captured(sub { task(@args) });
}

# --- say2 ---------------------------------------------------------------------
subtest 'say2: an undefined message is printed as an empty one' => sub {
	my $log = fresh_path();
	open my $fh, '>', $log or die;
	my ($msg, $out, undef, $error) = run_captured(sub { say2(undef, $fh) });
	close $fh;
	is($error, '', 'say2 did not die on undef under warnings FATAL');
	like($msg, qr/\A\@ \S*07\.coverage\.t line \d+ \z/, 'it returned the location and nothing after it');
	is(slurp($log), "$msg\n", 'and wrote that to the handle');
	is($out, "$msg\n", 'and to STDOUT');
};

# --- argument checks ----------------------------------------------------------
subtest 'task: the checks that pair and shape the newer options' => sub {
	my @cases = (
		[['executor_args' => ['--partition=short']], qr/"executor_args" needs an executor/],
		[['executor_args' => ['--partition=short'], executor => 'local'], qr/"executor_args" needs an executor/],
		[['container_args' => ['--gpus', 'all']], qr/"container_args" needs a "container"/],
		[['container_args' => '--gpus', container => 'img'], qr/"container_args" must be an array ref of words(?!, at least one)/],
		[[wrapper => [undef]], qr/"wrapper" must be an array ref of words, at least one/],
		[[wrapper => [['nice']]], qr/"wrapper" must be an array ref of words, at least one/],
		[[dir => ''], qr/"dir" must be a path, not the empty string/],
		[['stdout_file' => []], qr/"stdout_file" must be a path, not a reference/],
		[['stderr_file' => ''], qr/"stderr_file" must be a path, not the empty string/],
	);
	foreach my $case (@cases) {
		my ($args, $expect) = @$case;
		my (undef, undef, $err, $error) = run_task(cmd => [$^X, '-e', '1'], quiet => 1, @$args);
		like($error, $expect, "refused: @{[ join ' => ', map { ref $_ ? '[...]' : $_ } @$args ]}");
		like($err, qr/\S/, 'after dumping the arguments to STDERR');
	}
};
subtest 'task: a stdout_file that cannot be created is named in the error' => sub {
	my $nowhere = File::Spec->catfile($dir, 'no-such-dir' . ++$n, 'out.txt');
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', 'print 1'], 'stdout_file' => $nowhere, quiet => 1);
	like($error, qr/cannot empty "\Q$nowhere\E"/, 'task() died naming the file');
};

# --- the wrapped command ------------------------------------------------------
subtest 'wrapped command: the less common layers' => sub {
	my $cwd = Cwd::getcwd();
	my ($podman) = run_task(cmd => ['prog'], container => 'img', 'container_engine' => 'podman',
		stdin => 'inherit', env => { KEEP => 'x', DROP => undef }, threads => 2,
		'container_args' => ['--gpus', 'all'], 'dry_run' => 1, quiet => 1);
	# podman is rootless and maps the caller's user already, so no --user;
	# a variable "env" removes is not passed in, and one it sets is, by name
	is($podman->{'wrapped.cmd'},
		"podman run --rm -i -v $cwd:$cwd -w $cwd -e KEEP -e SIMPLEFLOW_THREADS --gpus all img prog",
		'podman: -i for stdin, each variable by name, and container_args before the image');
	my ($srun) = run_task(cmd => ['prog'], executor => 'slurm', 'dry_run' => 1, quiet => 1);
	is($srun->{'wrapped.cmd'}, 'srun prog', 'slurm asks for no resources that were not given');
	my $prefix = File::Spec->catdir('envs', 'analysis');
	my ($conda) = run_task(cmd => ['prog'], 'conda_env' => $prefix, 'dry_run' => 1, quiet => 1);
	is($conda->{'wrapped.cmd'}, "conda run --no-capture-output -p $prefix prog",
		'a conda_env with a directory separator is a prefix, given with -p');
	my ($string) = run_task(cmd => 'prog one two', wrapper => ['nice'], 'dry_run' => 1, quiet => 1);
	is($string->{'wrapped.cmd'},
		($^O eq 'MSWin32') ? 'nice cmd.exe /c prog one two' : 'nice /bin/sh -c prog one two',
		'a string command goes to the platform shell inside the wrapper');
};

# --- what a step says when it is not quiet ------------------------------------
subtest 'a dry run that is not quiet shows the wrapped command and the missing inputs' => sub {
	my $log = fresh_path();
	open my $log_fh, '>', $log or die;
	my $missing = fresh_path();
	my ($t, $out) = run_task(cmd => ['prog'], wrapper => ['nice'], 'input_file' => $missing,
		'log_fh' => $log_fh, 'dry_run' => 1);
	close $log_fh;
	is($t->{'will.do'}, 'no: dry run', 'it was a dry run');
	like($out, qr/^run as: nice prog$/m, 'the terminal shows what would really be run');
	like($out, qr/inputs do not exist yet.*\Q$missing\E/s, 'and the input that is not there yet');
	like(slurp($log), qr/inputs do not exist yet.*\Q$missing\E/s, 'and so does the log');
};
subtest 'stale: the reason for a re-run is printed, and a step with no inputs is never stale' => sub {
	my ($in, $made) = (fresh_path(), fresh_path());
	spew($in, 'input');
	spew($made, 'old');
	my $past = time - 100;
	utime $past, $past, $made or die "cannot set the time of $made: $!";
	my ($t, $out) = run_task(cmd => [$^X, '-e', $WRITE, $made, 'new'], 'input_file' => $in,
		'output_file' => $made, stale => 1);
	is($t->{'out.of.date'}, 1, 'the output was older than the input');
	like($out, qr/is being re-run: an input file is newer than an output file/, 'and the terminal says why it ran');
	is(slurp($made), 'new', 'and it did run');
	utime $past, $past, $made or die "cannot set the time of $made: $!";
	my ($none) = run_task(cmd => [$^X, '-e', $WRITE, $made, 'newer'], 'output_file' => $made, stale => 1, quiet => 1);
	is($none->{done}, 'before', 'with no inputs, stale has nothing to compare, so the step was done before');
	is(slurp($made), 'new', 'and was not run again');
};
subtest 'stale_cmd: the reason for a re-run is printed' => sub {
	my $made = fresh_path();
	run_task(cmd => [$^X, '-e', $WRITE, $made, 'one'], 'output_file' => $made, 'stale_cmd' => 1, quiet => 1);
	my ($t, $out) = run_task(cmd => [$^X, '-e', $WRITE, $made, 'two'], 'output_file' => $made, 'stale_cmd' => 1);
	is($t->{'cmd.changed'}, 1, 'the command had changed');
	like($out, qr/is being re-run: its command has changed since its outputs were made/, 'and the terminal says so');
};

# --- a failed directory output ------------------------------------------------
subtest 'a failed directory output replaces the .failed directory of an earlier failure' => sub {
	my $made = File::Spec->catdir($dir, 'dir' . ++$n);
	# makes the directory $ARGV[0], writes $ARGV[1] into a file there, and fails
	my $fail = q{use File::Spec; mkdir $ARGV[0] or die; open my $f, '>', File::Spec->catfile($ARGV[0], 'content') or die; print $f $ARGV[1]; exit 1};
	my ($first) = run_task(cmd => [$^X, '-e', $fail, $made, 'first'], 'output_dir' => $made, die => 0, quiet => 1);
	is_deeply($first->{'failed.outputs'}, ["$made.failed"], 'the first failure moved the directory aside');
	my ($second) = run_task(cmd => [$^X, '-e', $fail, $made, 'second'], 'output_dir' => $made, die => 0, quiet => 1);
	is_deeply($second->{'failed.outputs'}, ["$made.failed"], 'and so did the second, over the first');
	is(slurp(File::Spec->catfile("$made.failed", 'content')), 'second', 'which now holds the second run\'s output');
	ok(!-e $made, 'and the declared name is free for the next run');
};

# --- an interrupt that reaches task() or parallel() ---------------------------
# The command sends the signal to task()'s own process, which is the one
# running this file: its parent, or, for parallel(), the pid given to it.
# task() installs its handlers once the exec has succeeded -- which it learns
# from a pipe that exec closes -- and holds these signals back from before the
# fork until then, so one the command sends first is not lost. Until 0.20
# nothing held them, and the 29-44 ms the command takes to start perl here
# was relied on instead; a CPAN smoker lost that race, and t/08.fixes.t now
# sends the signal inside the window on purpose. Each command would sleep for 30 s if the signal did not end it; the bound
# of 10 s tells the two apart with headroom for a loaded machine.
SKIP: {
	skip 'needs POSIX signals and a real fork()', 4 if $^O eq 'MSWin32';
	foreach my $timeout (0, 30) {
		my $how = $timeout ? 'a timed step (its own process group)' : 'an untimed step';
		subtest "task: a TERM during $how ends the command, and then reaches the caller" => sub {
			my $caught;
			local $SIG{TERM} = sub { $caught = shift };
			my $sent = Time::HiRes::time();
			my ($t, undef, $err) = run_task(cmd => [$^X, '-e', 'kill TERM => getppid; sleep 30'],
				timeout => $timeout, die => 0, quiet => 1);
			cmp_ok(Time::HiRes::time() - $sent, '<', 10, 'the command was ended, not waited out');
			is($t->{'will.do'}, 'FAILED', 'the step failed');
			# untimed, the command is passed the same signal; timed, its whole
			# group is killed
			is($t->{signal}, $timeout ? POSIX::SIGKILL() : POSIX::SIGTERM(), 'and the command died of the signal it was sent');
			is($t->{'timed.out'}, 0, 'which is not a timeout');
			like($err, qr/was killed when task\(\) received SIGTERM/, 'the warning says what happened');
			is($caught, 'TERM', "and the signal went on to the caller's own handler");
		};
	}
	subtest 'parallel: a TERM to this process ends the running step, and then reaches the caller' => sub {
		my $caught;
		local $SIG{TERM} = sub { $caught = shift };
		my $sent = Time::HiRes::time();
		my (undef, undef, undef, $error) = run_captured(sub {
			parallel(jobs => 2, tasks => [{ cmd => [$^X, '-e', 'kill TERM => $ARGV[0]; sleep 30', $$], quiet => 1 }]);
		});
		cmp_ok(Time::HiRes::time() - $sent, '<', 10, 'the step was ended, not waited out');
		like($error, qr/1 of 1 tasks failed/, 'parallel() died with the failure');
		like($error, qr/was killed when task\(\) received SIGTERM/, 'which says what happened');
		is($caught, 'TERM', "and the signal went on to the caller's own handler");
	};
	subtest 'parallel: a step whose process is killed outright is reported, not lost' => sub {
		# the command's parent is the child that parallel() forked to run task()
		my (undef, undef, undef, $error) = run_captured(sub {
			parallel(jobs => 2, tasks => [{ cmd => [$^X, '-e', 'kill KILL => getppid'], quiet => 1 }]);
		});
		like($error, qr/task 0 \(.*\): the process running it ended before it could return a record/,
			'parallel() died saying the record never came back');
	};
}

# --- parallel: the serial path and its arguments ------------------------------
subtest 'parallel: with jobs => 1, a failure stops the steps after it' => sub {
	my $never = fresh_path();
	my (undef, undef, undef, $error) = run_captured(sub {
		parallel(jobs => 1, tasks => [
			{ cmd => [$^X, '-e', 'exit 5'], quiet => 1 },
			{ cmd => [$^X, '-e', $WRITE, $never], 'output_file' => $never, quiet => 1 },
		]);
	});
	like($error, qr/1 of 2 tasks failed/, 'parallel() died with the failure');
	like($error, qr/task 0 .*exited 5/, 'naming the task that failed');
	ok(!-e $never, 'and the step after it never ran');
};
subtest 'parallel: an odd-length list is refused' => sub {
	my (undef, undef, undef, $error) = run_captured(sub { parallel('jobs') });
	like($error, qr/parallel\(\) takes a flat key\/value list/, 'refused with the form it takes');
};

# --- report -------------------------------------------------------------------
subtest 'report: the ways it refuses its arguments' => sub {
	my $trace = fresh_path();
	spew($trace, qq{{"cmd":"a","will.do":"done"}\n});
	my $nowhere = File::Spec->catfile($dir, 'no-such-dir' . ++$n, 'report.html');
	my $missing = fresh_path();
	my @cases = (
		[['trace'], qr/report\(\) takes a flat key\/value list/],
		[[trace => $trace, html => fresh_path(), colour => 1], qr/report\(\) does not accept "colour"/],
		[[trace => $trace], qr/report\(\) needs "html"/],
		[[trace => [], html => fresh_path()], qr/report\(\) needs "trace"/],
		[[trace => '', html => fresh_path()], qr/report\(\) needs "trace"/],
		[[trace => $missing, html => fresh_path()], qr/cannot read the trace "\Q$missing\E"/],
		[[trace => $trace, html => $nowhere], qr/cannot write the report "\Q$nowhere\E"/],
	);
	foreach my $case (@cases) {
		my ($args, $expect) = @$case;
		my (undef, undef, undef, $error) = run_captured(sub { report(@$args) });
		like($error, $expect, "refused: $expect");
	}
};
subtest 'report: dry runs, unknown statuses, blank lines, and a trace where nothing ran' => sub {
	my $trace = fresh_path();
	spew($trace, qq{{"cmd":"a","will.do":"no: dry run","start.time":0}\n}
		. qq{\n   \n}
		. qq{{"cmd":"b","will.do":"yes"}\n}
		. qq{{"cmd":"c"}\n});
	my $html_file = fresh_path() . '.html';
	my ($count, undef, undef, $error) = run_captured(sub { report(trace => $trace, html => $html_file, title => 'Mine <x>') });
	is($error, '', 'report() returned');
	is($count, 3, 'reading three tasks, and skipping the blank lines');
	my $html = slurp($html_file);
	like($html, qr{<title>Mine &lt;x&gt;</title>}, 'the title given is used, escaped');
	like($html, qr/3 tasks: 0 done, 0 skipped, 0 failed, 1 dry runs/, 'a dry run is counted in the summary');
	like($html, qr/<tr class="dry">.*class="status">dry run<.*<tr class="other">.*class="status">yes<.*<tr class="other">.*class="status">unknown</s,
		'a status report() does not know is shown as it is, and a missing one as unknown');
	like($html, qr/<div class="lane"><\/div>/, 'the positive half: the timeline column is there');
	unlike($html, qr/class="bar/, 'but it has no bar, since nothing ran');
};

# --- the trace reader's errors ------------------------------------------------
subtest 'report: the trace reader names what is wrong, and where' => sub {
	my @cases = (
		['{"a":1} x',     qr/\Aunexpected text after the JSON value, at character 8\n\z/],
		['{1:2}',         qr/\Aexpected a string for a key, at character 1\n\z/],
		['{"a" 1}',       qr/\Aexpected ":" after a key, at character 4\n\z/],
		['{"a":1 "b":2}', qr/\Aexpected "," or "\}" in an object, at character 7\n\z/],
		['[1 2]',         qr/\Aexpected "," or "\]" in an array, at character 3\n\z/],
		['"abc',          qr/\Aa string is not closed, or has a bad escape, at character 4\n\z/],
		['"a\x"',         qr/\Aa string is not closed, or has a bad escape, at character 2\n\z/],
		['nope',          qr/\Aexpected a JSON value, at character 0\n\z/],
	);
	foreach my $case (@cases) {
		my ($json, $expect) = @$case;
		# the positive half first: this input must really reach the reader
		ok(!defined eval { SimpleFlow::_json_decode($json); 1 }, "'$json' is refused");
		like($@, $expect, 'with the reason and the character it stopped at');
	}
};

done_testing();
