# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OpenGL-FTGL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 10 };
use OpenGL ':all';
use OpenGL::Image;
use OpenGL::FTGL ':all';

my ($pixfont, $font, $ofont, $pfont, $efont, $efont2);
my $texture;
my $delay = 2000;
my $info = "Outline font";
my $mode = FTGL_RENDER_ALL;

sub LoadGLTexture {    # Load Bitmap And Convert To Texture
  my $file = shift;
  my $tex = new OpenGL::Image( source => $file ) or return undef;
  $texture = glGenTextures_p(1);    # Create The Texture
  return undef unless $tex->IsPowerOf2();
  glBindTexture( GL_TEXTURE_2D, $texture );
  my ( $ifmt, $fmt, $type ) =
    $tex->Get( 'gl_internalformat', 'gl_format', 'gl_type' );
  my ( $w, $h ) = $tex->Get( 'width', 'height' );
  glTexImage2D_c( GL_TEXTURE_2D, 0, $ifmt, $w, $h, 0, $fmt, $type,
    $tex->Ptr() );
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
  return 1;
}

sub RenderScene {
  my $now = glutGet(GLUT_ELAPSED_TIME);

  my $n = $now / 20.0;
  my $t1 = sin($n / 80.0);
  my $t2 = sin($n / 50.0 + 1.0);
  my $t3 = sin($n / 30.0 + 2.0);

  my @ambient = ( ($t1 + 2.0) / 3.0, ($t2 + 2.0) / 3.0, ($t3 + 2.0) / 3.0, 0.3 );
  my @diffuse = ( 1.0, 0.9, 0.9, 1.0 );
  my @specular = ( 1.0, 0.7, 0.7, 1.0 );
  my @position = ( 100.0, 100.0, 0.0, 1.0 );

  my @front_ambient = ( 0.7, 0.7, 0.7, 0.0 );

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);

  glPushMatrix();
    glTranslatef(-0.9, -0.2, -10.0);
    glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @ambient);
    glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @diffuse);
    glLightfv_p(GL_LIGHT1, GL_SPECULAR, @specular);
    glLightfv_p(GL_LIGHT1, GL_POSITION, @position);
    glEnable(GL_LIGHT1);
  glPopMatrix();

  glPushMatrix();
    glMaterialfv_p(GL_FRONT, GL_AMBIENT, @front_ambient);
    glColorMaterial(GL_FRONT, GL_DIFFUSE);
    glTranslatef(0.0, 0.0, 20.0);
    glRotatef($n / 1.11, 0.0, 1.0, 0.0);
    glRotatef($n / 2.23, 1.0, 0.0, 0.0);
    glRotatef($n / 3.17, 0.0, 0.0, 1.0);
    glTranslatef(-260.0, -0.2, 0.0);
    glBindTexture( GL_TEXTURE_2D, $texture );
    ftglRenderFont($font, "Hello FTGL!", $mode);
  glPopMatrix();
  
  glRasterPos2f(-400, -300);
  ftglRenderFont($pixfont, $info);

  glutSwapBuffers();
}

sub Exit {
  my $step = shift;
  if ($step == 0) {
    ok(1);
    $info = "Polygon font";
    $font = $pfont;
    glutTimerFunc($delay, \&Exit, 1);
  }
  elsif ($step == 1) {
    ok(1);
    $info = "Polygon font + texture";
    $font = $pfont;
    glEnable(GL_TEXTURE_2D);
    glutTimerFunc($delay, \&Exit, 2);
  }
  elsif ($step == 2) {
    ok(1);
    $info = "Extrude font";
    $font = $efont;
    glDisable(GL_TEXTURE_2D);
    glutTimerFunc($delay, \&Exit, 3);
  }
  elsif ($step == 3) {
    ok(1);
    $info = "Extrude font + texture";
    $font = $efont;
    glEnable(GL_TEXTURE_2D);
    glutTimerFunc($delay, \&Exit, 4);
  }
  elsif ($step == 4) {
    ok(1);
    $info = "Extrude font + texture FTGL_RENDER_FRONT";
    $font = $efont;
    $mode = FTGL_RENDER_FRONT;
    glutTimerFunc($delay, \&Exit, 5);
  }
  elsif ($step == 5) {
    ok(1);
    $info = "Extrude font + texture FTGL_RENDER_FRONT | FTGL_RENDER_BACK";
    $font = $efont;
    $mode = FTGL_RENDER_FRONT | FTGL_RENDER_BACK;
    glutTimerFunc($delay, \&Exit, 6);
  }
  elsif ($step == 6) {
    ok(1);
    $info = "Extrude font + texture FTGL_RENDER_FRONT | FTGL_RENDER_SIDE";
    $font = $efont;
    $mode = FTGL_RENDER_FRONT | FTGL_RENDER_SIDE;
    glutTimerFunc($delay, \&Exit, 7);
  }
  elsif ($step == 7) {
    ok(1);
    $info = "Extrude font + texture FTGL_RENDER_SIDE";
    $font = $efont;
    $mode = FTGL_RENDER_SIDE;
    glutTimerFunc($delay, \&Exit, 8);
  }
  elsif ($step == 8) {
    ok(1);
    $info = "Extrude font + texture Outset(5, 10 )";
    $font = $efont2;
    $mode = FTGL_RENDER_ALL;
    glutTimerFunc($delay, \&Exit, 9);
  }
  else {
  glutDestroyWindow(glutGetWindow());
  ok(1);
  }
}

# Initialise GLUT stuff
glutInit();
glutInitDisplayMode(GLUT_DEPTH | GLUT_DOUBLE | GLUT_RGBA);
glutInitWindowPosition(100, 100);
glutInitWindowSize(640, 480);
glutCreateWindow("Test OpenGL::FTGL");
glutDisplayFunc(\&RenderScene);
glutIdleFunc(\&RenderScene);
glutTimerFunc($delay, \&Exit, 0);

# Initialise GL stuff
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluPerspective(90, 640.0 / 480.0, 1, 1000);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();
gluLookAt(0.0, 0.0, 640.0 / 2.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

LoadGLTexture("./t/stone.tga") or die $!;

# Initialise FTGL stuff
$pixfont = ftglCreatePixmapFont("./t/FreeSansBold.otf") or die $!;
ftglSetFontFaceSize($pixfont, 12);

$ofont = ftglCreateOutlineFont("./t/FreeSansBold.otf") or die $!;
ftglSetFontFaceSize($ofont, 80);
$font = $ofont;

$pfont = ftglCreatePolygonFont("./t/FreeSansBold.otf") or die $!;
ftglSetFontFaceSize($pfont, 80);

$efont = ftglCreateExtrudeFont("./t/FreeSansBold.otf") or die $!;
ftglSetFontFaceSize($efont, 80);
ftglSetFontDepth($efont, 16);

$efont2 = ftglCreateExtrudeFont("./t/FreeSansBold.otf") or die $!;
ftglSetFontFaceSize($efont2, 80);
ftglSetFontDepth($efont2, 32);
ftglSetFontOutset($efont2, 5, 10 );

glutMainLoop();

__END__