# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;


BEGIN { use_ok( 'Profile::Log' ); }

my $object = Profile::Log->new ();
isa_ok ($object, 'Profile::Log', "Profile::Log->new");

