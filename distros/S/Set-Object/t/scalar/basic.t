
use Set::Object;
use Test::More tests => 24;

use strict;

my $s = Set::Object->new;

is($s->size, 0, "new set size is 0");
ok($s->is_null, "->is_null()");
is($s, "Set::Object()", "stringify");

$s->insert("a");

is($s->size, 1, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(a)", "stringify");

$s->insert("a");

is($s->size, 1, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(a)", "stringify");

$s->insert("b", "c", "d", "e");

is($s->size, 5, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(a b c d e)", "stringify");

$s->delete("b", "d");

is($s->size, 3, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(a c e)", "stringify");

$s->invert("b", "c", "d");

is($s->size, 4, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(a b d e)", "stringify");

$s->clear();

is($s->size, 0, "->size() [scalar]");
ok($s->is_null, "->is_null() [scalar]");
is($s, "Set::Object()", "stringify");

# End Of File.

$s->invert("b", "c", "d");

is($s->size, 3, "->size() [scalar]");
ok(!$s->is_null, "->is_null() [scalar]");
is($s, "Set::Object(b c d)", "stringify");


