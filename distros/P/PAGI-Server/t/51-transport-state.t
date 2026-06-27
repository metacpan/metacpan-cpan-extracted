#!/usr/bin/env perl

# =============================================================================
# Test: PAGI::Server::TransportState
#
# The server-provided pagi.transport handle for outbound flow-control
# introspection: buffered_amount (bytes queued but not yet on the wire) and the
# high/low water marks. The handle measures via server-supplied source coderefs
# (measure/high/low/arm_drain) rather than reaching into a connection directly.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use Future;

require PAGI::Server::TransportState;

# A source drives the handle: $buf is the current buffered byte count, and
# arm_drain parks the drain-fire callback so the test can release it later via
# _drain (the analogue of the buffer falling below the low mark).
my $buf = 0;
my @drain_fires;

sub mk_ts {
    my %o = @_;
    $buf = $o{buf} // 0;
    @drain_fires = ();
    return PAGI::Server::TransportState->new(
        measure   => sub { $buf },
        high      => ($o{high} // 65536),
        low       => ($o{low}  // 16384),
        arm_drain => sub { push @drain_fires, shift },
    );
}

# Simulate the buffer draining below the low mark: zero it and fire the armed
# drain callbacks.
sub _drain {
    $buf = 0;
    (shift @drain_fires)->() while @drain_fires;
}

subtest 'buffered_amount reflects the source measure (live)' => sub {
    my $t = mk_ts(buf => 0);

    is($t->buffered_amount, 0, 'zero when drained');

    $buf = 4096;
    is($t->buffered_amount, 4096, 'reflects queued bytes on a live re-read');
};

subtest 'watermarks expose the backpressure band' => sub {
    my $t = mk_ts(high => 65536, low => 16384);

    is($t->high_water_mark, 65536, 'high_water_mark');
    is($t->low_water_mark,  16384, 'low_water_mark');
};

subtest 'graceful when the source reports nothing' => sub {
    my $t = PAGI::Server::TransportState->new(
        measure   => sub { undef },
        high      => undef,
        low       => undef,
        arm_drain => sub { },
    );

    is($t->buffered_amount, 0,     'buffered_amount is 0 when measure returns undef');
    is($t->high_water_mark, undef, 'high_water_mark undef without a source value');
    is($t->low_water_mark,  undef, 'low_water_mark undef without a source value');
};

subtest 'graceful with no source at all' => sub {
    my $t = PAGI::Server::TransportState->new;

    is($t->buffered_amount, 0,     'buffered_amount is 0 without a measure source');
    is($t->high_water_mark, undef, 'high_water_mark undef without a source');
    is($t->low_water_mark,  undef, 'low_water_mark undef without a source');
};

# =============================================================================
# Backpressure callbacks (on_high_water / on_drain) - hysteresis
# =============================================================================

subtest 'on_high_water fires once on crossing; on_drain after high->low' => sub {
    my $t = mk_ts(high => 100, low => 20, buf => 0);

    my ($high, $drain) = (0, 0);
    $t->on_high_water(sub { $high++ });
    $t->on_drain(sub { $drain++ });

    # Below the mark: nothing fires.
    $t->_check_watermarks;
    is([$high, $drain], [0, 0], 'nothing while below high mark');

    # Cross above the high mark.
    $buf = 150;
    $t->_check_watermarks;
    is([$high, $drain], [1, 0], 'on_high_water fired once on crossing');

    # Still above: edge-triggered, must not re-fire.
    $t->_check_watermarks;
    is([$high, $drain], [1, 0], 'on_high_water does not re-fire while above');

    # Drain below the low mark.
    _drain();
    is([$high, $drain], [1, 1], 'on_drain fired once after high->low');

    # Re-arms: crossing high again fires on_high_water again.
    $buf = 150;
    $t->_check_watermarks;
    is([$high, $drain], [2, 1], 'cycle re-arms');
};

subtest 'on_high_water registered while already above fires immediately' => sub {
    my $t = mk_ts(high => 100, low => 20, buf => 150);

    my $fired = 0;
    $t->on_high_water(sub { $fired++ });
    is($fired, 1, 'late registrant fires immediately when already above');
};

subtest 'on_drain does not fire on registration while below low' => sub {
    my $t = mk_ts(high => 100, low => 20, buf => 0);

    my $fired = 0;
    $t->on_drain(sub { $fired++ });
    is($fired, 0, 'on_drain only fires on an actual high->low transition');
};

subtest 'multiple callbacks fire in registration order' => sub {
    my $t = mk_ts(high => 100, low => 20, buf => 0);

    my @order;
    $t->on_high_water(sub { push @order, 'a' });
    $t->on_high_water(sub { push @order, 'b' });

    $buf = 150;
    $t->_check_watermarks;
    is(\@order, ['a', 'b'], 'high-water callbacks in registration order');
};

subtest 'a callback error does not break the others' => sub {
    my $t = mk_ts(high => 100, low => 20, buf => 0);

    my $second = 0;
    $t->on_high_water(sub { die "boom" });
    $t->on_high_water(sub { $second++ });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    $buf = 150;
    $t->_check_watermarks;

    is($second, 1, 'second callback still ran');
    like($warnings[0], qr/callback error/, 'warning emitted');
};

done_testing;
