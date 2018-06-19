#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/
	make_context get_gl_errors $res :V1:all
	glClear GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT glClearColor
/;

$ENV{TEST_VISUAL}
	or plan skip_all => "Set TEST_VISUAL=1 to run these tests";

my $c= try { make_context; }
	or plan skip_all => "Can't test without context";

$res->resource_root_dir(catdir($FindBin::Bin, 'data'));
$res->font_config({
	default => { filename => 'SquadaOne-Regular', face_size => 32 }
});

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

# Fonts render at 1 unit per point, by default, so just change projection matrix instead
# of scaling modelview in every test.
setup_projection(left => -200, right => 200, z => 10);

# Render solid blue, as a test
glClearColor(0,0,1,1);
show {};

my $font= $res->font('default');
# Render with baseline at origin
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("Left Baseline");
};

# Render with baseline at origin
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("Right Baseline", xalign => 1);
};

show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render('Center Baseline', xalign => .5);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("Top", xalign => .5, yalign => 1);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("Center", xalign => .5, yalign => .5);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("Bottom", xalign => .5, yalign => -1);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render('Width=200', width => 200, xalign => .5);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render('Scale 3x', xalign => .5, scale => 3);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render('Width=200,Height=50', width => 200, height => 50, xalign => .5);
};
show {
	draw_boundbox( -50, $font->descender, 50, $font->ascender );
	$font->render("monospaced", x => -100, monospace => 15);
};

done_testing;
