use Set::Scalar;

use strict;

print "1..49\n";

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

$s->insert("a");

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

$s->insert("a");

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

$s->insert("b", "c", "d", "e");

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

$s->delete("b", "d");

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

$s->invert("b", "c", "d");

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

$s->fill();

print "not " unless $s->size == 5;
print "ok 31\n";

print "not " if $s->is_null;
print "ok 32\n";

print "not " unless $s->is_universal;
print "ok 33\n";

print "not " unless $s eq "(a b c d e)";
print "ok 34\n";

print "not " unless $s->universe eq "[a b c d e]";
print "ok 35\n";

$s->clear();

print "not " unless $s->size == 0;
print "ok 36\n";

print "not " unless $s->is_null;
print "ok 37\n";

print "not " if $s->is_universal;
print "ok 38\n";

print "not " unless $s eq "()";
print "ok 39\n";

print "not " unless $s->universe eq "[a b c d e]";
print "ok 40\n";

eval { $s->clear("x") };

print "not " unless $@ =~ /\Q::clear(): need no arguments/;
print "ok 41\n";

eval { $s->fill("y") };

print "not " unless $@ =~ /\Q::fill(): need no arguments/;
print "ok 42\n";

$s->insert("a".."e");

print "not " unless "@{ [ sort $s->members ] }" eq "a b c d e";
print "ok 43\n";

print "not " unless "@{ [ sort @$s ] }" eq "a b c d e";
print "ok 44\n";

my $t = Set::Scalar->new(@$s);

print "not " unless "@{ [ sort @$t ] }" eq "a b c d e";
print "ok 45\n";

$t += "f";

print "not " unless "@{ [ sort @$t ] }" eq "a b c d e f";
print "ok 46\n";

my $u = $t;

print "not " unless "@{ [ sort @$u ] }" eq "a b c d e f";
print "ok 47\n";

$t += "g";

print "not " unless "@{ [ sort @$t ] }" eq "a b c d e f g";
print "ok 48\n";

print "not " unless "@{ [ sort @$u ] }" eq "a b c d e f";
print "ok 49\n";

# End Of File.
