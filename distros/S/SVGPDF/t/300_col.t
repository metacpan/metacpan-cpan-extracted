#! perl

use Test::More tests => 22;
use SVGPDF::Colour;

# By name.
is( c1( "red"   )->rgb, "#FF0000" );
is( c1( "lime"  )->rgb, "#00FF00" );
is( c1( "blue"  )->rgb, "#0000FF" );

# By components.
is( c3( 255,0,0 )->rgb, "#FF0000" );
is( c3( 0,255,0 )->rgb, "#00FF00" );
is( c3( 0,0,255 )->rgb, "#0000FF" );

# Hex.
is( c1( "#FF0000" )->rgb, "#FF0000" );
is( c1( "#00ff00" )->rgb, "#00FF00" );
is( c1( "#0000Ff" )->rgb, "#0000FF" );

# RGB (values).
is( c1( "rgb(255,0,0)" )->rgb, "#FF0000" );
is( c1( "rgb(0,255,0)" )->rgb, "#00FF00" );
is( c1( "rgb(0,0,255)" )->rgb, "#0000FF" );

# RGB (percentage).
is( c1( "rgb(100%,0,0)" )->rgb, "#FF0000" );
is( c1( "rgb(0,100%,0)" )->rgb, "#00FF00" );
is( c1( "rgb(0,0,100%)" )->rgb, "#0000FF" );

# RGB (fractional percentage).
is( c1( "rgb(100.0%,0,0)" )->rgb, "#FF0000" );
is( c1( "rgb(0,100.0%,0)" )->rgb, "#00FF00" );
is( c1( "rgb(0,0,100.0%)" )->rgb, "#0000FF" );

# Individual components.
is( c( red   => 255 )->rgb, "#FF0000" );
is( c( green => 255 )->rgb, "#00FF00" );
is( c( blue  => 255 )->rgb, "#0000FF" );

# Colour component override.
is( c( colour => "rgb(10,2,16)", green => 4 )->rgb, "#0A0410" );

# Helpers.
sub c { SVGPDF::Colour->new(@_) };
sub c1 { SVGPDF::Colour->new( colour => $_[0]) };
sub c3 { SVGPDF::Colour->new( red => $_[0], green => $_[1], blue => $_[2] ) };

