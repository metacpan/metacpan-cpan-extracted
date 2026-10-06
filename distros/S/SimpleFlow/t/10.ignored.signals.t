#!/usr/bin/env perl

#
# Signals that the caller, or the test harness itself, has ignored.
#
# A background job started by a non-interactive shell -- "( cpanm SimpleFlow
# & )" in a script -- begins with SIGINT and SIGQUIT ignored, as POSIX
# requires, and an ignored disposition is inherited across fork and exec, so
# the whole suite then runs with them ignored. On 2026-10-05 0.193 could not
# be installed that way: t/04.fixes.t test 15 sent INT to a child perl that
# had inherited INT ignored, and failed "the calling program was ended by the
# interrupt" (got 0, expected 2). The module was right to leave the signal
# ignored; four tests relied on a signal's default action without setting it,
# and 0.194 makes each set the default itself.
#
# The first part covers the promise that failure exercised by accident, which
# no test had set up on purpose: a signal the caller ignores stays ignored, by
# perl and, since it is inherited, by the command (the comment above
# _run_forked, and @interrupts there and in parallel()). It passed against
# 0.193, so it is coverage of existing behaviour, not a regression test.
#
# The second part is a regression test for a defect fixed in 0.194, which
# failed against 0.193: parallel(), with TERM ignored, did not pass an
# interrupt sent to its own process on to its steps. Its comment has the
# details.
#
# The third part re-runs every other t/*.t with HUP, INT, QUIT, TERM and TSTP
# inherited ignored, and asserts that each still passes, so that a test added
# later that relies on a default disposition fails here rather than on a
# user's background install. Run against 0.193's tests it failed t/01.t,
# t/04.fixes.t and t/06.pipeline.t, the files of the four tests 0.194 fixed.
# It doubles the time "prove -Ilib t/" takes, from 29 s to 57 s here (perl
# 5.44.0, 2026-10-05). Re-running only those three files took 8 s, but a test
# that needs a signal can as easily arrive in a new file as in an old one.
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
use File::Basename ();
use File::Spec;
use File::Temp ();
use FindBin ();
use POSIX ();
use Time::HiRes ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use NoDoubleQuote 'refuse_double_quotes'; # t/lib: what MSWin32 would garble in a list cmd
use SimpleFlow qw(task parallel);

plan skip_all => 'MSWin32 has no POSIX signals to ignore or inherit' if $^O eq 'MSWin32';

# The same copy of the module this file loaded, not whatever is installed.
(my $lib_dir = $INC{'SimpleFlow.pm'}) =~ s{[/\\]SimpleFlow\.pm$}{};

# Sends the signal named in $ARGV[0] to every pid after it, to its own parent
# and then to itself, and prints a sentinel only once it has lived through all
# of them.
my $SENDS_THEN_PRINTS = q{my $s = shift; kill $s, @ARGV, getppid; kill $s, $$; print q{survived}};

# Every record must show a command that ran to the end unharmed. The sentinel
# comes first: it is what shows the command ran at all.
sub lived_through {
	my ($t, $what) = @_;
	is($t->{stdout}, 'survived', "$what: the command lived to print its sentinel");
	is($t->{'will.do'}, 'done', "$what: the record is done");
	is($t->{'exit'}, 0, "$what: exit 0");
	is($t->{signal}, 0, "$what: signal 0");
	is($t->{'timed.out'}, 0, "$what: not timed out");
	return;
}

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or return '';
	local $/;
	return scalar <$fh>;
}

# --- 1. a signal the caller ignores stays ignored -----------------------------
# HUP, INT, QUIT and TERM are the four that task() and parallel() otherwise
# take over while a command runs. "timeout => 10" is headroom: the command's
# record gave a duration of 2-3 ms here (perl 5.10.1 and 5.44.0, three runs
# each, with and without the timeout), and the limit is only ever reached if a
# signal it sends is not ignored after all.
foreach my $sig (qw(HUP INT QUIT TERM)) {
	subtest "$sig ignored by the caller stays ignored, by perl and by the command" => sub {
		local $SIG{$sig} = 'IGNORE';
		foreach my $timeout (10, 0) {
			my $what = $timeout ? 'task() with a timeout' : 'task() with no timeout';
			my @args = (cmd => [$^X, '-e', $SENDS_THEN_PRINTS, $sig], timeout => $timeout, quiet => 1);
			refuse_double_quotes(@args);
			my ($t, $error);
			capture {
				$t = eval { task(@args) };
				$error = $@;
			};
			is($error, '', "$what: returned");
			lived_through($t, $what);
		}
		# Each step runs in a child of parallel()'s, so the command's parent is
		# that child, and this perl is named to it explicitly.
		my @tasks = map { +{ cmd => [$^X, '-e', $SENDS_THEN_PRINTS, $sig, $$], timeout => $_, quiet => 1 } } (10, 0);
		refuse_double_quotes(map { @{ $_->{cmd} } } @tasks);
		my (@records, $error);
		capture {
			@records = eval { parallel(jobs => 2, tasks => \@tasks) };
			$error = $@;
		};
		is($error, '', 'parallel(): returned');
		is(scalar @records, 2, 'parallel(): with both records');
		lived_through($records[0], 'parallel() with a timeout');
		lived_through($records[1], 'parallel() with no timeout');
	};
}

# --- 2. parallel(), interrupted while the caller ignores TERM -----------------
# A regression test. parallel() used to pass any interrupt on to its running
# steps as TERM, and its children, like the commands they ran, had inherited
# TERM ignored from a caller that ignored it. So an INT or a HUP sent to
# parallel()'s process alone -- by "kill", or a scheduler -- reached no step:
# each ran to its end, and only then was the interrupt re-raised. A Ctrl-C at
# the terminal was not affected, because it reaches parallel()'s children
# directly, so the signal here goes to the one pid. Against 0.193 each case
# took 30 s, the whole of the steps' sleep; with the steps passed the signal
# that parallel() received, 0.022-0.028 s here (perl 5.10.1 and 5.44.0,
# three runs each, 2026-10-05).
#
# Each step writes down its pid and how it found TERM, then sleeps. It sets
# the signal it is to die of to its default itself, since this file may have
# inherited it ignored, as a background job is started, and leaves TERM as it
# found it.
my $STEP = q{open my $f, q{>}, $ARGV[0] or die; print $f $$, q{ }, $SIG{TERM} || q{DEFAULT}; close $f; }
	. q{$SIG{INT} = $SIG{HUP} = q{DEFAULT}; sleep 30};
my $PARALLEL = q{use strict; use warnings FATAL => 'all'; use SimpleFlow 'parallel'; }
	. q{parallel(jobs => 2, tasks => [map { { cmd => [$^X, '-e', $ARGV[0], $_], quiet => 1 } } @ARGV[1 .. $#ARGV]])};
my $scratch = File::Temp::tempdir(CLEANUP => 1);
foreach my $sig (qw(INT HUP)) { # INT: not re-raised by task(); HUP: re-raised, as TERM is
	subtest "parallel(), ignoring TERM, passes an $sig sent to it alone on to its steps (0.193 waited them out)" => sub {
		my @pid_files = map { File::Spec->catfile($scratch, "$sig.$_") } 1, 2;
		my $child = fork();
		die "fork() failed: $!" if not defined $child;
		if ($child == 0) {
			open STDOUT, '>', File::Spec->devnull;
			open STDERR, '>', File::Spec->devnull;
			# The $sig must be able to end this child perl, and this file
			# may have inherited it ignored; a default disposition survives
			# exec, as does the ignored TERM that is the point of the test.
			$SIG{$_} = 'DEFAULT' foreach qw(HUP INT QUIT);
			$SIG{TERM} = 'IGNORE';
			no warnings 'exec';
			# "or", not a statement after it: perl 5.10 and 5.12 warn
			# "Statement unlikely to be reached" despite the no warnings
			exec($^X, "-I$lib_dir", '-e', $PARALLEL, $STEP, @pid_files) or POSIX::_exit(127);
		}
		my @steps;
		foreach (1 .. 500) { # 10 s: see $RENDEZVOUS in t/06.pipeline.t for the measurement
			@steps = grep { defined } map { (slurp($_) =~ /\A([0-9]+) (\S+)\z/) ? [$1, $2] : undef } @pid_files;
			last if scalar @steps == 2;
			Time::HiRes::sleep(0.02);
		}
		is(scalar @steps, 2, 'both steps started');
		is_deeply([map { $_->[1] } @steps], ['IGNORE', 'IGNORE'], 'each inherited TERM ignored');
		my $sent = Time::HiRes::time();
		kill $sig, $child;
		waitpid $child, 0;
		my $took = Time::HiRes::time() - $sent;
		is($? & 127, { INT => POSIX::SIGINT(), HUP => POSIX::SIGHUP() }->{$sig}, "the calling program was ended by the $sig");
		# Either way the steps are gone by the end, so only the time tells
		# the two apart: a limit of 10 s, against the 0.022-0.028 s measured
		# and the 30 s that 0.193 took.
		cmp_ok($took, '<', 10, "promptly, because the steps were passed the $sig (0.193 sent TERM, and waited 30 s)");
		my @alive = grep { kill 0, $_ } map { $_->[0] } @steps;
		is(scalar @alive, 0, 'and no step outlived it');
		kill 'KILL', @alive if @alive;
	};
}

# --- 3. the rest of the suite, with signals inherited ignored -----------------
my @INHERITED = qw(HUP INT QUIT TERM TSTP); # INT and QUIT: any background job; HUP: nohup

# Runs @command with @INHERITED ignored, as a background job would start it,
# and returns its (stdout, stderr, wait status). system() leaves the child
# what this perl had at the fork.
sub run_ignoring {
	my @command = @_;
	my ($out, $err, $status) = capture {
		local @SIG{@INHERITED} = ('IGNORE') x @INHERITED;
		system(@command);
		$?;
	};
	return ($out, $err, $status);
}

# Positive sentinel: the child really does start with every one of them
# ignored, so that the files below passing means something.
my ($seen) = run_ignoring($^X, '-e', q{print join q{,}, map { defined $SIG{$_} ? $SIG{$_} : q{undef} } @ARGV}, @INHERITED);
is($seen, join(',', ('IGNORE') x @INHERITED), "a child perl starts with @INHERITED ignored");

my $me = File::Basename::basename(__FILE__);
opendir my $t_dir, $FindBin::Bin or die "cannot read $FindBin::Bin: $!";
my @files = sort grep { /\.t\z/ && ($_ ne $me) } readdir $t_dir;
closedir $t_dir;
cmp_ok(scalar @files, '>=', 10, 'the other test files were found');
foreach my $file (@files) {
	my ($out, $err, $status) = run_ignoring($^X, "-I$lib_dir", File::Spec->catfile($FindBin::Bin, $file));
	like($out, qr/^1\.\.[1-9]/m, "$file ran its tests with @INHERITED inherited ignored");
	is($status, 0, "$file passed with @INHERITED inherited ignored")
		or diag("stdout:\n$out\nstderr:\n$err");
}

done_testing();
