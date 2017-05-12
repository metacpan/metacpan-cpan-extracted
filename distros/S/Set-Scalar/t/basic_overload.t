use Set::Scalar;

use strict;

print "1..40\n";

my $s = Set::Scalar->new;

print "not " unless $s->size == 0;
print "ok 1\n";

print "not " unless $s->is_null;
print "ok 2\n";

print "not " unless $s->is_universal;
print "ok 3\n";

print "not " unless $s eq "()";
print "ok 4\n";

print "not " unless $s->universe eq "[]";
print "ok 5\n";

$s += "a";

print "not " unless $s->size == 1;
print "ok 6\n";

print "not " if $s->is_null;
print "ok 7\n";

print "not " unless $s->is_universal;
print "ok 8\n";

print "not " unless $s eq "(a)";
print "ok 9\n";

print "not " unless $s->universe eq "[a]";
print "ok 10\n";

$s += "a";

print "not " unless $s->size == 1;
print "ok 11\n";

print "not " if $s->is_null;
print "ok 12\n";

print "not " unless $s->is_universal;
print "ok 13\n";

print "not " unless $s eq "(a)";
print "ok 14\n";

print "not " unless $s->universe eq "[a]";
print "ok 15\n";

$s += "b";
$s += "c";
$s += "d";
$s += "e";

print "not " unless $s->size == 5;
print "ok 16\n";

print "not " if $s->is_null;
print "ok 17\n";

print "not " unless $s->is_universal;
print "ok 18\n";

print "not " unless $s eq "(a b c d e)";
print "ok 19\n";

print "not " unless $s->universe eq "[a b c d e]";

print "ok 20\n";

$s -= "b";
$s -= "d";

print "not " unless $s->size == 3;
print "ok 21\n";

print "not " if $s->is_null;
print "ok 22\n";

print "not " if $s->is_universal;
print "ok 23\n";

print "not " unless $s eq "(a c e)";
print "ok 24\n";

print "not " unless $s->universe eq "[a b c d e]";

print "ok 25\n";

$s /= "b";
$s /= "c";
$s /= "d";

print "not " unless $s->size == 4;
print "ok 26\n";

print "not " if $s->is_null;
print "ok 27\n";

print "not " if $s->is_universal;
print "ok 28\n";

print "not " unless $s eq "(a b d e)";
print "ok 29\n";

print "not " unless $s->universe eq "[a b c d e]";
print "ok 30\n";

my $t = $s;

print "not " unless $t->size == 4;
print "ok 31\n";

print "not " if $t->is_null;
print "ok 32\n";

print "not " if $t->is_universal;
print "ok 33\n";

print "not " unless $t eq "(a b d e)";
print "ok 34\n";

print "not " unless $t->universe eq "[a b c d e]";
print "ok 35\n";

$t = $t + 'f';

print "not " unless $t eq "(a b d e f)";
print "ok 36\n";

print "not " unless $t->universe eq "[a b c d e f]";
print "ok 37\n";

print "not " unless $s eq "(a b d e)";
print "ok 38\n";

print "not " unless $s->universe eq "[a b c d e f]";
print "ok 39\n";

my $a = Set::Scalar->new();
adder(2);
adder(3);
adder(34);
sub adder {
  my $e = shift;
  $a = $a + $e;
}
print "not " unless $a eq "(2 3 34)";
print "ok 40\n";

# End Of File.
