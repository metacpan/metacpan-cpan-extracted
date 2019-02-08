#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use lib "$FindBin::Bin/lib";
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context log_gl_errors GL_FLOAT /;

my $cx;
plan skip_all => "Can't create an OpenGL context: $@"
	unless eval { $cx= make_context(); 1 };

plan skip_all => "No support for buffer objects in this OpenGL context: $@"
	unless eval { require OpenGL::Sandbox::Buffer; };

OpenGL::Sandbox->import('GL_ARRAY_BUFFER', 'GL_STATIC_DRAW');

my $buf= new_ok( 'OpenGL::Sandbox::Buffer', [] );

$buf->bind(GL_ARRAY_BUFFER());
is( $buf->target, GL_ARRAY_BUFFER(), 'marked the last known target' );

$buf->load("x" x 150);
ok( !log_gl_errors, 'load: no GL errors' );
is( $buf->usage, GL_STATIC_DRAW(), 'got default usage hint' );

$buf->load_at(50, "y"x100, 20);
ok( !log_gl_errors, 'load_at: no GL errors' );

if ($^O eq 'MSWin32') {
	# can't use a normal TODO or SKIP because the code still crashes
	TODO: { local $TODO= "unmap crashes on Windows, so can't test mmap"; fail("memory map works"); }
} else {
	is( ${$buf->mmap}, ("x" x 50).("y" x 80).("x" x 20), "memory map works" );
	ok( !log_gl_errors, 'load_at: no GL errors' );

	substr( ${$buf->mmap}, 20, 40 )= "z"x40;

	$buf->unmap;
	is( ${$buf->mmap('r+', 10, 80)}, ("x"x10).("z"x40).("y"x30), 'memory map sub-range matches expected' );
}

undef $buf;
ok( !log_gl_errors, 'load_at: no GL errors' );

done_testing;
