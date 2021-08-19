#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::XS;

use Errno;

my $enoent_str = do { local $! = Errno::ENOENT; "$!" };

my $val;

my $dualvar = do { local $! = Errno::ENOENT };

my $deferred = Promise::XS::Deferred::create();
$deferred->resolve($dualvar);

$deferred->promise()->then(
    sub { $val = shift },
);

is( 0 + $val, Errno::ENOENT, 'resolve dualvar - number' );
is( "$val", $enoent_str, 'resolve dualvar - string' );

#----------------------------------------------------------------------

$deferred = Promise::XS::Deferred::create();
$deferred->reject($dualvar);

$deferred->promise()->catch(
    sub { $val = shift },
);

is( 0 + $val, Errno::ENOENT, 'reject dualvar - number' );
is( "$val", $enoent_str, 'reject dualvar - string' );

done_testing;

1;
