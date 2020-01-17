#!/usr/bin/env perl

package t::mojo;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( EventTest );

use constant _BACKEND => 'Mojo';

#----------------------------------------------------------------------

__PACKAGE__->run();

#----------------------------------------------------------------------

sub _REQUIRE {
    require Mojo::IOLoop;
    die "Mojo::IOLoop lacks next_tick()." if !Mojo::IOLoop->can('next_tick');
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { Mojo::IOLoop->stop() } );

    Mojo::IOLoop->start();
}
