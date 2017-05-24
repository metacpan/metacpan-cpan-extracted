use Signals::XSIG;
use Test::More tests => 18;
use strict;
use warnings;
use POSIX ();
use Config;
eval { require Time::HiRes };

# running the default emulator of Signals::XSIG should produce the
# same behavior as not using Signals::XSIG
# t/20c: signals that are usually ignored

require "t/20-defaults.tt";

my @failed = ();
my @signals = qw(IO URG POLL CHLD CLD WINCH);

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
