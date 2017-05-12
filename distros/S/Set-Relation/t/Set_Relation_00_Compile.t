use 5.008001;
use utf8;
use strict;
use warnings;
use Carp::Always 0.01;

use Test::More 0.47;

use_ok( 'Set::Relation' );
is( $Set::Relation::VERSION, 0.013001,
    'Set::Relation is the correct version' );

use_ok( 'Set::Relation::V1' );
is( $Set::Relation::V1::VERSION, 0.013001,
    'Set::Relation::V1 is the correct version' );

use_ok( 'Set::Relation::V2' );
is( $Set::Relation::V2::VERSION, 0.013001,
    'Set::Relation::V2 is the correct version' );

done_testing();

1; # Magic true value required at end of a reusable file's code.
