#!/usr/bin/env perl

package t::use_event_ioasync;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( UseEventTest );

my ($LOOP);

__PACKAGE__->run();

use constant _BACKEND => 'IOAsync';

sub _REQUIRE_BACKEND {
    Promise::ES6::use_event( 'IO::Async', $LOOP );
}

sub _REQUIRE {
    require IO::Async::Loop;

    $LOOP = IO::Async::Loop->new();
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { $LOOP->stop() } );

    $LOOP->run();
}

1;
