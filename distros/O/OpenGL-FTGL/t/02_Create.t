# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OpenGL-FTGL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 22 };
use OpenGL ':all';
use OpenGL::FTGL ':all';
ok(1); # If we made it this far, we're ok.

#########################

my $font1 = ftglCreateBitmapFont("./t/FreeSansBold.xxx");
ok( ! defined $font1 );

$font1 = ftglCreateBitmapFont("./t/FreeSansBold.otf");
ok( defined $font1 );
isa_ok( $font1, 'FTGLfontPtr' );

#########################

my $font2 = ftglCreatePixmapFont("./t/FreeSansBold.xxx");
ok( ! defined $font2 );

$font2 = ftglCreatePixmapFont("./t/FreeSansBold.otf");
ok( defined $font2 );
isa_ok( $font2, 'FTGLfontPtr' );

#########################

my $font3 = ftglCreateOutlineFont("./t/FreeSansBold.xxx");
ok( ! defined $font3 );

$font3 = ftglCreateOutlineFont("./t/FreeSansBold.otf");
ok( defined $font3 );
isa_ok( $font3, 'FTGLfontPtr' );

#########################

my $font4 = ftglCreatePolygonFont("./t/FreeSansBold.xxx");
ok( ! defined $font4 );

$font4 = ftglCreatePolygonFont("./t/FreeSansBold.otf");
ok( defined $font4 );
isa_ok( $font3, 'FTGLfontPtr' );

#########################

my $font5 = ftglCreateExtrudeFont("./t/FreeSansBold.xxx");
ok( ! defined $font5 );

$font5 = ftglCreateExtrudeFont("./t/FreeSansBold.otf");
ok( defined $font5 );
isa_ok( $font5, 'FTGLfontPtr' );

#########################

my $font6 = ftglCreateTextureFont("./t/FreeSansBold.xxx");
ok( ! defined $font6 );

$font6 = ftglCreateTextureFont("./t/FreeSansBold.otf");
ok( defined $font6 );
isa_ok( $font6, 'FTGLfontPtr' );

#########################

my $font7 = ftglCreateBufferFont("./t/FreeSansBold.xxx");
ok( ! defined $font7 );

$font7 = ftglCreateBufferFont("./t/FreeSansBold.otf");
ok( defined $font7 );
isa_ok( $font7, 'FTGLfontPtr' );







