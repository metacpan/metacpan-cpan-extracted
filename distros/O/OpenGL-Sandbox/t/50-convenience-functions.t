#! /usr/bin/env perl
use strict;
use warnings;
use Try::Tiny;
use Test::More;

use OpenGL::Sandbox qw( :all );
my $gl= eval { make_context; };
SKIP: {
	skip "GL context not available", 4 unless current_context;
	for (qw( next_frame get_gl_errors log_gl_errors warn_gl_errors )) {
		ok( eval("$_; 1"), "$_ didn't die" ) or diag $@;
	}
}
undef $gl;

done_testing;
