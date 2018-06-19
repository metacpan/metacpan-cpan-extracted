#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use Log::Any::Adapter 'TAP';

plan skip_all => 'OpenGL::Modern not installed'
	unless eval 'require OpenGL::Modern; 1';

$ENV{OPENGL_SANDBOX_OPENGLMODULE}= 'OpenGL::Modern';
require OpenGL::Sandbox;
OpenGL::Sandbox->import(qw/ make_context get_gl_errors glTexParameteri /);

ok( scalar keys %OpenGL::Sandbox::_gl_err_msg > 3, 'Have at least 3 error codes defined' );

my $ctx= try { make_context() };

SKIP: {
	skip "Can't create an OpenGL context", 2 unless $ctx;

	is_deeply( [ get_gl_errors() ], [], 'no errors before starting' );
	glTexParameteri(-1, -1, -1);
	is_deeply( [ get_gl_errors() ], ['GL_INVALID_ENUM'], 'invalid enum' );
}

done_testing;
