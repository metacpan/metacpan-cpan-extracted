#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
BEGIN { $OpenGL::Sandbox::V1::VERSION= $ENV{ASSUME_V1_VERSION} } # for testing before release
use OpenGL::Sandbox qw/ make_context get_gl_errors glFlush GL_TRIANGLES
 -V1 compile_list cylinder sphere disk partial_disk /;

my $c= try { make_context; }
	or plan skip_all => "Can't test without context";

# No way to verify... just call methods and verify no GL errors.
sub assert_noerror {
	my ($code, $name)= @_;
	local $@;
	if (eval { $code->(); 1; }) {
		glFlush();
		is_deeply( [get_gl_errors], [], $name);
	} else {
		fail($name);
		diag $@;
	}
}

assert_noerror sub { cylinder(1,2,3,4,5); }, 'cylinder';
assert_noerror sub { sphere(1,2,3); }, 'sphere';
assert_noerror sub { disk(2,1,3,4); }, 'disk';
assert_noerror sub { partial_disk(2,1,3,4,5,6); }, 'partial_disk';

my $q= OpenGL::Sandbox::V1::Quadric->new;
assert_noerror sub { $q->cylinder(1,2,3,4,5); }, 'cylinder';
assert_noerror sub { $q->sphere(1,2,3); }, 'sphere';
assert_noerror sub { $q->disk(2,1,3,4); }, 'disk';
assert_noerror sub { $q->partial_disk(2,1,3,4,5,6); }, 'partial_disk';
assert_noerror sub {
	is( $q->$_, $q, $_ ) for qw/ draw_fill draw_line draw_silhouette draw_point /;
	is( $q->$_, $q, $_ ) for qw/ no_normals flat_normals smooth_normals /;
	is( $q->$_, $q, $_ ) for qw/ inside outside /;
	is( $q->texture($_), $q, "texture($_)" ) for 1, 0;
}, 'quadric options';
undef $q;

done_testing;
