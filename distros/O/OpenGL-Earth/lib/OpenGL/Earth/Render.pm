package OpenGL::Earth::Render;

use strict;
use warnings;
use OpenGL q(:all);

sub string {
    my ( $font, $str ) = @_;
    my @c = split '', $str;
    for (@c) {
        glutBitmapCharacter( $font, ord $_ );
    }
}

sub text_stats {
    my ($motion) = @_;
    my ($width, $height) = ( 600, 600 );

    # We need to change the projection matrix for the text rendering.
    glMatrixMode(GL_PROJECTION);

    # But we like our current view too; so we save it here.
    glPushMatrix();

    # Now we set up a new projection for the text.
    glLoadIdentity();

    glOrtho( 0, $width, 0, $height, -1.0, 1.0 );

    # Lit or textured text looks awful.
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_TEXTURE_GEN_S);
    glDisable(GL_TEXTURE_GEN_T);
    glDisable(GL_LIGHTING);

    # We don'$t want depth-testing either.
    glDisable(GL_DEPTH_TEST);
    glColor4f( 0.6, 1.0, 0.6, .75 );

    # Render our various display mode settings.
    my $buf;
    $buf = sprintf "Mode: %s", $OpenGL::Earth::TEXTURE_MODE;
    glRasterPos2i( 2, 2 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "AAdd: %d", $OpenGL::Earth::ALPHA_ADD;
    glRasterPos2i( 2, 14 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "Blend: %d", $OpenGL::Earth::BLEND_ON;
    glRasterPos2i( 2, 26 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "Light: %d", $OpenGL::Earth::LIGHT_ON;
    glRasterPos2i( 2, 38 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "Tex: %d", $OpenGL::Earth::TEXTURE_ON;
    glRasterPos2i( 2, 50 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "Filt: %d", $OpenGL::Earth::FILTERING_ON;
    glRasterPos2i( 2, 62 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "XAcc: %3.3f", $motion->{force_x};
    glRasterPos2i( 2, 74 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "YAcc: %3.3f", $motion->{force_y};
    glRasterPos2i( 2, 88 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "ZAcc: %3.3f", $motion->{force_z};
    glRasterPos2i( 2, 100 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "XTilt: %3.3f", $motion->{tilt_x};
    glRasterPos2i( 2, 114 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "YTilt: %3.3f", $motion->{tilt_y};
    glRasterPos2i( 2, 128 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "Pitch: %3.3f", $motion->{tilt_z};
    glRasterPos2i( 2, 142 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "XAxis: %3.3f", $motion->{axis_x};
    glRasterPos2i( 2, 156 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "YAxis: %3.3f", $motion->{axis_y};
    glRasterPos2i( 2, 170 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    $buf = sprintf "ZAxis: %3.3f", $motion->{axis_z};
    glRasterPos2i( 2, 184 );
    string( GLUT_BITMAP_HELVETICA_12, $buf );

    # Now we want to render the calulated FPS at the top.
    # To ease, simply translate up.  Note we're working in screen
    # pixels in this projection.
    #
    #glTranslatef(6.0,$Window_Height - 14,0.0);
    #
    # Make sure we can read the FPS section by first placing a
    # dark, mostly opaque backdrop rectangle.
    #glColor4f(0.0, 0.0, 0.0, 0.75);
    #
    #glBegin(GL_QUADS);
    #glVertex3f(  0.0, -2.0, 0.0);
    #glVertex3f(  0.0, 12.0, 0.0);
    #glVertex3f(140.0, 12.0, 0.0);
    #glVertex3f(140.0, -2.0, 0.0);
    #glEnd();

    #glColor4f(0.9, 0.0, 0.0, .75);
    #$buf = sprintf "FPS: %f F: %2d", $FrameRate, $FrameCount;
    #glRasterPos2i(6,0);
    #string(GLUT_BITMAP_HELVETICA_12,$buf);

    # Done with this special projection matrix.  Throw it away.
    glPopMatrix();

}

1;
