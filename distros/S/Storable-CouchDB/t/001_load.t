# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 7;

BEGIN { use_ok( 'Storable::CouchDB' ); }

my $s = Storable::CouchDB->new;
isa_ok ($s, 'Storable::CouchDB');

ok($s->can("store"), "can store");
ok($s->can("delete"), "can delete");
ok($s->can("retrieve"), "can retrieve");
ok($s->can("uri"), "can uri");
ok($s->can("db"), "can db");
