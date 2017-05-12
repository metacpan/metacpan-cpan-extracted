
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic;

plan tests => 6;

my  $sbv = new Statistics::Basic::Variance([1 .. 3]);

ok( $sbv->query == (2/3) );

    $sbv->insert( 4 );
ok( $sbv->query == (2/3) );

    $sbv->set_size( 4 );
ok( $sbv->query == (35/16) );

    $sbv->set_vector( [5 .. 7] );
ok( $sbv->query == (2/3) );

    $sbv->ginsert( 8 );
ok( $sbv->query == (5/4) );

my  $j = new Statistics::Basic::Variance;
    $j->set_vector([1 .. 3]);
ok( $j->query == (2/3) );
