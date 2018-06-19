#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw(
	make_context $res tex glEnable glBlendFunc glClear glClearColor get_gl_errors
	glBlendFunc
	GL_TEXTURE_2D GL_BLEND GL_SRC_ALPHA GL_ONE GL_CLAMP GL_REPEAT GL_COLOR_BUFFER_BIT
	GL_DEPTH_BUFFER_BIT GL_MODULATE GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
);
use OpenGL::Sandbox::V1 ':all';

$ENV{TEST_VISUAL}
	or plan skip_all => "Set TEST_VISUAL=1 to run these tests";

my $c= try { make_context; }
	or plan skip_all => "Can't test without context";

$res->resource_root_dir(catdir($FindBin::Bin, 'data'));

sub show(&) {
	my ($code, $tname)= @_;
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	load_identity;
	$code->();
	$c->swap_buffers;
	sleep .5;
	my @e= get_gl_errors;
	ok( !@e, $tname )
		or diag "GL Errors: ".join(', ', @e);
}
sub spin(&) {
	my ($code, $tname)= @_;
	load_identity;
	for (my $i= 0; $i < 200; $i++) {
		glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
		local_matrix {
			rotate $i*1, 1, 1, 0;
			rotate $i*2, 0, 0, 1;
			$code->();
		};
		$c->swap_buffers;
	}
	my @e= get_gl_errors;
	ok( !@e, $tname )
		or diag "GL Errors: ".join(', ', @e);
}

# First frame seems to get lost, unless I sleep a bit
show {};

# Render solid blue, as a test
glClearColor(0,0,1,1);
show {};

#subtest textures => \&test_textures;
sub test_textures {
	# Render texture at 0,0
	glEnable(GL_TEXTURE_2D);
	glClearColor(0,0,0,1);
	my $t= tex('8x8')->bind;
	$t->wrap_s(GL_CLAMP);
	$t->wrap_t(GL_CLAMP);
	# Render scaled to 1/4 the window
	show {
		$t->render(scale => 1/$t->width);
	};

	# Render full-window, ignoring native texture dimensions
	show {
		$t->render(w => 2, center => 1);
	};

	# Render repeated 9 times across the window
	$t->wrap_s(GL_REPEAT);
	$t->wrap_t(GL_REPEAT);
	show {
		$t->render(w => 2, center => 1, s_rep => 9, t_rep => 9);
	};

	# Render with alpha blending, and with non-square aspect texture
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(0,.2,.3,1);
	show {
		tex('14x7-rgba')->render(w => 2, center => 1, s_rep => 9, t_rep => 9);
	};
};

#subtest coordinate_sys => \&test_coordinate_sys;
sub test_coordinate_sys {
	# Render a coordinate system
	spin {
		draw_axes_xy;
	};

	# Render a coordinate system in 3D and spin it
	spin {
		draw_axes_xyz;
	};
};

subtest boundbox => \&test_boundbox;
sub test_boundbox {
	show { draw_boundbox( -.5, -.5, .5, .5 ); };
	show { draw_boundbox( .3, .3, .9, .9 ); };
	show { draw_boundbox( -.9, .3, .9, .9 ); };
}

subtest projection => \&test_projection;
sub test_projection {
	setup_projection(left => -11, right => 11, z => 2);
	show { draw_boundbox( -10, -10, 10, 10 ) };
	setup_projection(left => -11, right => 11, z => 2, aspect => .5);
	show { draw_boundbox( -10, -10, 10, 10 ) };
}

undef $c;
done_testing;
