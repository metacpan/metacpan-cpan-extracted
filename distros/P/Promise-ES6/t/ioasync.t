#!/usr/bin/env perl

package t::mojo;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( EventTest );

my ($LOOP, $LOOP_GUARD);

__PACKAGE__->run();

use constant _BACKEND => 'IOAsync';

use Promise::ES6::IOAsync;

sub _REQUIRE {
    require IO::Async::Loop;
    require Promise::ES6::IOAsync;

    $LOOP = IO::Async::Loop->new();
    $LOOP_GUARD = Promise::ES6::IOAsync::SET_LOOP($LOOP);

    1;
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { $LOOP->stop() } );

    $LOOP->run();
}
