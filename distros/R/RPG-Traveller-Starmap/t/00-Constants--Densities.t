use Test::More tests => 5;
use RPG::Traveller::Starmap::Constants qw/ :densities /;
use strict;
{
    ok( RIFT == 1, "Rift Test" );
}
{
    ok( SPARSE == 2, "Sparse Test" );
}
{
    ok( SCATTERED == 3, "Scattered Test" );
}
{
    ok( NORMAL == 4, "Normal Test" );
}
{
    ok( DENSE == 5, "Dense Test" );
}

