
use Set::Object;

use Test::More tests => 18;

use strict;

my $s = Set::Object->new;

is($s->size, 0, "new set size is 0");
ok($s->is_null, "->is_null()");
is($s, "Set::Object()", "stringify");

$s += "a";

is($s->size, 1, "->size()");
ok(!$s->is_null, "->is_null()");
is($s, "Set::Object(a)", "stringify");

$s += "a";

is($s->size, 1, "->size()");
ok(!$s->is_null, "->is_null()");
is($s, "Set::Object(a)", "stringify");

$s += "b";
$s += "c";
$s += "d";
$s += "e";

is($s->size, 5, "->size()");
ok(!$s->is_null, "->is_null()");
is($s, "Set::Object(a b c d e)", "stringify");

$s -= "b";
$s -= "d";

is($s->size, 3, "->size()");
ok(!$s->is_null, "->is_null()");
is($s, "Set::Object(a c e)", "stringify");

$s /= "b";
$s /= "c";
$s /= "d";

is($s->size, 4, "->size()");
ok(!$s->is_null, "->is_null()");
is($s, "Set::Object(a b d e)", "stringify");

