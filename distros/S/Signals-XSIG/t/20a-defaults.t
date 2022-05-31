use Signals::XSIG;
use Test::More tests => 78;
use lib '.'; # 5.26 compatibility
use strict;
use warnings;
use POSIX ();
use Config;
eval { require Time::HiRes };

# running the default emulator of Signals::XSIG should produce the
# same behavior as not using Signals::XSIG
# t/20a: signals that usually terminate a program
#        gracefully or otherwise

# it takes a few seconds to test each signal
# so this is the most time consuming test.

require "t/20-defaults.tt";

my @failed = ();
my @signals 
  = qw(USR1 USR2 HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS
       SEGV SYS PIPE ALRM TERM XCPU XFSZ VTALRM PROF LOST
       STKFLT IOT BREAK FOO);

if (@ARGV > 0) {
    my $n = @signals;
    @signals = @ARGV;
    unshift @signals, '#' while @signals < $n;
}

foreach my $signal (@signals) {

    if (!exists $SIG{$signal} && !sig_exists($signal)) {
      SKIP: {
          skip "Signal $signal doesn't exist in $^O $]", 3;
        }
        next;
    }
    if ($^O eq 'MSWin32') {
        # having trouble sending some signals on MSWin32 without
        # aborting the whole test
      SKIP: {
	  skip "Skip terminating signals on MSWin32", 3;
	}
	next;
    }

    diag "signal = $signal" if $^O eq 'MSWin32';
    my ($basic, $module, @unlink) = test_default_behavior_for_signal($signal);
    if (!ok_test_behavior($basic, $module, $signal)) {
        push @failed, $signal;
    }
    unlink @unlink if @unlink && @ARGV==0;
}

if (@failed && @ARGV == 0) {
    no warnings 'once';
    diag "Failures detected with PAUSE_TIME=$main::PAUSE_TIME";
    diag "If these are intermittent failures, they might go away if you";
    diag "increase the pause time. Try";
    diag "";
    diag "     PAUSE_TIME=10 make test";
    diag "";
    on_failure_recommend_spike(@failed);
}

END {
    unlink glob("*.stackdump");
}
