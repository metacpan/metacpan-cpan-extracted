
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all);

plan tests => 8;

my  $sbm = new Statistics::Basic::Median([1 .. 3]);

ok($sbm->query, 2);

$sbm->insert( 10 );
ok($sbm->query, 3);

$sbm->set_size( 5 );
ok($sbm->query, 2);

$sbm->ginsert( 9 );
ok($sbm->query, 2.5);

$sbm->set_vector( [2, 3 .. 5, 7, 0, 0] );
ok($sbm->query, 3);

my  $j = new Statistics::Basic::Median;
    $j->set_vector( [1 .. 3] );

ok($j->query, 2);

ok( median(6, 47, 49, 15, 42, 41, 7, 39, 43, 40, 36), 40   );
ok( median(7, 15, 36, 39, 40, 41),                    37.5 );
