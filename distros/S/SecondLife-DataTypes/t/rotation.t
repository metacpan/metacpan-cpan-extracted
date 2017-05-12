use Test::More tests => 9;

use_ok( 'SecondLife::Rotation' );

my $rot = SecondLife::Rotation->new("<1.3,1.5,-3,1>");
is( "$rot", "<1.3, 1.5, -3, 1>", "stringify");
is( $rot->x, 1.3, "x");
is( $rot->y, 1.5, "y");
is( $rot->z, -3, "z");
is( $rot->s, 1, "s");

my $rot2 = SecondLife::Rotation->new(x=>1.3,y=>1.5,z=>-3,s=>1);
is( "$rot2", "$rot", "Moose style constructor" );

my $rot3 = SecondLife::Rotation->new( Math::Quaternion->new( 1,1.3,1.5,-3 ) );
is( "$rot3", "$rot", "Math::Quaternion object" );

my $rot4 = SecondLife::Rotation->new({axis=>[0,1,0],angle=>0.1});
is( "$rot4", "<0, 0.0499791692706783, 0, 0.998750260394966>", "Math::Quaternion constructor" );

