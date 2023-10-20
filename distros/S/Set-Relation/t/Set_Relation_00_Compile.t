use 5.008000;
use utf8;
use strict;
use warnings;

use Test::More 0.92;

use_ok( 'Set::Relation' );
is( $Set::Relation::VERSION, 0.013004,
    'Set::Relation is the correct version' );

use_ok( 'Set::Relation::V1' );
is( $Set::Relation::V1::VERSION, 0.013004,
    'Set::Relation::V1 is the correct version' );

use_ok( 'Set::Relation::V2' );
is( $Set::Relation::V2::VERSION, 0.013004,
    'Set::Relation::V2 is the correct version' );

done_testing();

1;
