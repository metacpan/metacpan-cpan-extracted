#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use OpenGL::Modern ':all';

#eval 'use Test::Pod::Coverage';
#my $xerror = Prima::XOpenDisplay;
#plan skip_all => $xerror if defined $xerror;

my $tests = 3;
plan tests => $tests;

my $gCC_status = -1;
$gCC_status = glewCreateContext();    # returns GL_TRUE or GL_FALSE
ok( ( $gCC_status == GL_TRUE() or $gCC_status == GL_FALSE() ), "glewCreateContext" );    # returns GL_TRUE or GL_FALSE

SKIP: {
    skip "glewContext did not succeed, skipping live tests", 2 unless $gCC_status == GLEW_OK;

    my $gI_status = -1;
    $gI_status = ( done_glewInit() ) ? GLEW_OK() : glewInit();                           # returns GLEW_OK or ???
    ok( $gI_status == GLEW_OK(), "glewInit" ) or note "glewInit() returned '$gI_status'\n";

  SKIP: {
        skip "glewInit did not succeed, skipping live tests", 1 unless $gI_status == GLEW_OK;

        my $opengl_version = glGetString( GL_VERSION );    # should skip if no context (and/or no init?)
        isnt( '', $opengl_version, 'GL_VERSION' );

        note "We got OpenGL version $opengl_version\n";
    }
}
