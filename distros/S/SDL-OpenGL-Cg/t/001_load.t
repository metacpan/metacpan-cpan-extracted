# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'SDL::OpenGL::Cg' ); }

my $object = SDL::OpenGL::Cg->new ();
isa_ok ($object, 'SDL::OpenGL::Cg');


