#!/usr/bin/env perl
use strict;
use warnings;
use OpenGL::Simple qw(:all);
use OpenGL::Simple::GLUT qw(:all);
use OpenGL::Simple::Viewer;

# If you have a nice NVIDIA card with the vendor drivers, it's possible
# to set the fullscreen anti-aliasing mode through the __GL_FSAA_MODE
# environment variable, on linux at least. This takes effect when a new
# GLUT window is created.

# This script opens up windows to render a torus with FSAA mode from 0
# to 7. Some of these modes may not have any effect, depending on your
# card and driver version.


my $aamax=7;


glutInit;

my %args = (
        screenx => 256, screeny => 256,
        draw_geometry => sub {
                glColor(1,1,1,1);
                glutSolidTorus(0.25,0.5,20,20);
                glColor(0,0,0,1);
                glutWireTorus(0.25,0.5,20,20);
        },
);

my @viewers;

for my $aaval (0..$aamax) {
       
        # Set an environment variable (see driver README) to turn on FSAA.
        $ENV{'__GL_FSAA_MODE'}=$aaval;

        my $v = new OpenGL::Simple::Viewer(%args, 'title'=>"FSAA mode $aaval");
        setup_gl();

        push @viewers,$v;
}

OpenGL::Simple::Viewer::gang_together(@viewers);


glutMainLoop;
exit;

sub setup_gl {
        glClearColor(1,1,1,1);

        glPolygonOffset(1,1);
        glEnable(GL_POLYGON_OFFSET_FILL);
        glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
        glHint(GL_LINE_SMOOTH_HINT,GL_NICEST);
}




