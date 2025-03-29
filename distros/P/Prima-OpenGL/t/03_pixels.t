#!/usr/bin/perl

BEGIN { $ENV{PERL_DL_NONLAZY} = 0; }
use strict;
use warnings;
use Test::More;
use Prima::sys::Test;
use OpenGL;
use Prima::OpenGL;
use Prima::Application;

plan tests => 34;

my $x = Prima::DeviceBitmap-> new(
	width  => 2,
	height => 2,
);
$x-> gl_begin_paint;

glClearColor(0,0,1,1);
glClear(GL_COLOR_BUFFER_BIT);
glOrtho(-1,1,-1,1,-1,1);

glColor3f(1,0,0);
glBegin(GL_POLYGON);
	glVertex2f( 0,0);
	glVertex2f( 1, 0);
	glVertex2f( 1, -1);
	glVertex2f( 0, -1);
glEnd();
glFinish();

$x-> gl_flush;

sub hex_is
{
	my ( $a, $b, $c) = @_;
	return is(sprintf("%x", $a), sprintf("%x", $b), $c);
}

# RGB
my $i = $x->gl_read_pixels( format => GL_RGB );
hex_is( $i->pixel(0,0), 0x000000FF, "rgb(0,0)=B");
hex_is( $i->pixel(0,1), 0x000000FF, "rgb(0,1)=B");
hex_is( $i->pixel(1,0), 0x00FF0000, "rgb(1,0)=R");
hex_is( $i->pixel(1,1), 0x000000FF, "rgb(1,1)=B");

# R/G/B
$i = $x->gl_read_pixels( format => GL_BLUE );
hex_is( $i->pixel(0,0), 0xFF, "blue(0,0)=B");
hex_is( $i->pixel(0,1), 0xFF, "blue(0,0)=B");
hex_is( $i->pixel(1,0), 0x00, "blue(0,0)=0");
hex_is( $i->pixel(1,1), 0xFF, "blue(0,0)=B");

$i = $x->gl_read_pixels( format => GL_GREEN );
hex_is( $i->pixel(0,0), 0x00, "green(0,0)=0");
hex_is( $i->pixel(0,1), 0x00, "green(0,0)=0");
hex_is( $i->pixel(1,0), 0x00, "green(0,0)=0");
hex_is( $i->pixel(1,1), 0x00, "green(0,0)=0");

$i = $x->gl_read_pixels( format => GL_RED );
hex_is( $i->pixel(0,0), 0x00, "red(0,0)=0");
hex_is( $i->pixel(0,1), 0x00, "red(0,0)=0");
hex_is( $i->pixel(1,0), 0xFF, "red(0,0)=R");
hex_is( $i->pixel(1,1), 0x00, "red(0,0)=0");

$i = $x->gl_read_pixels( format => GL_RED, type => GL_SHORT );
is( $i->pixel(0,0), 0x00,   "red16(0,0)=0");
ok( $i->pixel(1,0) > 0x7FF0, "red16(0,0)=R16");

$i = $x->gl_read_pixels( format => GL_RED, type => GL_INT );
is( $i->pixel(0,0), 0x00,       "red32(0,0)=0");
ok( $i->pixel(1,0) > 0x7FFF0000, "red32(0,0)=R32");

$i = $x->gl_read_pixels( format => GL_RED, type => GL_FLOAT );
ok( $i->pixel(0,0) < 0.01,       "redf(0,0)=0");
ok( $i->pixel(1,0) > 0.99,       "redf(0,0)=1.0f");

my ( $d, $m ) = $x->gl_read_pixels( format => GL_RGBA )-> split;
hex_is( $d->pixel(0,0), 0x000000FF, "RGBa(0,0)=B");
hex_is( $d->pixel(0,1), 0x000000FF, "RGBa(0,1)=B");
hex_is( $d->pixel(1,0), 0x00FF0000, "RGBa(1,0)=R");
hex_is( $d->pixel(1,1), 0x000000FF, "RGBa(1,1)=B");
hex_is( $m->pixel(0,0), 0x000000FF, "rgbA(0,0)=1");
hex_is( $m->pixel(0,1), 0x000000FF, "rgbA(0,1)=1");
hex_is( $m->pixel(1,0), 0x000000FF, "rgbA(1,0)=1");
hex_is( $m->pixel(1,1), 0x000000FF, "rgbA(1,1)=1");

$d->type(im::RGB);
$d->color(0);
$d->bar(0,0,1,1);
$d->color(0xff8800);
$d->bar(1,1,2,2);
$d->gl_draw_pixels;
$d = $x->gl_read_pixels( format => GL_RGB );
hex_is( $d->pixel(0,0), 0x00000000, "RGB(0,0)=0");
hex_is( $d->pixel(0,1), 0x00000000, "RGB(0,1)=0");
hex_is( $d->pixel(1,0), 0x00000000, "RGB(1,0)=0");
my $c = $d->pixel(1,1);
my ( $b, $g, $r ) = (( $c & 0xff), ($c >> 8) & 0xff, ($c >> 16) & 0xff);
ok( $r > 0xf0 && $g > 0x78 && $g < 0x98 && $b == 0, "RGB(1,1)=1");

$x-> gl_end_paint;

