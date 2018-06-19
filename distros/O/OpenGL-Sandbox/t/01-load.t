#! /usr/bin/env perl
use strict;
use warnings;
use Try::Tiny;
use Test::More;

use_ok( 'OpenGL::Sandbox' ) or BAIL_OUT;
ok( eval { OpenGL::Sandbox->import('make_context') ; 1 } && main->can('make_context'), 'import local symbol' );
ok( eval { OpenGL::Sandbox->import('GL_TRUE')      ; 1 } && main->can('GL_TRUE') && GL_TRUE(), 'import GL constant' );
ok( eval { OpenGL::Sandbox->import('glBindTexture'); 1 } && main->can('glBindTexture'),'import GL function' );

done_testing;
