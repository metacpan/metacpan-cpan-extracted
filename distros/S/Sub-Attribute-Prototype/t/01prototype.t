#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib "t";
use testmodule;

is( prototype( \&testmodule::func ), "&@", '&testmodule::func has correct prototype' );

is_deeply( [ testmodule::func { $_ == 2 } 1, 2, 3 ], [ 2 ],
   'Prototype on &testmodule::func was effective' );

done_testing;
