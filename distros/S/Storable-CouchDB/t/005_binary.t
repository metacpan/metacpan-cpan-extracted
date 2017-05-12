# -*- perl -*-

use Test::More tests => 14;
use IO::Socket::INET;

BEGIN { use_ok( 'Storable::CouchDB' ); }

my $s = Storable::CouchDB->new;
isa_ok ($s, 'Storable::CouchDB');

my $key="varable-test";

SKIP: {
  skip "CouchDB not found.", 12 unless IO::Socket::INET->new("127.0.0.1:5984");
diag("hash");

foreach my $value ("\n", "\r", "\x00abc") { #stored as UTF8
  {
    my $data=$s->store($key=>{a=>$value}); #overwrites or creates if not exists
    diag explain $data;
    is(ref($data), "HASH", "return");
    is($data->{"a"}, $value, "Values");
  }
  {
    my $data=$s->retrieve($key);
    diag explain $data;
    is(ref($data), "HASH", "return");
    is($data->{"a"}, $value, "Values");
  }
}
}
