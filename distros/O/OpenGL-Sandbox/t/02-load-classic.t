#! /usr/bin/env perl
use strict;
use warnings;
use Try::Tiny;
use Test::More;

plan skip_all => 'Need module OpenGL'
	unless eval 'require OpenGL';

$ENV{OPENGL_SANDBOX_OPENGLMODULE}= 'OpenGL';
use_ok( 'OpenGL::Sandbox' );
is( $OpenGL::Sandbox::OpenGLModule, 'OpenGL', 'correct module' );
ok( eval { OpenGL::Sandbox->import('make_context') ; 1 } && main->can('make_context'), 'import local symbol' );
ok( eval { OpenGL::Sandbox->import('GL_TRUE')      ; 1 } && main->can('GL_TRUE') && GL_TRUE(), 'import GL constant' );
ok( eval { OpenGL::Sandbox->import('glBindTexture'); 1 } && main->can('glBindTexture'),'import GL function' );

done_testing;
