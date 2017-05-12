use Signals::XSIG;
use Test::More tests => 81;
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
       SEGV SYS PIPE ALRM TERM URG XCPU XFSZ VTALRM PROF LOST
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

  my ($basic, $module, @unlink) = test_default_behavior_for_signal($signal);
  if (!ok_test_behavior($basic, $module, $signal)) {
    push @failed, $signal;
  }
  unlink @unlink if @unlink && @ARGV==0;
}

if (@failed && @ARGV == 0) {
  on_failure_recommend_spike(@failed);
}
