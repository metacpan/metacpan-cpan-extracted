# -*- perl -*-

use Test::More tests => 6;
use IO::Socket::INET;

BEGIN { use_ok( 'Storable::CouchDB' ); }

my $s = Storable::CouchDB->new;
isa_ok ($s, 'Storable::CouchDB');

SKIP: {
  skip "CouchDB not found.", 4 unless IO::Socket::INET->new("127.0.0.1:5984");
diag("hash");

diag("delete");
$return=$s->delete('mydockey');
diag explain $return;
isa_ok($return, "HASH", "always a hash return");
is(scalar(keys %$return), 1, 'sizeof');
is((keys(%$return))[0], "Hello", "Keys");
is($return->{"Hello"}, "World!", "Values");
}
