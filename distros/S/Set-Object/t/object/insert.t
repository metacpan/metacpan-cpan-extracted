# -*- perl -*-

use Set::Object;

require 't/object/Person.pm';
package Person;
use Test::More tests => 18;

populate();

$simpsons = Set::Object->new;

is($simpsons->size(), 0, "Set::Object->size() [ no contents ]");

$added = $simpsons->insert($homer);
is($added, 1, "Set::Object->insert() [ returned # added ]");
is($simpsons->size(), 1, "Set::Object->size() [ one member ]");

$added = $simpsons->insert($homer);
is($added, 0, "Set::Object->insert() [ returned # added ]");
is($simpsons->size(), 1, "Set::Object->size() [ one member ]");

$added = $simpsons->insert($marge);
is($added, 1, "Set::Object->insert() [ returned # added ]");
is($simpsons->size(), 2, "Set::Object->size() [ two members ]");

$simpsons->insert($maggie, $homer, $bart, $marge, $bart, $lisa, $lisa, $maggie);
is($simpsons->size(), 5, "Set::Object->size() [ lots of inserts ]");

# Now be really abusive
#eval { $simpsons->insert("bogon") };
#like($@, qr/Tried to insert/i, "Caught feeding in a bogon OK");
#

my $test = new Set::Object;
eval { $test->insert("bogon"); };
is ( $test."", "Set::Object(bogon)", "as_string on bogon-ified set");

eval { $simpsons->remove("bogon"); };

# array refs
my $array;
$test->insert($array = [ "array", "ref" ]);
my $array2 = [ "array", "ref" ];

$test->insert($array);
is ($test->size(), 2, "Inserted an array OK");
ok ($test->includes($array), "Can put non-objects in a set");
ok ($test->includes("bogon"), "Can put scalars in a set");
ok (!$test->includes($array2), "Lookup of identical item doesn't work");

like ( $test."", qr/Set::Object\(ARRAY/, "Inserted an array OK");

# hash refs
$test->clear();
my $hash;
$test->insert($hash = { "hash" => "ref" });
my $hash2 = { "hash" => "ref" };

$test->insert($hash);
is ($test->size(), 1, "Inserted an hash OK");
ok ($test->includes($hash), "Can put non-objects in a set");
ok (!$test->includes($hash2), "Lookup of identical item doesn't work");

like ( $test."", qr/Set::Object\(HASH/, "Inserted an array OK");

