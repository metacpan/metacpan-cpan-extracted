#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use Log::Any::Adapter 'TAP';

plan skip_all => 'OpenGL not installed'
	unless eval 'require OpenGL; 1';

$ENV{OPENGL_SANDBOX_OPENGLMODULE}= 'OpenGL';
require OpenGL::Sandbox;
OpenGL::Sandbox->import(qw/ make_context gl_error_name get_gl_errors glTexParameteri GL_INVALID_ENUM /);

is( gl_error_name(GL_INVALID_ENUM()), "GL_INVALID_ENUM", 'can look up name of GL_INVALID_ENUM' );
is( gl_error_name(-9999), undef, "invalid code returns undef" );

my $ctx= try { make_context() };

SKIP: {
	skip "Can't create an OpenGL context", 2 unless $ctx;

	is_deeply( [ get_gl_errors() ], [], 'no errors before starting' );
	glTexParameteri(-1, -1, -1);
	is_deeply( [ get_gl_errors() ], ['GL_INVALID_ENUM'], 'invalid enum' );
}

done_testing;
