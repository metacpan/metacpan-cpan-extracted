# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Rose::DBx::Object::Cached::FastMmap' ); }

my $object = Rose::DBx::Object::Cached::FastMmap->new ();
isa_ok ($object, 'Rose::DBx::Object::Cached::FastMmap');


