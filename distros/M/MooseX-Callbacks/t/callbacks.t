#!/usr/bin/env perl

use Test::More tests => 5;
use strict;
use warnings;

BEGIN {
    use_ok( 'MooseX::Callbacks' ) || print "Bail out!\n";
}

sub run_tests {
    my $obj = bless({}, "CallbackTest");

    my $event_1_fired = 0;
    my $event_2_fired = 0;
    $obj->register_callbacks(
        event1 => sub {
            $event_1_fired++;
        },
        event2 => sub {
            is_deeply(\@_, [ 1, 2, 3 ], "Got callback args");
            $event_2_fired++;
        },
    );

    $obj->dispatch('event1', 1, 2, 3);
    $obj->dispatch('event1');
    $obj->dispatch('event2', 1, 2, 3);
    $obj->dispatch('event2', 1, 2, 3);

    is($event_1_fired, 2, "Received callbacks");
    is($event_2_fired, 2, "Received callbacks");
}

run_tests();

####

package CallbackTest;

use Moose;
BEGIN { with 'MooseX::Callbacks'; }

1;
