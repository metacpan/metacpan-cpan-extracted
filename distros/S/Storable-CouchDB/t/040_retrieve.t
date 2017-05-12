# -*- perl -*-

use Test::More tests => 3;
use IO::Socket::INET;

BEGIN { use_ok( 'Storable::CouchDB' ); }

my $s = Storable::CouchDB->new;
isa_ok ($s, 'Storable::CouchDB');

SKIP: {
  skip "CouchDB not found.", 1 unless IO::Socket::INET->new("127.0.0.1:5984");
diag("hash");

diag("retrieve");
$return=$s->retrieve('mydockey');
diag explain $return;
is($return, undef, "undef when not exists");
}
