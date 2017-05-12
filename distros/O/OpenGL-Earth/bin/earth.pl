#!/usr/bin/env perl
#
# OpenGL texture-mapped Earth
# 08/12/2008 <cosimo@cpan.org>
#
# -----------------------------------------------------------------
# Originally based on OpenGL cube demo written by
# Chris Halsall (chalsall@chalsall.com) for the
# O'Reilly Network on Linux.com (oreilly.linux.com).
# May 2000.
#
# Released into the Public Domain; do with it as you wish.
# We would like to hear about interesting uses.
#
# Translated from C to Perl by J-L Morel <jl_morel@bribes.org>
# (http://www.bribes.org/perl/wopengl.html)
#

BEGIN { $| = 1 }

use strict;
use lib '../lib';

use OpenGL q(:all);
use OpenGL::Earth;
use OpenGL::Earth::Coords;
use OpenGL::Earth::Physics;
use OpenGL::Earth::Render;
use OpenGL::Earth::Scene;
use OpenGL::Earth::Wiimote;

use constant PROGRAM_TITLE => 'OpenGL Earth';

# ------
# Callback function called when a normal $key is pressed.

sub cbKeyPressed {
    my $key = shift;
    my $c   = uc chr $key;
    if ( $key == 27 or $c eq 'Q' ) {
        glutDestroyWindow($OpenGL::Earth::WINDOW_ID);
        exit(1);
    }
    elsif ( $c eq 'B' ) {    # B - Blending.
        $OpenGL::Earth::BLEND_ON = $OpenGL::Earth::BLEND_ON ? 0 : 1;
        if ( !$OpenGL::Earth::BLEND_ON ) {
            glDisable(GL_BLEND);
        }
        else {
            glEnable(GL_BLEND);
        }
    }
    elsif ( $c eq 'L' ) {    # L - Lighting
        $OpenGL::Earth::LIGHT_ON = $OpenGL::Earth::LIGHT_ON ? 0 : 1;
    }
    elsif ( $c eq 'M' ) {    # M - Mode of Blending
        if ( ++$OpenGL::Earth::TEXTURE_MODE > 3 ) {
            $OpenGL::Earth::TEXTURE_MODE = 0;
        }
        glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,
            $OpenGL::Earth::TEXTURE_MODES[$OpenGL::Earth::TEXTURE_MODE] );
    }
    elsif ( $c eq 'T' ) {    # T - Texturing.
        $OpenGL::Earth::TEXTURE_ON = $OpenGL::Earth::TEXTURE_ON ? 0 : 1;
    }
    elsif ( $c eq 'A' ) {    # A - Alpha-blending hack.
        $OpenGL::Earth::ALPHA_ADD = $OpenGL::Earth::ALPHA_ADD ? 0 : 1;
    }
    elsif ( $c eq 'F' ) {    # F - Filtering.
        $OpenGL::Earth::FILTERING_ON = $OpenGL::Earth::FILTERING_ON ? 0 : 1;
    }
    elsif ( $c eq 'S' or $key == 32 ) {    # S (Space) - Freeze!
        OpenGL::Earth::Physics::stop();
    }
    elsif ( $c eq 'R' ) {                  # R - Reverse.
        OpenGL::Earth::Physics::reverse_motion();
    }
    else {
        printf "KP: No action for %d.\n", $key;
    }
}

# ------
# Callback Function called when a special $key is pressed.

sub cbSpecialKeyPressed {
    my $key = shift;

    if ( $key == GLUT_KEY_PAGE_UP ) {    # move the cube into the distance.
        $OpenGL::Earth::Physics::Z_OFF -= 0.05;
    }
    elsif ( $key == GLUT_KEY_PAGE_DOWN ) {    # move the cube closer.
        $OpenGL::Earth::Physics::Z_OFF += 0.05;
    }
    elsif ( $key == GLUT_KEY_UP ) {           # decrease $x rotation speed;
        $OpenGL::Earth::Physics::X_SPEED -= 0.01;
    }
    elsif ( $key == GLUT_KEY_DOWN ) {         # increase $x rotation speed;
        $OpenGL::Earth::Physics::X_SPEED += 0.01;
    }
    elsif ( $key == GLUT_KEY_LEFT ) {         # decrease $y rotation speed;
        $OpenGL::Earth::Physics::Y_SPEED -= 0.01;
    }
    elsif ( $key == GLUT_KEY_RIGHT ) {        # increase $y rotation speed;
        $OpenGL::Earth::Physics::Y_SPEED += 0.01;
    }
    else {
        printf "SKP: No action for %d.\n", $key;
    }
}

# ------
# Function to build a simple full-color texture with alpha channel,
# and then create mipmaps.  This could instead load textures from
# graphics files from disk, or render textures based on external
# input.

sub ourBuildTextures {
    my $gluerr;

    # Generate a texture index, then bind it for future operations.
    @OpenGL::Earth::TEXTURES = glGenTextures_p(1);
    glBindTexture( GL_TEXTURE_2D, $OpenGL::Earth::TEXTURES[0] );

    # Iterate across the texture array.
    open my $texf, '<', '../textures/earth-1024x512.texture'
      or die "Please read this distribution textures/README file\n"
      . "for instructions on how to download a pre-made Earth texture\n";

    binmode $texf;
    my $tex = q{};
    my $buf;
    while ( sysread( $texf, $buf, 1048576 ) ) {
        $tex .= $buf;
    }

    my $tex_w = 1024;
    my $tex_h = 512;

=cut
  use Imager;

  my $scanline;
  my $tex = q{};
  my $earth_pic = Imager->new();
  print "Reading earth pic...\n";

  $earth_pic->read(file=>'../textures/earth-1024x512.bmp') or die "Can't read texture!\n";

  print "Reading scanlines... ";
  my $tex_w = $earth_pic->getwidth();
  my $tex_h = $earth_pic->getheight();
  my $perc = 0;
  for (my $y = $tex_h - 1; $y >= 0; $y--) {
      $scanline = $earth_pic->getscanline(y=>$y);
      $tex .= $scanline;
      $perc = int (100 * ($tex_h - 1 - $y) / $tex_h);
      print "$perc%   \r";

  }
  print "\rTexture built.\n";

  open my $texf, '>', '../textures/earth-1024x512.texture'; 
  binmode $texf;
  print $texf $tex;
  close $texf;

=cut

    # The GLU library helps us build MipMaps for our texture.
    if (
        $gluerr =
        gluBuild2DMipmaps_s( GL_TEXTURE_2D, 4, $tex_w, $tex_h, GL_RGBA,
            GL_UNSIGNED_BYTE, $tex
        )
      )
    {
        printf STDERR "GLULib%s\n", gluErrorString($gluerr);
        exit(-1);
    }

    # Some pretty standard settings for wrapping and filtering.
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP );
    glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );

=cut
  glBindTexture(GL_TEXTURE_2D, $OpenGL::Earth::TEXTURES[1]);

  use Imager;

  $tex = q{};
  my $scanline;
  my $pic = Imager->new();
  print "Reading clouds pic...\n";

  $pic->read(file=>'clouds.bmp') or die "Can't read texture!\n";

  print "Reading scanlines...\n";
  $tex_w = $pic->getwidth();
  $tex_h = $pic->getheight();
  for (my $y = $tex_h - 1; $y >= 0; $y--) {
      $scanline = $pic->getscanline(y=>$y);
      for (0 .. length($scanline)/4 - 1) {
         my $red = ord substr($scanline, $_ * 4, 1);
         $red -= 100;
         if ($red < 0) { $red = 0 }
         if ($red > 100) { $red += ($red - 100) * 2 }
         if ($red > 255) { $red = 255 }
         substr($scanline, $_ * 4 + 3, 1, pack("C",$red));
      }
      $tex .= $scanline;
  }
  print "Clouds Texture built.\n";

  open my $texf, '>', 'clouds-texture.bin'; 
  binmode $texf;
  print $texf $tex;
  close $texf;

=cut

=cut
  open $texf, '<', 'clouds-texture.bin';
  binmode $texf;
  my $buf;
  $tex = q{};
  while (sysread($texf, $buf, 1048576)) {
    $tex .= $buf;
  }

  $tex_w = 1024;
  $tex_h = 512;

  # The GLU library helps us build MipMaps for our texture.
  if ($gluerr = gluBuild2DMipmaps_s(GL_TEXTURE_2D, 4, $tex_w, $tex_h, GL_RGBA, GL_UNSIGNED_BYTE, $tex)) {
     printf STDERR "GLULib%s\n", gluErrorString($gluerr);
     exit(-1);
  }

  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_R,GL_CLAMP);
  glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);

=cut

    return;
}

# ------
# Does everything needed before losing control to the main
# OpenGL event loop.

sub ourInit {
    my ( $Width, $Height ) = @_;

    OpenGL::Earth::Wiimote::init();

    ourBuildTextures();

    glutFullScreen();

    # Color to clear color buffer to.
    glClearColor( 0.0, 0.0, 0.0, 0.0 );

    # Depth to clear depth buffer to; type of test.
    glClearDepth(1.0);
    glDepthFunc(GL_LESS);

    # Enables Smooth Color Shading; try GL_FLAT for (lack of) fun.
    glShadeModel(GL_SMOOTH);

    # Load up the correct perspective matrix; using a callback directly.
    OpenGL::Earth::Scene::resize( $Width, $Height );

    # Set up a light, turn it on.
    OpenGL::Earth::Scene::setup_lighting();

    glHint( GL_LINE_SMOOTH_HINT, GL_FASTEST );
    glEnable(GL_LINE_SMOOTH);

    glColorMaterial( GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE );
    glEnable(GL_COLOR_MATERIAL);

}

# ------
# The main() function.  Inits OpenGL.  Calls our own init function,
# then passes control onto OpenGL.

glutInit();

# To see OpenGL drawing, take out the GLUT_DOUBLE request.
glutInitDisplayMode( GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH );
glutInitWindowSize( $OpenGL::Earth::WINDOW_WIDTH,
    $OpenGL::Earth::WINDOW_HEIGHT );

# Open a window
$OpenGL::Earth::WINDOW_ID = glutCreateWindow(PROGRAM_TITLE);

# Register the callback function to do the drawing.
glutDisplayFunc( \&OpenGL::Earth::Scene::render );

# If there's nothing to do, draw.
glutIdleFunc( \&OpenGL::Earth::Scene::render );

# It's a good idea to know when our window's resized.
glutReshapeFunc( \&OpenGL::Earth::Scene::resize );

# And let's get some keyboard input.
glutKeyboardFunc( \&cbKeyPressed );
glutSpecialFunc( \&cbSpecialKeyPressed );

# OK, OpenGL's ready to go.  Let's call our own init function.
ourInit( $OpenGL::Earth::WINDOW_WIDTH, $OpenGL::Earth::WINDOW_HEIGHT );

# Print out a bit of help dialog.
print PROGRAM_TITLE, "\n";
print << 'TXT';
Use arrow keys to rotate, 'R' to reverse, 'S' to stop.
Page up/down will move the earth away from/towards camera.
Use first letter of shown display mode settings to alter.
Q or [Esc] to quit; OpenGL window must have focus for input.
TXT

# Pass off control to OpenGL.
# Above functions are called as appropriate.
glutMainLoop();

