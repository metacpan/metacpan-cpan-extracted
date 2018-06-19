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
use OpenGL::Sandbox::V1 'color_parts';

is_deeply( [ color_parts([ .25, .5, .75, 1 ]) ], [ .25, .5, .75, 1 ], 'read array' );
is_deeply( [ color_parts(.75, .5, .25, .5) ], [ .75, .5, .25, .5 ], 'read list' );
is_deeply( [ color_parts('#00FF00') ], [ 0, 1, 0, 1 ], 'parse HTML' );
is_deeply( [ color_parts('#00FF0011') ], [ 0, 1, 0, 0x11/255.0 ], 'parse HTML with alpha' );

done_testing;
