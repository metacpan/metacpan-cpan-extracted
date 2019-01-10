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
use OpenGL::Sandbox qw/ make_context get_gl_errors GL_TRIANGLES
 -V1 compile_list call_list plot_xy /;

my $c= try { make_context; }
	or plan skip_all => "Can't test without context";

sub geom {
	plot_xy GL_TRIANGLES,
		1, 1,
		1, 0,
		0, 1;
}

my $list= compile_list \&geom;
isa_ok( $list, 'OpenGL::Sandbox::V1::DisplayList' );
ok( $list->id, 'has a displaylist id' );
is_deeply( [get_gl_errors], [], 'no GL errors' );

$list->call;
is_deeply( [get_gl_errors], [], 'no GL errors' );

my $list2;
call_list $list2, \&geom;
isa_ok( $list2, 'OpenGL::Sandbox::V1::DisplayList' );
ok( $list->id, 'has a displaylist id' );
is_deeply( [get_gl_errors], [], 'no GL errors' );

done_testing;
