use Set::Scalar;
use Set::Scalar::Universe;

use strict;

print "1..7\n";

my $s1 = Set::Scalar->new("a".."e");

my $u1 = $s1->universe;

my $u2 = Set::Scalar::Universe->new;

$u2->enter;

my $s2 = Set::Scalar->new("f".."j");

print "not " if $u1 == $u2;
print "ok 1\n";

print "not " unless $s1->universe eq "[a b c d e]";
print "ok 2\n";

print "not " unless $s2->universe eq "[f g h i j]";
print "ok 3\n";

my $u3 = Set::Scalar::Universe->new("a".."e");

print "not " if $s1->universe == $u3;
print "ok 4\n";

$u3->extend("x");

print "not " unless $u3 eq "[a b c d e x]";
print "ok 5\n";

print "not " unless "$u1" eq "[a b c d e]";
print "ok 6\n";

print "not " unless "$u2" eq "[f g h i j]";
print "ok 7\n";

# End Of File.
