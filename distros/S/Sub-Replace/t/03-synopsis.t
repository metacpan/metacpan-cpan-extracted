
use Test::More;

use Sub::Replace;

sub one {'One'}

is( one(), 'One' );

BEGIN {
    Sub::Replace::sub_replace( 'one', sub {'Uno'} );
}

is( one(), 'Uno' );

BEGIN {
    Sub::Replace::sub_replace( 'one', sub {'Eins'} );
}

is( one(), 'Eins' );

done_testing;
