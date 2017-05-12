#!/usr/bin/env perl
use strict;
use warnings;
use OpenGL::Simple qw(:all);
use OpenGL::Simple::GLUT qw(:all);
use OpenGL::Simple::Viewer;
use Imager;

glutInit;

my $v = new OpenGL::Simple::Viewer(
        draw_geometry => sub {
                glutSolidTeapot(1.0);
        },
);

my $img = new Imager;
$img->read(file=>'check.png') or die("Unable to load texture");

my $texid = glGenTextures(1);
glBindTexture(GL_TEXTURE_2D,$texid);
glTexImage2D(image=>$img);
glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
glTexParameter(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
glEnable(GL_TEXTURE_2D);
glClearColor(0,0.3,0.6,1);


glutMainLoop;
