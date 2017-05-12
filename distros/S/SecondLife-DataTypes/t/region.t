use Test::More tests => 6;

use_ok( 'SecondLife::Region' );

my $region = SecondLife::Region->new( name=>"Dew Drop", x=>236544, y=>242944 );
is( "$region", "Dew Drop (236544, 242944)", "stringify" );
is( $region->name, "Dew Drop", "name" );
is( $region->x, 236544, "x" );
is( $region->y, 242944, "y" );

my $region2 = SecondLife::Region->new( "Dew Drop (236544, 242944)" );
is( "$region", "$region2", "parse from string" );
