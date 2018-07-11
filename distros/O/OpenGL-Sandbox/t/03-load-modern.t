#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Try::Tiny;
use Test::More;

plan skip_all => 'Need module OpenGL::Modern'
	unless eval 'require OpenGL::Modern';

$ENV{OPENGL_SANDBOX_OPENGLMODULE}= 'OpenGL::Modern';
use_ok( 'OpenGL::Sandbox' );
is( $OpenGL::Sandbox::OpenGLModule, 'OpenGL::Modern', 'correct module' );
ok( eval { OpenGL::Sandbox->import('make_context') ; 1 } && main->can('make_context'), 'import local symbol' );
ok( eval { OpenGL::Sandbox->import('GL_TRUE')      ; 1 } && main->can('GL_TRUE') && GL_TRUE(), 'import GL constant' );
ok( eval { OpenGL::Sandbox->import('glBindTexture'); 1 } && main->can('glBindTexture'),'import GL function' );

done_testing;
