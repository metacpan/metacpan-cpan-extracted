#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use lib "$FindBin::Bin/lib";
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context log_gl_errors GL_FLOAT program /,
	-resources => { path => "$FindBin::Bin/data" };

my $cx;
plan skip_all => "Can't create an OpenGL context: $@"
	unless eval { $cx= make_context(); 1 };

plan skip_all => "No support for buffer objects in this OpenGL context: $@"
	unless eval {
		require OpenGL::Sandbox::VertexArray;
		require OpenGL::Sandbox::Buffer;
	};

OpenGL::Sandbox->import('GL_ARRAY_BUFFER', 'GL_STATIC_DRAW');

my $vao= new_ok( 'OpenGL::Sandbox::VertexArray', [
	attributes => {
		pos => { size => 2, type => GL_FLOAT },
	}
] );
my $vbo= new_ok( 'OpenGL::Sandbox::Buffer', [
	target => GL_ARRAY_BUFFER(),
	data => pack('f*', (0)x100)
] );

my $program= program('xy_screen')->bind;
ok( eval { $vao->bind($program, $vbo); 1 }, 'apply' ) or diag $@;

done_testing;
