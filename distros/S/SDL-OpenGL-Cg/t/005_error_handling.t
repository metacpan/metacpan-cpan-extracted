# -*- perl -*-

use Test::More tests => 9;

BEGIN { use_ok( 'SDL::OpenGL::Cg', qw/:all/ ); }

my $object = SDL::OpenGL::Cg->new ();
isa_ok ($object, 'SDL::OpenGL::Cg');

is(cgGetError(), CG_NO_ERROR());
is(cgGetErrorString(), "CG ERROR : No error has occurred.");

cgEnableProfile(-1001);
is(cgGetError(), CG_INVALID_PROFILE_ERROR());
is(cgGetError(), CG_NO_ERROR());
is(cgGetErrorString(), "CG ERROR : No error has occurred.");

cgEnableProfile(-1001);
is(cgGetErrorString(), "CG ERROR : The profile is not supported.");
is(cgGetErrorString(), "CG ERROR : No error has occurred.");
