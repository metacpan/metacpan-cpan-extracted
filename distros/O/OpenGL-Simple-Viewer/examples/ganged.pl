#!/usr/bin/env perl
use strict;
use warnings;
use OpenGL::Simple qw(:all);
use OpenGL::Simple::GLUT qw(:all);
use OpenGL::Simple::Viewer;
use Math::Quaternion;
use Math::Trig;

glutInit;

my $wsize = 256;
glutInitWindowPosition(0,0);

my $v1 = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glColor(1,0,0,1);
                glutSolidIcosahedron;
        },
);
glutInitWindowPosition(0,$wsize);

my $v2 = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glColor(0,1,0,1);
                glutWireIcosahedron;
        },
);
glutInitWindowPosition($wsize,0.5*$wsize);

my $v3 = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glEnable(GL_LIGHTING);
                glColor(0.5,0.5,0.5,1);
                glutSolidIcosahedron;
                glDisable(GL_LIGHTING);
                glLineWidth(3.0);
                glColor(0,0,1,1);
                glutWireIcosahedron;
        }
);
# Set some extra GL state in window 3.
glPolygonOffset(1.0,1.0);
glEnable(GL_POLYGON_OFFSET_FILL);
glEnable(GL_DEPTH_TEST);
glEnable(GL_COLOR_MATERIAL);

glutInitWindowPosition(2*$wsize,0);

my $v4 = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glColor(1,0,1,1);
                glutSolidTeapot(1.0);
        }
);

glutInitWindowPosition(2*$wsize,$wsize);

my $v5 = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glColor(0,1,1,1);
                glutWireTeapot(1.0);
        }
);

# Rotate v5 by 90 degrees

my $q = new Math::Quaternion({ axis=>[0,1,0], angle => 0.5*pi });
$v5->{'orientation'} = $q * $v5->{'orientation'};

# Gang together the motions of v1 and v2.
$v1->gang_together($v2);

# Gang v4 and v5 together.
OpenGL::Simple::Viewer::gang_together($v4,$v5);

# Make a movement of v3 apply to all the others.
$v3->enslave($v1,$v2,$v4,$v5);

# Make a movement of v5 apply to v1 and v3
$v5->enslave($v1,$v3);
# But then decide against it.
$v5->decouple($v1,$v3);

glutMainLoop;

exit;

