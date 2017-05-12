
use strict;
use warnings;
use Test::More tests => 27;

BEGIN {
    use_ok('AnyEvent::Strict');
    use_ok('Test::AnyEvent::Time');
}

my $DEFAULT_MARGIN = 0.1;

sub around_ok {
    my ($got_time, $exp_time, $margin) = @_;
    $margin ||= $DEFAULT_MARGIN;
    ok(defined($got_time), "not timed out");
    cmp_ok($got_time, "<=", $exp_time + $margin);
    cmp_ok($got_time, ">=", $exp_time - $margin);
}

sub delay_cb {
    my ($delay) = @_;
    return sub {
        my $cv = shift;
        my $w; $w = AnyEvent->timer(
            after => $delay,
            cb => sub {
                undef $w;
                $cv->send();
            }
        );
    };
}

sub delays_cb {
    my (@delays) = @_;
    return sub {
        my $cv = shift;
        foreach my $delay (@delays) {
            $cv->begin();
            my $w; $w = AnyEvent->timer(
                after => $delay,
                cb => sub {
                    undef $w;
                    $cv->end();
                }
            );
        }
    };
}

around_ok(elapsed_time(delay_cb(2), 10), 2);
around_ok(elapsed_time(delay_cb(0.9), 10), 0.9);
around_ok(elapsed_time(delays_cb(0.9, 0.4, 0.1, 0.3, 0.5), 10), 0.9);
around_ok(elapsed_time(delay_cb(2.8)), 2.8);
around_ok(elapsed_time(delay_cb(0)), 0);
around_ok(elapsed_time(delays_cb(0.2, 0.4, 0, 1.2, 0.1, 0.8)), 1.2);

## elapsed_time(sub {});  # NEVER do that. It blocks forever.

cmp_ok(elapsed_time(delay_cb(10), 1), "<", 0, "timed out (too long delay)");
cmp_ok(elapsed_time(sub { }, 1), "<", 0, "timed out (noop callback)");
cmp_ok(elapsed_time(delay_cb(1), 0), "<", 0, "timed out (zero timeout)");
cmp_ok(elapsed_time(delays_cb(1, 2, 3, 4, 5), 0), '<', 0, 'timed out (zero timeout)');
cmp_ok(elapsed_time(delays_cb(0.4, 0.2, 0, 1.8, 2.2, 0.9, 0.4, 0.6, 1.1), 1.4), '<', 0, 'timed out (in the middle of events)');

ok(!defined(elapsed_time(1)), "error (null callback)");
ok(!defined(elapsed_time()), "error (null argument)");



