#!/usr/bin/env perl

#
# Tests for parallel() and report(), added in 0.19: running independent steps
# at the same time, and an HTML report of a pipeline's trace. Neither exists
# before 0.19, so nothing here can run against an older module.
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
use File::Spec;
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use NoDoubleQuote 'refuse_double_quotes'; # t/lib: what MSWin32 would garble in a list cmd
use File::Temp 'tempdir';
use JSON::PP ();
use POSIX ();
use Time::HiRes ();
use SimpleFlow qw(task parallel report);

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

# Leaves a marker named $ARGV[1] in the directory $ARGV[0], then waits until
# $ARGV[2] markers are there, and prints how many it saw. Tasks run at the
# same time all see every marker at once; tasks run one after another cannot,
# and the first gives up after 10 s -- headroom for a loaded machine over the
# 29-44 ms perl takes to start here, spent only when something is wrong.
my $RENDEZVOUS = q{use File::Spec; my ($d, $me, $all) = @ARGV; open my $m, '>', File::Spec->catfile($d, $me) or die; close $m; }
	. q{my $until = time + 10; my $seen; }
	. q{while (1) { opendir my $h, $d or die; $seen = grep { !/^\./ } readdir $h; last if $seen >= $all || time > $until; select undef, undef, undef, 0.02 } }
	. q{print $seen};

sub run_parallel {
	my @args = @_;
	refuse_double_quotes(@args);
	my (@records, $error);
	my ($out, $err) = capture {
		@records = eval { parallel(@args) };
		$error = $@;
	};
	return (\@records, $out, $err, $error);
}

# parallel() refuses "jobs" above 1 on MSWin32, on purpose, so the subtests
# that need it are skipped there and this one checks the refusal instead. 0.19
# ran them anyway, and failed three subtests on a Strawberry Perl 5.42.0 smoker.
my $NO_FORK = '"jobs" above 1 is refused on MSWin32, which has no real fork()';
SKIP: {
	skip 'only MSWin32 refuses "jobs" above 1', 1 if $^O ne 'MSWin32';
	subtest 'parallel: "jobs" above 1 is refused on MSWin32, saying why' => sub {
		my $out = fresh_path();
		my ($records, undef, undef, $error) = run_parallel(jobs => 2,
			tasks => [{ cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die}, $out], quiet => 1 }]);
		like($error, qr/"jobs" above 1 is not supported on MSWin32: it needs a real fork\(\)/, 'parallel() died, saying why');
		ok(!-e $out, 'before running any step');
	};
}

SKIP: {
	skip $NO_FORK, 1 if $^O eq 'MSWin32';
	subtest 'parallel: the steps run at the same time, and come back in order' => sub {
		my $markers = File::Spec->catdir($dir, 'markers' . ++$n);
		mkdir $markers or die;
		my @tasks = map { { cmd => [$^X, '-e', $RENDEZVOUS, $markers, "m$_", 3], quiet => 1, note => "task $_" } } 1 .. 3;
		my ($records, undef, undef, $error) = run_parallel(jobs => 3, tasks => \@tasks);
		is($error, '', 'parallel() returned');
		is(scalar @$records, 3, 'with a record for each task');
		is_deeply([map { $_->{stdout} } @$records], [3, 3, 3], 'each saw all three running at once');
		is_deeply([map { $_->{note} } @$records], ['task 1', 'task 2', 'task 3'], 'in the order given');
		like($records->[0]{'source.file'}, qr/06\.pipeline\.t\z/, 'source.file is the caller of parallel()');
	};
}

SKIP: {
	skip $NO_FORK, 1 if $^O eq 'MSWin32';
	subtest 'parallel: a failure stops new steps, lets the running ones finish, and dies' => sub {
		my ($slow_out, $never) = (fresh_path(), fresh_path());
		my @tasks = (
			{ cmd => [$^X, '-e', 'exit 5'], quiet => 1 },
			{ cmd => [$^X, '-e', q{sleep 1; open my $f, '>', $ARGV[0] or die}, $slow_out], 'output.file' => $slow_out, quiet => 1 },
			{ cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die}, $never], 'output.file' => $never, quiet => 1 },
		);
		my (undef, undef, undef, $error) = run_parallel(jobs => 2, tasks => \@tasks);
		like($error, qr/exited 5/, 'parallel() died with the failure');
		ok(-e $slow_out, 'the step already running when it failed was finished');
		ok(!-e $never, 'and the step not yet started was not');
	};
}

subtest 'parallel: keep.going runs every step, and then dies' => sub {
	my $later = fresh_path();
	my @tasks = (
		{ cmd => [$^X, '-e', 'exit 5'], quiet => 1 },
		{ cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die}, $later], 'output.file' => $later, quiet => 1 },
	);
	my (undef, undef, undef, $error) = run_parallel(jobs => 1, tasks => \@tasks, 'keep.going' => 1);
	ok(-e $later, 'the step after the failure still ran');
	like($error, qr/exited 5/, 'and parallel() died with the failure at the end');
	like($error, qr/1 of 2 tasks failed/, 'saying how many');
};

SKIP: {
	skip $NO_FORK, 1 if $^O eq 'MSWin32';
	subtest 'parallel: under die => 0 the failed records come back' => sub {
		my @tasks = ({ cmd => [$^X, '-e', 'exit 5'], die => 0, quiet => 1 }, { cmd => [$^X, '-e', 'print 1'], quiet => 1 });
		my ($records, undef, undef, $error) = run_parallel(jobs => 2, tasks => \@tasks);
		is($error, '', 'parallel() returned');
		is_deeply([map { $_->{'will.do'} } @$records], ['FAILED', 'done'], 'with both records');
	};
}

subtest 'parallel: bad arguments are refused' => sub {
	foreach my $case ([[jobs => 0, tasks => []], qr/"jobs"/], [[jobs => 2], qr/"tasks"/],
			[[jobs => 2, tasks => ['cmd']], qr/"tasks".*index 0/], [[jobs => 2, tasks => [], bogus => 1], qr/bogus/]) {
		my ($args, $expect) = @$case;
		my (undef, undef, undef, $error) = run_parallel(@$args);
		like($error, $expect, "refused: $expect");
	}
};

SKIP: {
	skip 'needs POSIX signals and a real fork()', 1 if $^O eq 'MSWin32';
	subtest 'parallel: a TERM to perl ends every running step, and then perl' => sub {
		my @pid_files = (fresh_path(), fresh_path());
		my $code = q{use strict; use warnings FATAL => 'all'; use SimpleFlow 'parallel'; }
			. q{parallel(jobs => 2, tasks => [map { { cmd => [$^X, '-e', 'open my $f, q{>}, $ARGV[0] or die; print $f $$; close $f; sleep 30', $_], quiet => 1 } } @ARGV])};
		my $child = fork();
		die "fork() failed: $!" if not defined $child;
		if ($child == 0) {
			open STDOUT, '>', File::Spec->devnull;
			open STDERR, '>', File::Spec->devnull;
			no warnings 'exec';
			# "or", not a statement after it: perl 5.10 and 5.12 warn
			# "Statement unlikely to be reached" despite the no warnings
			exec($^X, "-I$lib_dir", '-e', $code, @pid_files) or POSIX::_exit(127);
		}
		my @pids;
		foreach (1 .. 500) { # 10 s: see $RENDEZVOUS for the measurement
			@pids = grep { /\A[0-9]+\z/ } map { slurp($_) } @pid_files;
			last if scalar @pids == 2;
			Time::HiRes::sleep(0.02);
		}
		is(scalar @pids, 2, 'both steps started');
		my $sent = Time::HiRes::time();
		kill 'TERM', $child;
		waitpid $child, 0;
		my $took = Time::HiRes::time() - $sent;
		is($? & 127, POSIX::SIGTERM(), 'the calling program was ended by the TERM');
		# The steps would sleep for 30 s; passed the TERM, they end at once
		# (0.024-0.025 s here, three runs). Without it, parallel() waited them
		# out, and the steps were gone by the end anyway, so only the time
		# tells the two apart.
		cmp_ok($took, '<', 10, 'promptly, because the steps were ended, not waited out');
		my @alive = grep { kill 0, $_ } @pids;
		is(scalar @alive, 0, 'and no step outlived it');
		kill 'KILL', @alive if @alive;
	};
}

# --- report -------------------------------------------------------------------
subtest 'report: an HTML page from a trace' => sub {
	my $trace_file = fresh_path();
	open my $trace, '>', $trace_file or die;
	my $out = fresh_path();
	capture {
		# no double quote in the command, which MSWin32 would garble; the note has one
		task(cmd => [$^X, '-e', q{open my $f, '>', $ARGV[0] or die}, $out, '<b>&'], 'output.file' => $out,
			'trace.fh' => $trace, note => 'say "hi"', quiet => 1);
		task(cmd => [$^X, '-e', '1'], 'output.file' => $out, 'trace.fh' => $trace, quiet => 1);
		task(cmd => [$^X, '-e', 'exit 3'], 'trace.fh' => $trace, die => 0, quiet => 1);
	};
	close $trace;
	my $html_file = fresh_path() . '.html';
	my $count = report(trace => $trace_file, html => $html_file);
	is($count, 3, 'report() says how many tasks it read');
	my $html = slurp($html_file);
	like($html, qr/<title>[^<]+<\/title>/, 'the page has a title');
	like($html, qr/&lt;b&gt;&amp;/, 'a command is HTML-escaped');
	like($html, qr/say &quot;hi&quot;/, 'and so is a note');
	unlike($html, qr/<b>&|say "hi"/, 'and neither is written raw');
	like($html, qr/class="status">done<.*class="status">skipped<.*class="status">FAILED</s,
		'each task has its status, in order');
	like($html, qr/3 tasks: 1 done, 1 skipped, 1 failed/, 'and the summary counts them');
};
subtest 'report: a trace line that is not JSON is refused, naming the line' => sub {
	my $trace_file = fresh_path();
	open my $fh, '>', $trace_file or die;
	print {$fh} qq{{"cmd":"a","will.do":"done"}\n}, qq{not json\n};
	close $fh;
	my $error;
	capture { eval { report(trace => $trace_file, html => fresh_path()) }; $error = $@ };
	like($error, qr/line 2/, 'report() died naming line 2');
};
subtest "report: the trace reader reads what JSON::PP writes" => sub {
	my $value = {
		string => qq{quote " backslash \\ slash / tab \t newline \n bell \x07},
		unicode => "caf\x{e9} \x{263a} \x{1F600}",
		numbers => [0, -1, 3.25, 1.5e-7, 12345678901],
		literals => [JSON::PP::true(), JSON::PP::false(), undef],
		nested => { empty_array => [], empty_hash => {}, deep => [[{ a => 'b' }]] },
	};
	my $json = JSON::PP->new->utf8->canonical->encode($value);
	my $read = SimpleFlow::_json_decode($json);
	$value->{literals} = [1, 0, undef]; # true and false are read as 1 and 0
	is_deeply($read, $value, 'every JSON construct is read back as JSON::PP wrote it');
	my $ascii = JSON::PP->new->ascii->encode({ u => "\x{1F600}\x{e9}" });
	is_deeply(SimpleFlow::_json_decode($ascii), { u => "\x{1F600}\x{e9}" }, 'including \u escapes and surrogate pairs');
};

done_testing();
