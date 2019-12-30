#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::XS;

my $val;

my $deferred = Promise::XS::Deferred::create();
$deferred->resolve(42);

$deferred->promise()->then(
    sub { $val = shift },
);

is( $val, 42, 'simple synchronous execution' );

done_testing;

1;
