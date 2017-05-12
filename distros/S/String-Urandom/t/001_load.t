# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/001_load.t - check module loading

use Test::More;

BEGIN { use_ok('String::Urandom') }

ok 1;

my $obj = new String::Urandom;

isa_ok( $obj, 'String::Urandom' );

done_testing();
