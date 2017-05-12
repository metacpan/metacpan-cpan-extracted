use Test::More tests => 6;

use_ok( 'SecondLife::Vector' );

my $rot = SecondLife::Vector->new("<1.3,1.5,-3>");
is( "$rot", "<1.3, 1.5, -3>", "stringify");
is( $rot->x, 1.3, "x");
is( $rot->y, 1.5, "y");
is( $rot->z, -3, "z");

my $rot2 = SecondLife::Vector->new(x=>1.3, y=>1.5, z=>-3);
is( "$rot", "$rot2", "Alternative constructor syntax" );
