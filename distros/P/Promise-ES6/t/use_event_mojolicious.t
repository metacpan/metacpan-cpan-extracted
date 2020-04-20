#!/usr/bin/env perl

package t::use_event_mojolicious;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( UseEventTest );

__PACKAGE__->run();

use constant _BACKEND => 'Mojo::IOLoop';

sub _REQUIRE {
    require Mojo::IOLoop;
    die "Mojo::IOLoop lacks next_tick()." if !Mojo::IOLoop->can('next_tick');
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { Mojo::IOLoop->stop() } );

    Mojo::IOLoop->start();
}

1;
