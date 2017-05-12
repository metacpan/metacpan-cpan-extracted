# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OpenGL-FTGL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 30 };
use OpenGL ':all';
use OpenGL::FTGL ':all';

my $bfont = ftglCreateBitmapFont("./t/FreeSansBold.otf")
  or die $!;
my $success = ftglSetFontFaceSize($bfont, 12);
ok( $success );
ok( ftglGetFontError($bfont) == 0 );
ok( ftglGetFontFaceSize($bfont) == 12 );

$success = ftglSetFontCharMap ( $bfont, FT_ENCODING_MS_SYMBOL );
ok( !$success );

$success = ftglSetFontCharMap ( $bfont, FT_ENCODING_UNICODE );
ok( $success );

my $pfont = ftglCreatePixmapFont("./t/FreeSansBold.otf")
  or die $!;
$success = ftglSetFontFaceSize($pfont, 16);
ok( $success );
ok( ftglGetFontError($pfont) == 0 );
ok( ftglGetFontFaceSize($pfont) == 16 );

my @map  = ftglGetFontCharMapList($bfont);
ok( $map[0] == FT_ENCODING_UNICODE );
ok( $map[1] == FT_ENCODING_APPLE_ROMAN );
ok( $map[2] == FT_ENCODING_UNICODE );
ok( $map[3] == FT_ENCODING_ADOBE_STANDARD );

my @bb = ftglGetFontBBox ( $bfont, "AbcWdefq" );

ok( $bb[0] == 0.125 );
ok( $bb[1] == -2 );
ok( $bb[2] == 0 );
ok( $bb[3] == 58.84375 );
ok( $bb[4] == 9 );
ok( $bb[5] == 0 );

@bb = ftglGetFontBBox ( $bfont, "AbcWdefq", 4 );

ok( $bb[0] == 0.125 );
ok( $bb[1] == 0 );
ok( $bb[2] == 0 );
ok( $bb[3] == 33.046875 );
ok( $bb[4] == 9 );
ok( $bb[5] == 0 );

ok( ftglGetFontAdvance ( $bfont, "AbcWdefq" ) == 59 );
ok( ftglGetFontAscender( $bfont ) == 11 );
ok( ftglGetFontDescender( $bfont ) == -3 );
# == 18.3120002746582
ok( ftglGetFontLineHeight($bfont) > 18.312 );
ok( ftglGetFontLineHeight($bfont) < 18.313 );

sub display {
  glClear(GL_COLOR_BUFFER_BIT);         #clear the window 
  glRasterPos2f(-0.95, 0.5);
  ftglSetFontFaceSize($bfont, 48)
    or die ftglGetFontErrorMsg ($bfont) ;
  ftglRenderFont($bfont, "BitMapFont example");
  
  ftglSetFontFaceSize($bfont, 24)
    or die ftglGetFontErrorMsg ($bfont) ;
  glRasterPos2f(-0.95, 0.2);
  ftglRenderFont($bfont, "24 points");
  
  glRasterPos2f(-0.95, -0.2);
  ftglSetFontFaceSize($pfont, 48)
    or die ftglGetFontErrorMsg ($pfont) ;
  ftglRenderFont($pfont, "PixMapFont example");
  
  ftglSetFontFaceSize($pfont, 32)
    or die ftglGetFontErrorMsg ($pfont) ;
  glRasterPos2f(-0.95, -0.8);
  ftglRenderFont($pfont, "32 points", FTGL_RENDER_ALL);
  
  glFlush(); 
}

sub Exit {
  glutDestroyWindow(glutGetWindow());
  ok(1);
}

# Standard GLUT initialization 
glutInit();
glutInitWindowSize(500,500);      # 500 x 500 pixel window 
glutCreateWindow("OpenGL::FTGL"); # window title 
glutDisplayFunc(\&display);
glutTimerFunc(2000, \&Exit, 0);

# Initialisation
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluOrtho2D(-1.0, 1.0, -1.0, 1.0);
glMatrixMode(GL_MODELVIEW);

glutMainLoop();

__END__





