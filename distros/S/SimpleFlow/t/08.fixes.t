#!/usr/bin/env perl

#
# Regression tests for the defects fixed in 0.20. Each block names the
# behaviour that was wrong before, so that a re-break is recognisable from the
# failure message alone.
#
# Both blocks were confirmed to FAIL against 0.19 (the release, as committed
# in a83401e) before the fix went in, on perl 5.44.0 and 5.10.1. They use no
# argument 0.19 did not accept; "quiet" and "timeout" make them 0.16 or later.
#
# The defect: a signal that reached task()'s process after the command had
# been exec'd, but before _run_forked had installed its handlers, went to the
# caller's handler alone. The command was neither killed nor passed the
# signal, ran to its end, and came back as done. A CPAN smoker (perl 5.16.3 on
# Alpine, 2026-09-27) lost that race in t/07.coverage.t, whose command sends
# the signal as soon as it starts.
#
# A test cannot win or lose that race on demand by timing, so the signal is
# sent from inside the window itself: between the exec and the handlers,
# _run_forked reads $SIG{HUP} to see whether the caller ignores it, and a
# blessed handler whose "eq" is overloaded runs code at exactly that point.
# Its only effect is the kill; it compares as unequal to 'IGNORE', as a plain
# code ref would.
#
# The command is a list run by $^X, as in t/04.fixes.t. Unkilled it sleeps
# for 5 s, which is what 0.19 waited out; killed, it never gets that far.
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
use POSIX ();
use SimpleFlow qw(task);

{
	package InTheWindow;
	our $fired = 0; # how many times the comparison has sent the signal
	use overload 'eq' => sub { $fired++; kill 'TERM', $$; return 0 }, fallback => 1;
}

SKIP: {
	skip 'needs POSIX signals and a real fork()', 2 if $^O eq 'MSWin32';
	foreach my $timeout (0, 30) {
		my $how = $timeout ? 'a timed step (its own process group)' : 'an untimed step';
		subtest "a TERM that arrives just after the exec, during $how, still ends the command (0.19 let it run on as done)" => sub {
			my $caught = 0;
			local $SIG{TERM} = sub { $caught++ };
			local $SIG{HUP} = bless sub {}, 'InTheWindow';
			local $InTheWindow::fired = 0;
			my ($t, $error);
			my (undef, $err) = capture {
				$t = eval { task(cmd => [$^X, '-e', 'sleep 5'], timeout => $timeout, die => 0, quiet => 1) };
				$error = $@;
			};
			is($error, '', 'task() returned');
			# the sentinel: without it, what follows would pass if no signal were sent
			cmp_ok($InTheWindow::fired, '>=', 1, 'the signal was sent from inside the window');
			is($t->{'will.do'}, 'FAILED', 'the step failed (0.19: done, having waited the command out)');
			# untimed, the command is passed the same signal; timed, its whole group is killed
			is($t->{signal}, $timeout ? POSIX::SIGKILL() : POSIX::SIGTERM(),
				'the command died of the signal (0.19: 0, it was never sent one)');
			like($err, qr/was killed when task\(\) received SIGTERM/, 'the warning says what happened');
			is($caught, 1, "the signal still reached the caller's own handler, once");
		};
	}
}

done_testing();
