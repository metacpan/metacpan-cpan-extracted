package OpenGL::Earth::Scene;

use strict;
use warnings;
use OpenGL q(:all);
use OpenGL::Earth::NetworkHits;
use OpenGL::Earth::Physics;

our @LIGHT_AMBIENT  = ( 0.0, 0.0, 0.1, 0.2 );
our @LIGHT_DIFFUSE  = ( 1.2, 1.2, 1.2, 1.0 );
our @LIGHT_POSITION = ( 4.0, 4.0, 2.0, 3.0);

sub render {

  # Enables, disables or otherwise adjusts as
  # appropriate for our current settings.

  if ($OpenGL::Earth::TEXTURE_ON) {
    glEnable(GL_TEXTURE_2D);
  }
  else {
    glDisable(GL_TEXTURE_2D);
  }
  if ($OpenGL::Earth::LIGHT_ON) {
    glEnable(GL_LIGHTING);
  }
  else {
    glDisable(GL_LIGHTING);
  }

  #if ($OpenGL::Earth::ALPHA_ADD) {
  #  glBlendFunc(GL_SRC_ALPHA,GL_ONE);
  #}
  #else {
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  #}

  # If we're blending, we don'$t want z-buffering.
  if ($OpenGL::Earth::BLEND_ON) {
    glDisable(GL_DEPTH_TEST);
  }
  else {
    glEnable(GL_DEPTH_TEST);
  }
  if ($OpenGL::Earth::FILTERING_ON) {
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  }
  else {
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
  }

  # Need to manipulate the ModelView matrix to move our model around.
  glMatrixMode(GL_MODELVIEW);

  # Reset to 0,0,0; no rotation, no scaling.
  glLoadIdentity();

  OpenGL::Earth::Physics::move();

  # Clear the color and depth buffers.
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  my $quad = gluNewQuadric();
  if ($quad != 0)
  {
      gluQuadricNormals($quad, GLU_SMOOTH);
      gluQuadricTexture($quad, GL_TRUE);
 
      #my @Earth_emission = (0.0, 0.0, 0.0, 1.0);
      #my @Earth_specular = (0.3, 0.3, 0.3, 1.0);
      #glMaterialf(GL_FRONT, GL_EMISSION, 0.0); #@Earth_emission);
      #glMaterialf(GL_FRONT, GL_SPECULAR, 50.0); #@Earth_specular);

      # Render Earth sphere
      glBindTexture(GL_TEXTURE_2D, $OpenGL::Earth::TEXTURES[0]);
      glColor3f(0.6, 0.6, 0.6);

      gluSphere($quad, 1.5, 64, 64);
      gluDeleteQuadric($quad);
  }

  glDisable(GL_LIGHTING);

  OpenGL::Earth::NetworkHits::display();

  # Sense the wii motion
  my $motion = OpenGL::Earth::Wiimote::get_motion();

  # Move back to the origin (for the text, below).
  glLoadIdentity();

  OpenGL::Earth::Render::text_stats($motion);

  # All done drawing.  Let's show it.
  glutSwapBuffers();

  #static_motion_calc($motion);
  OpenGL::Earth::Physics::calculate_falloff_motion($motion);

  # And collect our statistics.
  #ourDoFPS();

  return;
}

sub resize {

    my ($width, $height) = @_;

    # Let's not core dump, no matter what.
    $height = 1 if ($height == 0);

    glViewport(0, 0, $width, $height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0,$width/$height,0.1,100.0);

    glMatrixMode(GL_MODELVIEW);

    $OpenGL::Earth::WINDOW_WIDTH  = $width;
    $OpenGL::Earth::WINDOW_HEIGHT = $height;

    return;
}

sub setup_lighting {
    glLightfv_p(GL_LIGHT1, GL_POSITION, @LIGHT_POSITION);
    glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @LIGHT_AMBIENT);
    glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @LIGHT_DIFFUSE);
    glEnable (GL_LIGHT1);
}

1;

