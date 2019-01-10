#! /usr/bin/env perl
use strict;
use warnings;
use Try::Tiny;
use Test::More;

use_ok( 'OpenGL::Sandbox' ) or BAIL_OUT;
ok( eval { OpenGL::Sandbox->import('make_context') ; 1 } && main->can('make_context'), 'import local symbol' );
ok( eval { OpenGL::Sandbox->import('GL_TRUE')      ; 1 } && main->can('GL_TRUE') && GL_TRUE(), 'import GL constant' );
ok( eval { OpenGL::Sandbox->import('glBindTexture'); 1 } && main->can('glBindTexture'),'import GL function' );

SKIP: {
	skip "GLX not available", 1 unless eval { require X11::GLX::DWIM; };
	ok( eval { require OpenGL::Sandbox::ContextShim::GLX; 1 }, 'Load context shim GLX' );
}
SKIP: {
	skip "SDL not available", 1 unless eval { require SDLx::App; };
	ok( eval { require OpenGL::Sandbox::ContextShim::SDL; 1 }, 'Load context shim SDL' );
}
SKIP: {
	skip "GLFW not available", 1 unless eval { require OpenGL::GLFW; };
	ok( eval { require OpenGL::Sandbox::ContextShim::GLFW; 1 }, 'Load context shim GLFW' );
}

done_testing;
