use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';
use Carp::Always 0.09;

use Test::More 0.92;

use_ok( 'Muldis::Rosetta' );
is( $Muldis::Rosetta::VERSION, 0.016000,
    'Muldis::Rosetta is the correct version' );

use_ok( 'Muldis::Rosetta::Interface' );
is( $Muldis::Rosetta::Interface::VERSION, 0.016000,
    'Muldis::Rosetta::Interface is the correct version' );

use_ok( 'Muldis::Rosetta::Validator' );
is( $Muldis::Rosetta::Validator::VERSION, 0.016000,
    'Muldis::Rosetta::Validator is the correct version' );

use_ok( 'Muldis::Rosetta::Engine::Example' );
is( $Muldis::Rosetta::Engine::Example::VERSION, 0.016000,
    'Muldis::Rosetta::Engine::Example is the correct version' );

done_testing();

1; # Magic true value required at end of a reusable file's code.
