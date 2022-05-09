use Signals::XSIG;
use Test::More tests => 15;
use strict;
use warnings;
use POSIX ();
use Config;
eval { require Time::HiRes };

# running the default emulator of Signals::XSIG should produce the
# same behavior as not using Signals::XSIG
# t/20b: signals that usually suspend or resume a process
#

require "t/20-defaults.tt";

my @failed = ();
my @signals = qw(STOP TSTP TTIN TTOU CONT);

if (@ARGV > 0) {
    my $n = @signals;
    @signals = @ARGV;
    unshift @signals, '#' while @signals < $n;
}

foreach my $signal (@signals) {

  SKIP: {
      if (!exists $SIG{$signal} && !sig_exists($signal)) {
          skip "Signal $signal doesn't exist in $^O $]", 3;
      }
  
      my ($basic, $module, @unlink) = test_default_behavior_for_signal($signal);

      if ($basic->{xpid} != 0 && $module->{xpid} == 0
          && $Signals::XSIG::Default::DEFAULT_BEHAVIOR{$signal} eq 'SUSPEND') {

          push @failed, $signal;
          diag "expected $^O to suspend on SIG$signal, but it didn't";
          skip "expected $^O to suspend on SIG$signal, but it didn't", 3;

      }
      if (!ok_test_behavior($basic, $module, $signal)) {
          push @failed, $signal;
      }
      unlink @unlink if @unlink && @ARGV==0;
    }
}

if (@failed && @ARGV == 0) {
    on_failure_recommend_spike(@failed);
}
