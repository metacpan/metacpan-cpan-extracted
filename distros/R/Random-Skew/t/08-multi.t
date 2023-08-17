# Testing Random::Skew

use strict;
use warnings;

use Random::Skew;

use Test::More;

Random::Skew::GRAIN( 30 );
my %config = (
    Much => 157,
    Lots => 122,
    Some => 53,
    Few  => 4,
    Rare => 1,
);



my $rs = Random::Skew->new(
    %config
);



my @v;

@v = $rs->items(3);
is( @v, 3, "items returned = 3" );

@v = $rs->items(2500);
is( @v, 2500, "items returned = 2500" );

my %v;
$v{$_}++ for @v;

is( scalar(keys %v), 5, "2500 iterations, 5 distinct items" );
ok( $v{Much} > $v{Lots}, "Large items proportional" );
ok( $v{Few} > $v{Rare}, "Small items proportional" );



done_testing( );
