#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context get_gl_errors /;
# Override the glOrtho and glFrustum to save the coordinates locally
our (@glOrtho, @glFrustum);
BEGIN {
	*OpenGL::Sandbox::glOrtho= sub { @glOrtho= @_; };
	*OpenGL::Sandbox::glFrustum= sub { @glFrustum= @_; };
	push @OpenGL::Sandbox::EXPORT_OK, 'glOrtho','glFrustum';
}
use OpenGL::Sandbox::V1 'setup_projection';
is( \&OpenGL::Sandbox::V1::glOrtho, \&OpenGL::Sandbox::glOrtho, 'installed mock method' )
	or BAIL_OUT;

my @tests= (
	{ opts => [ left => -10, right => 10, bottom => -3, top => 3 ],
	  frustum => [ -10, 10, -3, 3, 1, 1000 ],
	},
	{ opts => [ left => -10, right => 10, aspect => 1 ],
	  frustum => [ -10, 10, -10, 10, 1, 1000 ],
	},
	{ opts => [ left => -10, aspect => 4/3 ],
	  frustum => [ -10, 10, -7.5, 7.5, 1, 1000 ],
	},
	{ opts => [ bottom => -10, aspect => 1 ],
	  frustum => [ -10, 10, -10, 10, 1, 1000 ],
	},
	{ opts => [ top => 1, right => 1 ],
	  frustum => [ -1, 1, -1, 1, 1, 1000 ],
	},
	{ opts => [ width => 1, aspect => 2 ],
	  frustum => [ -.5, .5, -.25, .25, 1, 1000 ],
	},
	{ opts => [ aspect => 2 ],
	  frustum => [ -2, 2, -1, 1, 1, 1000 ],
	},
	{ opts => [ z => 4, aspect => 2 ],
	  frustum => [ -2/4, 2/4, -1/4, 1/4, 1, 1000 ],
	},
	{ opts => [ ortho => 1, aspect => 1 ],
	  ortho => [ -1, 1, -1, 1, -1, 1000 ],
	},
	{ opts => [ ortho => 1, mirror_x => 1 ],
	  ortho => [ 1, -1, -1, 1, -1, 1000 ],
	},
	{ opts => [ ortho => 1, mirror_y => 1 ],
	  ortho => [ -1, 1, 1, -1, -1, 1000 ],
	},
	{ opts => [ ortho => 1, mirror_x => 1, mirror_y => 1 ],
	  ortho => [ 1, -1, 1, -1, -1, 1000 ],
	},
);
for my $i (0..$#tests) {
	@glOrtho= ();
	@glFrustum= ();
	my $in=      $tests[$i]{opts};
	my $frustum= $tests[$i]{frustum} // [];
	my $ortho=   $tests[$i]{ortho} // [];
	setup_projection(@$in);
	is_deeply( \@glOrtho,   $ortho,   "test $i: ortho" );
	is_deeply( \@glFrustum, $frustum, "test $i: frustum" );
}

done_testing;
