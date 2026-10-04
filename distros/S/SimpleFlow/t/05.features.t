#!/usr/bin/env perl

#
# Tests for the options and record fields added in 0.19: retries, env, dir,
# stdout_file and stderr_file, protect, output_dir(s), trace_fh, the CPU
# times, lock, %SimpleFlow::DEFAULTS, the stderr tail of a failure's message,
# input_dir(s), stale_cmd, the on_success and on_failure hooks, and wrapper,
# container, conda_env and executor. parallel() and report() are in
# t/06.pipeline.t. These are features, not fixes, so
# nothing here can run against an older module; the regression tests for the
# 0.19 fixes are in t/04.fixes.t.
#
# Every command is a list run by the perl already running ($^X), so that no
# path is re-parsed by a shell and none of the code needs a double quote (see
# t/03.fixes.t's header for why that matters on MSWin32).
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
use JSON::PP ();
use POSIX ();
use Time::HiRes ();
use SimpleFlow qw(task);

my $dir = tempdir(CLEANUP => 1);
my $n = 0;
sub fresh_path { return File::Spec->catfile($dir, 'f' . ++$n) }

# The same copy of the module this file loaded, not whatever is installed.
(my $lib_dir = $INC{'SimpleFlow.pm'}) =~ s{[/\\]SimpleFlow\.pm$}{};

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

# Run task() with the output captured, and return (record, stdout, stderr, error).
sub run_task {
	my @args = @_;
	refuse_double_quotes(@args);
	my ($t, $error);
	my ($out, $err) = capture {
		$t = eval { task(@args) };
		$error = $@;
	};
	return ($t, $out, $err, $error);
}

# --- retries ------------------------------------------------------------------
subtest 'retries: a step that fails once and then succeeds' => sub {
	my $counter = fresh_path();
	my $out = fresh_path();
	# exits 1 on its first run and 0 after, counting runs in $ARGV[0]
	my $flaky = q{my $n = -e $ARGV[0] ? do { open my $c, '<', $ARGV[0] or die; <$c> } : 0; }
		. q{open my $c, '>', $ARGV[0] or die; print $c $n + 1; close $c; }
		. q{exit 1 if $n == 0; open my $f, '>', $ARGV[1] or die; print $f 'ok'};
	my ($t, undef, $err) = run_task(cmd => [$^X, '-e', $flaky, $counter, $out],
		'output_file' => $out, retries => 2, quiet => 1);
	is($t->{'will.do'}, 'done', 'the step succeeded in the end');
	is($t->{attempts}, 2, 'on its second attempt');
	is(slurp($counter), 2, 'and the command really ran twice');
	like($err, qr/attempt 1 of 3.*retrying/, 'the failed attempt was reported');
};
subtest 'retries: a step that always fails stops after its last attempt' => sub {
	my ($t, undef, $err) = run_task(cmd => [$^X, '-e', 'exit 3'], retries => 2, die => 0, quiet => 1);
	is($t->{'will.do'}, 'FAILED', 'the step failed');
	is($t->{attempts}, 3, 'after 1 + 2 attempts');
	is($t->{'exit'}, 3, 'and the record is the last attempt\'s');
	my $retries = () = $err =~ /retrying/g;
	is($retries, 2, 'two retries were announced');
};
subtest 'retries: retry_delay waits between attempts' => sub {
	my $t0 = Time::HiRes::time();
	my ($t) = run_task(cmd => [$^X, '-e', 'exit 1'], retries => 1, 'retry_delay' => 0.5,
		die => 0, quiet => 1);
	my $took = Time::HiRes::time() - $t0;
	is($t->{attempts}, 2, 'there was a retry');
	# two perl start-ups take ~0.1 s here; the delay is what makes it 0.5 s or more
	cmp_ok($took, '>=', 0.5, 'and task() waited retry_delay before it');
};
subtest 'retries: the default is one attempt, and bad values are refused' => sub {
	my ($t) = run_task(cmd => [$^X, '-e', 'exit 1'], die => 0, quiet => 1);
	is($t->{attempts}, 1, 'one attempt without "retries"');
	is($t->{retries}, 0, 'and the record says retries => 0');
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], retries => 'twice');
	like($error, qr/"retries" must be a whole number/, 'a non-number retries is refused');
	(undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], 'retry_delay' => '-1');
	like($error, qr/"retry_delay" must be a number of seconds/, 'a negative retry_delay is refused');
};

# --- env ----------------------------------------------------------------------
subtest 'env: variables are set for the command only' => sub {
	local $ENV{SF_TEST_GONE} = 'still here';
	my ($t) = run_task(cmd => [$^X, '-e',
			q{print $ENV{SF_TEST_SET}, '|', (exists $ENV{SF_TEST_GONE} ? 'present' : 'absent')}],
		env => { SF_TEST_SET => 'set for the command', SF_TEST_GONE => undef }, quiet => 1);
	is($t->{stdout}, 'set for the command|absent', 'the command saw one set and one removed');
	ok(!exists $ENV{SF_TEST_SET}, 'the caller never had SF_TEST_SET');
	is($ENV{SF_TEST_GONE}, 'still here', 'and still has SF_TEST_GONE');
	is_deeply($t->{env}, { SF_TEST_SET => 'set for the command', SF_TEST_GONE => undef },
		'the record shows the env it was given');
};
subtest 'env: bad values are refused' => sub {
	foreach my $case ([[], 'an array ref'], [{ 'A=B' => 1 }, 'a name with "="'],
			[{ A => [] }, 'a reference as a value']) {
		my ($bad, $what) = @$case;
		my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], env => $bad);
		like($error, qr/"env"/, "$what is refused");
	}
};

# --- dir ----------------------------------------------------------------------
subtest 'dir: the step runs in the directory, and the caller stays put' => sub {
	my $work = File::Spec->catdir($dir, 'work' . ++$n);
	mkdir $work or die "cannot make $work: $!";
	my $before = Cwd::getcwd();
	my ($t) = run_task(cmd => [$^X, '-e', $WRITE, 'here.txt'], 'output_file' => 'here.txt',
		dir => $work, quiet => 1);
	is($t->{'will.do'}, 'done', 'the relative output was found in "dir"');
	ok(-f File::Spec->catfile($work, 'here.txt'), 'and was made there');
	is($t->{dir}, Cwd::abs_path($work), 'the record\'s dir is where it ran');
	is(Cwd::getcwd(), $before, 'the caller is back in its own directory');
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', 'exit 2'], dir => $work, quiet => 1);
	like($error, qr/exited 2/, 'a failing step in "dir" died');
	is(Cwd::getcwd(), $before, 'and the caller is back in its own directory even so');
	(undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], dir => fresh_path());
	like($error, qr/"dir"/, 'a directory that does not exist is refused');
};

# --- stdout_file and stderr_file ---------------------------------------------
subtest 'stdout_file and stderr_file receive the output instead of the record' => sub {
	my ($so, $se) = (fresh_path(), fresh_path());
	spew($so, 'left from an earlier run');
	my ($t) = run_task(cmd => [$^X, '-e', q{print 'to stdout'; print STDERR 'to stderr'}],
		'stdout_file' => $so, 'stderr_file' => $se, quiet => 1);
	is(slurp($so), 'to stdout', 'stdout went to its file, which was emptied first');
	is(slurp($se), 'to stderr', 'stderr went to its file');
	is($t->{stdout}, '', 'and the record holds neither');
	is($t->{stderr}, '', 'nor the other');
	is($t->{'stdout_file'}, $so, 'the record names the file');
};
subtest 'one file for both, and every attempt kept' => sub {
	my $both = fresh_path();
	my ($t) = run_task(cmd => [$^X, '-e', q{$| = 1; print 'out;'; print STDERR 'err;'; exit 1}],
		'stdout_file' => $both, 'stderr_file' => $both, retries => 1, die => 0, quiet => 1);
	is($t->{attempts}, 2, 'there were two attempts');
	is(slurp($both), 'out;err;out;err;', 'both streams of both attempts are in the one file, in order');
};
subtest 'a skipped step leaves its stdout_file alone' => sub {
	my ($out, $so) = (fresh_path(), fresh_path());
	spew($out, 'done already');
	spew($so, 'the log of the run that made it');
	my ($t) = run_task(cmd => [$^X, '-e', 'print 1'], 'output_file' => $out,
		'stdout_file' => $so, quiet => 1);
	is($t->{done}, 'before', 'the step was skipped');
	is(slurp($so), 'the log of the run that made it', 'and its stdout_file was not emptied');
};

# --- protect ------------------------------------------------------------------
SKIP: {
	skip 'root can write to a read-only file, so protect proves nothing', 3 if $> == 0;
	subtest 'protect: a successful output is made read-only' => sub {
		my $out = fresh_path();
		my ($t) = run_task(cmd => [$^X, '-e', $WRITE, $out], 'output_file' => $out,
			protect => 1, quiet => 1);
		is($t->{'will.do'}, 'done', 'the step ran');
		ok(-f $out, 'the output is there');
		ok(!-w $out, 'and is no longer writable');
		my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', $WRITE, $out],
			'output_file' => $out, protect => 1, overwrite => 1, quiet => 1);
		like($error, qr/write-protected/, 'forcing a re-run over it is refused, and says why');
		is(slurp($out), 'made', 'and the output is untouched');
	};
	subtest 'protect: a failed step\'s outputs are not protected' => sub {
		my $out = fresh_path();
		run_task(cmd => [$^X, '-e', "$WRITE; exit 1", $out], 'output_file' => $out,
			protect => 1, die => 0, quiet => 1);
		ok(-f "$out.failed", 'the failed output was moved aside');
		ok(-w "$out.failed", 'and is still writable');
	};
	subtest 'protect: everything in an output directory is made read-only' => sub {
		my $out = File::Spec->catdir($dir, 'protected' . ++$n);
		my $inside = File::Spec->catfile($out, 'inside.txt');
		run_task(cmd => [$^X, '-e', q{mkdir $ARGV[0] or die; open my $f, '>', $ARGV[1] or die}, $out, $inside],
			'output_dir' => $out, protect => 1, quiet => 1);
		ok(-f $inside, 'the file inside was made');
		ok(!-w $inside, 'and is read-only');
		chmod 0755, $out; chmod 0644, $inside; # so that tempdir's cleanup can remove them
	};
}

# --- output_dir and output_dirs -----------------------------------------------
subtest 'output_dir: a directory output is checked, skipped and moved aside' => sub {
	my $out = File::Spec->catdir($dir, 'outdir' . ++$n);
	my $make = q{use File::Spec; mkdir $ARGV[0] or die; open my $f, '>', File::Spec->catfile($ARGV[0], 'x') or die; print $f 'x'};
	my ($t) = run_task(cmd => [$^X, '-e', $make, $out], 'output_dir' => $out, quiet => 1);
	is($t->{'will.do'}, 'done', 'the step that made the directory succeeded');
	is_deeply($t->{'output_dirs'}, [$out], 'output_dir is folded into output_dirs');
	my ($again) = run_task(cmd => [$^X, '-e', 'exit 1'], 'output_dirs' => [$out], quiet => 1);
	is($again->{done}, 'before', 'with the directory there, the step is skipped');
	my $never = File::Spec->catdir($dir, 'never' . ++$n);
	my ($missing, undef, $err) = run_task(cmd => [$^X, '-e', '1'], 'output_dir' => $never,
		die => 0, quiet => 1);
	is($missing->{'will.do'}, 'FAILED', 'a directory that was never made is FAILED');
	like($err, qr/should have been made but are missing/, 'and is reported missing');
	my $partial = File::Spec->catdir($dir, 'partial' . ++$n);
	my ($failed) = run_task(cmd => [$^X, '-e', "$make; exit 1", $partial], 'output_dir' => $partial,
		die => 0, quiet => 1);
	ok(!-e $partial && -d "$partial.failed", 'a failed step\'s directory is moved aside');
	is_deeply($failed->{'failed.outputs'}, ["$partial.failed"], 'and listed in failed.outputs');
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'],
		'output_dir' => $out, 'output_dirs' => [$out]);
	like($error, qr/cannot both be given/, 'output_dir and output_dirs are mutually exclusive');
};
subtest 'output_dir: an empty directory is warned about' => sub {
	my $out = File::Spec->catdir($dir, 'empty' . ++$n);
	my ($t, undef, $err) = run_task(cmd => [$^X, '-e', 'mkdir $ARGV[0] or die', $out],
		'output_dir' => $out, quiet => 1);
	is($t->{'will.do'}, 'done', 'an empty directory still counts as made');
	like($err, qr/output directories are empty/, 'but is warned about');
};
subtest 'output_dir: stale looks at what is inside the directory' => sub {
	my $out = File::Spec->catdir($dir, 'stale' . ++$n);
	my $in = fresh_path();
	mkdir $out or die;
	my $inside = File::Spec->catfile($out, 'x');
	spew($inside, 'old');
	spew($in, 'input');
	# the input is made newer than everything in the directory
	my $now = time;
	utime $now - 100, $now - 100, $inside, $out;
	utime $now, $now, $in;
	my ($t) = run_task(cmd => [$^X, '-e', "open my \$f, '>', \$ARGV[0] or die; print \$f 'new'", $inside],
		'input_file' => $in, 'output_dir' => $out, stale => 1, quiet => 1);
	is($t->{'out.of.date'}, 1, 'the directory is out of date');
	is(slurp($inside), 'new', 'and was rebuilt');
	# The other way round: the directory's own mtime is older than the input,
	# but a file in it was rewritten since. A directory's mtime changes only
	# when an entry is added or removed, so judging by it alone would call
	# this out of date and rebuild it for nothing.
	utime $now - 200, $now - 200, $out;
	utime $now - 100, $now - 100, $in;
	utime $now, $now, $inside;
	my ($fresh) = run_task(cmd => [$^X, '-e', 'exit 1'],
		'input_file' => $in, 'output_dir' => $out, stale => 1, quiet => 1);
	is($fresh->{'out.of.date'}, 0, 'a directory whose contents are newer than the input is up to date');
	is($fresh->{done}, 'before', 'and is skipped');
};

# --- CPU times ----------------------------------------------------------------
SKIP: {
	skip 'the children\'s CPU times from times() are not known to be filled in on MSWin32', 1
		if $^O eq 'MSWin32';
	subtest 'cpu.user and cpu.system are the command\'s CPU time' => sub {
		# spins until its own user time reaches 0.3 s, so the figure does not
		# depend on how loaded the machine is
		my ($t) = run_task(cmd => [$^X, '-e', '1 while (times)[0] < 0.3'], quiet => 1);
		# times() counts in clock ticks, 1/100 s here, so 0.29 allows one tick
		cmp_ok($t->{'cpu.user'}, '>=', 0.29, 'cpu.user is at least what the command spent');
		cmp_ok($t->{'cpu.system'}, '>=', 0, 'cpu.system is a number of seconds');
		cmp_ok($t->{'start.time'}, '>', 0, 'start.time is set');
	};
}

# --- trace_fh -----------------------------------------------------------------
subtest 'trace_fh gets one JSON line per task, on every path' => sub {
	my $trace_file = fresh_path();
	open my $trace, '>', $trace_file or die "cannot write $trace_file: $!";
	my $out = fresh_path();
	run_task(cmd => [$^X, '-e', $WRITE, $out, "caf\x{e9}"], 'output_file' => $out,
		'trace_fh' => $trace, note => "caf\x{e9}", quiet => 1);
	run_task(cmd => [$^X, '-e', $WRITE, $out], 'output_file' => $out, 'trace_fh' => $trace, quiet => 1);
	run_task(cmd => [$^X, '-e', 'exit 4'], 'trace_fh' => $trace, die => 0, quiet => 1);
	close $trace;
	my @lines = split /\n/, slurp($trace_file);
	is(scalar @lines, 3, 'three tasks, three lines');
	my @records = map { eval { JSON::PP->new->utf8->decode($_) } } @lines;
	is(scalar @records, 3, 'each line is valid JSON');
	is($records[0]{'will.do'}, 'done', 'the first ran');
	is($records[0]{note}, "caf\x{e9}", 'with its non-ASCII note intact');
	is($records[1]{'will.do'}, 'no', 'the second was skipped');
	is($records[2]{'exit'}, 4, 'the third exited 4');
	like($lines[2], qr/"exit":4[,}]/, 'as a JSON number, not a string');
	ok(!exists $records[0]{stdout}, 'the captured output is left out of the trace');
	cmp_ok($records[1]{time}, '>', 0, 'every line says when it was written');
};

# --- lock ---------------------------------------------------------------------
SKIP: {
	skip 'the lock test forks, and needs a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'lock: a second run waits for the first, and then skips' => sub {
		my $work = File::Spec->catdir($dir, 'locked' . ++$n);
		mkdir $work or die;
		my ($started, $out) = map { File::Spec->catfile($work, $_) } 'started', 'out';
		# the command marks that it has started, holds the step for 1 s, and
		# then makes the output
		my $slow = q{open my $s, '>', $ARGV[0] or die; close $s; sleep 1; }
			. q{open my $f, '>', $ARGV[1] or die; print $f 'first'};
		my $first = fork();
		die "fork() failed: $!" if not defined $first;
		if ($first == 0) {
			open STDOUT, '>', File::Spec->devnull;
			open STDERR, '>', File::Spec->devnull;
			no warnings 'exec';
			exec($^X, "-I$lib_dir", '-MSimpleFlow', '-e',
				'task(cmd => [$^X, q{-e}, $ARGV[0], $ARGV[1], $ARGV[2]], q{output_file} => $ARGV[2], lock => 1, quiet => 1, dir => $ARGV[3])',
				$slow, $started, $out, $work)
				or POSIX::_exit(127); # "or": a statement after exec drew "Statement unlikely to be reached" on a 5.16.3 smoker, "no warnings" notwithstanding
		}
		# loading perl and SimpleFlow takes 29-44 ms here; 10 s is headroom for
		# a loaded machine, spent only if the first run never starts
		foreach (1 .. 500) { last if -e $started; Time::HiRes::sleep(0.02) }
		ok(-e $started, 'the first run started its command');
		my ($t, undef, $err) = run_task(cmd => [$^X, '-e', $WRITE, $out, 'second'],
			'output_file' => $out, lock => 1, quiet => 1, dir => $work);
		waitpid $first, 0;
		is($t->{done}, 'before', 'the second run found the step done');
		is(slurp($out), 'first', 'so the output is the first run\'s');
		like($err, qr/waiting for another run/, 'and it said it was waiting');
	};
}
subtest 'lock: an unshared step runs as usual, and dry runs take no lock' => sub {
	my $work = File::Spec->catdir($dir, 'lockplain' . ++$n);
	mkdir $work or die;
	my ($t) = run_task(cmd => [$^X, '-e', $WRITE, 'out'], 'output_file' => 'out', lock => 1,
		dir => $work, quiet => 1);
	is($t->{'will.do'}, 'done', 'the step ran');
	is($t->{lock}, 1, 'with lock => 1 on the record');
	ok(-d File::Spec->catdir($work, '.simpleflow'), 'the lock files live in .simpleflow');
	my $dry_work = File::Spec->catdir($dir, 'lockdry' . ++$n);
	mkdir $dry_work or die;
	run_task(cmd => 'x', 'output_file' => 'out', lock => 1, 'dry_run' => 1, dir => $dry_work, quiet => 1);
	ok(!-e File::Spec->catdir($dry_work, '.simpleflow'), 'a dry run made no lock file');
};

# --- %SimpleFlow::DEFAULTS ---------------------------------------------------
subtest '%DEFAULTS applies to every task that does not say otherwise' => sub {
	local %SimpleFlow::DEFAULTS = ('dry_run' => 1, quiet => 1, env => { SF_DEFAULT => 'from defaults' });
	my ($t, $out) = run_task(cmd => [$^X, '-e', '1']);
	is($t->{'will.do'}, 'no: dry run', 'a default dry_run makes every step a dry run');
	is($out, '', 'and a default quiet silences the terminal');
	my ($ran) = run_task(cmd => [$^X, '-e', 'print $ENV{SF_DEFAULT}, q{|}, $ENV{SF_OWN}'],
		'dry_run' => 0, env => { SF_OWN => 'from the task' });
	is($ran->{'will.do'}, 'done', 'a task that sets the key itself wins');
	is($ran->{stdout}, 'from defaults|from the task', 'and its env is merged with the default env');
};
subtest '%DEFAULTS refuses keys that name a particular step' => sub {
	foreach my $key ('cmd', 'output_file', 'no.such.key') {
		local %SimpleFlow::DEFAULTS = ($key => 'x');
		my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], quiet => 1);
		like($error, qr/%SimpleFlow::DEFAULTS.*\Q$key\E|\Q$key\E.*%SimpleFlow::DEFAULTS/s,
			"\"$key\" in %DEFAULTS is refused, naming %DEFAULTS");
	}
};

# --- the end of stderr in a failure's message --------------------------------
subtest "a failure's message ends with the last lines of stderr" => sub {
	my $noisy = q{print STDERR qq{line $_\n} for 1 .. 10; exit 1};
	my @warned;
	local $SIG{__WARN__} = sub { push @warned, @_ };
	run_task(cmd => [$^X, '-e', $noisy], die => 0, quiet => 1);
	my $message = join '', @warned;
	like($message, qr/exited 1/, 'the failure was warned about');
	like($message, qr/stderr ended with:\s+line 5\s+line 6\s+line 7\s+line 8\s+line 9\s+line 10/,
		'with its last six lines of stderr, in order');
	unlike($message, qr/line 4\b/, 'and nothing before them');
	my $file = fresh_path();
	@warned = ();
	run_task(cmd => [$^X, '-e', $noisy], 'stderr_file' => $file, die => 0, quiet => 1);
	like(join('', @warned), qr/stderr ended with:.*line 10/s, 'the tail is read back from stderr_file too');
	@warned = ();
	run_task(cmd => [$^X, '-e', 'exit 1'], die => 0, quiet => 1);
	unlike(join('', @warned), qr/stderr ended with/, 'a command that wrote no stderr gets no tail');
};

# --- input_dir and input_dirs -------------------------------------------------
subtest 'input_dir: a directory input must exist, except in a dry run' => sub {
	my $missing = File::Spec->catdir($dir, 'nodir' . ++$n);
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], 'input_dir' => $missing, quiet => 1);
	like($error, qr/missing or are not readable/, 'a missing input directory is refused');
	my ($dry, $out) = run_task(cmd => [$^X, '-e', '1'], 'input_dir' => $missing, 'dry_run' => 1);
	is($dry->{'will.do'}, 'no: dry run', 'but a dry run carries on');
	like($out, qr/do not exist yet.*\Q$missing\E/s, 'and lists it');
	my $present = File::Spec->catdir($dir, 'indir' . ++$n);
	mkdir $present or die;
	my ($t) = run_task(cmd => [$^X, '-e', '1'], 'input_dirs' => [$present], quiet => 1);
	is($t->{'will.do'}, 'done', 'a present input directory is accepted');
	is_deeply($t->{'input_dirs'}, [$present], 'and recorded');
};
subtest 'input_dir: stale looks at what is inside an input directory' => sub {
	my $in = File::Spec->catdir($dir, 'instale' . ++$n);
	mkdir $in or die;
	my $inside = File::Spec->catfile($in, 'x');
	my $out = fresh_path();
	spew($inside, 'data');
	spew($out, 'old');
	my $now = time;
	utime $now - 200, $now - 200, $in;  # the directory itself is old
	utime $now - 100, $now - 100, $out; # the output is newer than that
	utime $now, $now, $inside;          # but a file in the input is newer still
	my ($t) = run_task(cmd => [$^X, '-e', $WRITE, $out], 'input_dir' => $in, 'output_file' => $out,
		stale => 1, quiet => 1);
	is($t->{'out.of.date'}, 1, 'the output is out of date against the file inside');
	is($t->{done}, 'now', 'and was rebuilt');
};

# --- stale_cmd ----------------------------------------------------------------
subtest 'stale_cmd: a step whose command changed is run again' => sub {
	my $work = File::Spec->catdir($dir, 'cmdstale' . ++$n);
	mkdir $work or die;
	my @common = ('output_file' => 'out', 'stale_cmd' => 1, dir => $work, quiet => 1);
	my ($first) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'one'], @common);
	is($first->{done}, 'now', 'the first run ran');
	my ($same) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'one'], @common);
	is($same->{done}, 'before', 'the same command again is skipped');
	is($same->{'cmd.changed'}, 0, 'and has not changed');
	my ($changed) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'two'], @common);
	is($changed->{'cmd.changed'}, 1, 'a different command has changed');
	is($changed->{done}, 'now', 'and is run again');
	is(slurp(File::Spec->catfile($work, 'out')), 'two', 'making the new output');
	my ($env) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'two'], @common, env => { SF_X => 1 });
	is($env->{'cmd.changed'}, 1, 'so does a change of env');
	my ($without) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'three'], 'output_file' => 'out',
		dir => $work, quiet => 1);
	is($without->{done}, 'before', 'without stale_cmd a changed command is still skipped, as before 0.19');
};
subtest 'stale_cmd: outputs made without it are adopted, not re-run' => sub {
	my $work = File::Spec->catdir($dir, 'adopt' . ++$n);
	mkdir $work or die;
	spew(File::Spec->catfile($work, 'out'), 'made before stale_cmd was used');
	my @common = ('output_file' => 'out', 'stale_cmd' => 1, dir => $work, quiet => 1);
	my ($t) = run_task(cmd => [$^X, '-e', $WRITE, 'out'], @common);
	is($t->{done}, 'before', 'an output with no command on record is not re-run');
	my ($changed) = run_task(cmd => [$^X, '-e', $WRITE, 'out', 'new'], @common);
	is($changed->{'cmd.changed'}, 1, 'but its command was recorded, so the next change is seen');
};

# --- on_success and on_failure ------------------------------------------------
subtest 'on_success and on_failure are called with the record' => sub {
	my (@success, @failure);
	my %hooks = ('on_success' => sub { push @success, shift }, 'on_failure' => sub { push @failure, shift });
	my $out = fresh_path();
	run_task(cmd => [$^X, '-e', $WRITE, $out], 'output_file' => $out, %hooks, quiet => 1);
	is(scalar @success, 1, 'on_success was called once');
	is($success[0]{'will.do'}, 'done', 'with the record of the run');
	is(scalar @failure, 0, 'on_failure was not called');
	run_task(cmd => [$^X, '-e', '1'], 'output_file' => $out, %hooks, quiet => 1);
	is(scalar @success, 1, 'a skip calls neither');
	my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', 'exit 6'], %hooks, quiet => 1);
	is(scalar @failure, 1, 'a failure under die => 1 calls on_failure');
	is($failure[0]{'exit'}, 6, 'with the failed record');
	like($error, qr/exited 6/, 'before task() dies as usual');
	my (undef, undef, undef, $bad) = run_task(cmd => [$^X, '-e', '1'], 'on_success' => 'not code');
	like($bad, qr/"on_success" must be a code ref/, 'a hook that is not code is refused');
};

# --- wrapper, container, conda_env, executor ---------------------------------
subtest 'wrapper: the command runs inside the wrapper' => sub {
	# a wrapper that says it ran, and then runs what it was given. Not with
	# exec: on MSWin32 that starts the command and ends the wrapper at once, so
	# task() saw the wrapper finish before the command printed anything, and
	# 0.19's stdout here was '' on a Strawberry Perl 5.42.0 smoker.
	my $wrapper = [$^X, '-e', q{print STDERR 'wrapped;'; system {$ARGV[0]} @ARGV; exit $? >> 8}];
	my ($t) = run_task(cmd => [$^X, '-e', q{print 'the command'}], wrapper => $wrapper, quiet => 1);
	is($t->{stdout}, 'the command', 'the command ran');
	is($t->{stderr}, 'wrapped;', 'inside the wrapper');
	like($t->{'wrapped.cmd'}, qr/\Q$^X\E -e .*print 'the command'/, 'and wrapped.cmd shows the whole of it');
	is($t->{cmd}, join(' ', $^X, '-e', q{print 'the command'}), 'while cmd is the command as given');
	SKIP: {
		skip 'a string command is wrapped in /bin/sh -c, which MSWin32 does not have', 1 if $^O eq 'MSWin32';
		my ($s) = run_task(cmd => qq{"$^X" -e "print 1" && "$^X" -e "print 2"}, wrapper => $wrapper, quiet => 1);
		is($s->{stdout}, '12', 'a string command keeps its shell features inside the wrapper');
	}
};
subtest 'container, conda_env and executor build the wrapped command' => sub {
	my $cwd = Cwd::getcwd();
	my ($docker) = run_task(cmd => ['samtools', 'index', 'x.bam'], container => 'biocontainers/samtools:1.19',
		'dry_run' => 1, quiet => 1);
	like($docker->{'wrapped.cmd'}, qr/\Adocker run --rm .*-v \Q$cwd:$cwd\E -w \Q$cwd\E .*biocontainers\/samtools:1\.19 samtools index x\.bam\z/,
		'a container defaults to docker, with the working directory mounted');
	my ($apptainer) = run_task(cmd => ['samtools', 'index', 'x.bam'], container => 'samtools.sif',
		'container_engine' => 'apptainer', 'dry_run' => 1, quiet => 1);
	like($apptainer->{'wrapped.cmd'}, qr/\Aapptainer exec --bind \Q$cwd\E --pwd \Q$cwd\E samtools\.sif samtools index x\.bam\z/,
		'apptainer and singularity use exec, with the working directory bound');
	my ($conda) = run_task(cmd => ['python', 'x.py'], 'conda_env' => 'analysis', 'dry_run' => 1, quiet => 1);
	like($conda->{'wrapped.cmd'}, qr/\Aconda run --no-capture-output -n analysis python x\.py\z/,
		'conda_env runs the command with conda run');
	my ($slurm) = run_task(cmd => ['bwa', 'mem', 'ref.fa'], executor => 'slurm', threads => 8, mem => '16G',
		walltime => '2:00:00', 'executor_args' => ['--partition=short'], 'dry_run' => 1, quiet => 1);
	like($slurm->{'wrapped.cmd'}, qr/\Asrun --cpus-per-task=8 --mem=16G --time=2:00:00 --partition=short bwa mem ref\.fa\z/,
		'executor => slurm runs it with srun, asking for the resources');
	my ($local) = run_task(cmd => [$^X, '-e', 'print $ENV{SIMPLEFLOW_THREADS}'], threads => 3, quiet => 1);
	is($local->{stdout}, 3, 'run locally, the command is told its threads in SIMPLEFLOW_THREADS');
	foreach my $bad (['container_engine' => 'lxc', container => 'x'], [executor => 'pbs'], [threads => 0],
			[mem => 'lots'], [walltime => 'soon'], [wrapper => 'nice']) {
		my (undef, undef, undef, $error) = run_task(cmd => [$^X, '-e', '1'], @$bad);
		like($error, qr/"\Q$bad->[0]\E"/, "a bad \"$bad->[0]\" is refused");
	}
};

# --- the record's shape -------------------------------------------------------
subtest 'the new fields are on the record on every path' => sub {
	my $out = fresh_path();
	my %t;
	($t{'a run'})     = run_task(cmd => [$^X, '-e', $WRITE, $out], 'output_file' => $out, quiet => 1);
	($t{'a skip'})    = run_task(cmd => [$^X, '-e', '1'], 'output_file' => $out, quiet => 1);
	($t{'a dry run'}) = run_task(cmd => [$^X, '-e', '1'], 'dry_run' => 1, quiet => 1);
	is($t{'a run'}{done}, 'now', 'the run ran');
	is($t{'a skip'}{done}, 'before', 'the skip skipped');
	is($t{'a dry run'}{'will.do'}, 'no: dry run', 'the dry run was one');
	my %expected = (
		attempts => undef, 'cpu.user' => undef, 'cpu.system' => undef, 'start.time' => undef,
		env => {}, lock => 0, protect => 0, retries => 0, 'retry_delay' => 0,
		'stdout_file' => '', 'stderr_file' => '', 'output_dirs' => [],
		'input_dirs' => [], 'stale_cmd' => 0, 'cmd.changed' => 0, wrapper => [], container => '',
		'container_engine' => '', 'conda_env' => '', executor => 'local', 'executor_args' => [],
		threads => 0, mem => '', walltime => '', 'wrapped.cmd' => '',
	);
	foreach my $path (sort keys %t) {
		foreach my $key (sort keys %expected) {
			ok(exists $t{$path}{$key}, "\"$key\" is present after $path");
			is_deeply($t{$path}{$key}, $expected{$key}, "and holds its default after $path")
				if defined $expected{$key};
		}
	}
	is($t{'a skip'}{attempts}, 0, 'nothing was attempted by the skip');
	is($t{'a run'}{attempts}, 1, 'one attempt by the run');
};

done_testing();
