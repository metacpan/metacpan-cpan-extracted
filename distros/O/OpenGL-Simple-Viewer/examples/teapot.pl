#!/usr/bin/env perl
use strict;
use warnings;

use OpenGL::Simple::Viewer;
use OpenGL::Simple::GLUT qw(:all);

glutInit;

my $v = new OpenGL::Simple::Viewer(
        draw_geometry => sub { glutSolidTeapot(1.0); }
);

glutMainLoop;




