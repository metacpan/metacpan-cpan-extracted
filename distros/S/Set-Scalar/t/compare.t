use Set::Scalar;

use strict;

my $t = Set::Scalar->new(qw(a b c));
my $u = Set::Scalar->new(qw(a b c));
my $v = Set::Scalar->new(qw(d e f));
my $w = Set::Scalar->new(qw(a b));
my $x = Set::Scalar->new(qw(b c d));
my $n = Set::Scalar->new(qw());
my $o = Set::Scalar->new(qw());

print "1..23\n";

print "not " unless $t == $u;
print "ok 1\n";

print "not " unless $t != $v;
print "ok 2\n";

print "not " if $t == $v;
print "ok 3\n";

print "not " if $t == $w;
print "ok 4\n";

print "not " unless $t > $w;
print "ok 5\n";

print "not " unless $w < $t;
print "ok 6\n";

print "not " unless $t >= $u;
print "ok 7\n";

print "not " unless $t <= $u;
print "ok 8\n";

print "not " unless $t >= $w;
print "ok 9\n";

print "not " unless $w <= $t;
print "ok 10\n";

print "not " unless $t == "(a b c)";
print "ok 11\n";

print "not " unless "(a b c)" == $u;
print "ok 12\n";

print "not " unless $t->compare($x) eq 'proper intersect';
print "ok 13\n";

print "not " unless $t->compare($v) eq 'disjoint';
print "ok 14\n";

print "not " unless $t > $n;
print "ok 15\n";

print "not " unless $n < $t;
print "ok 16\n";

print "not " unless $n == $o;
print "ok 17\n";

print "not " unless $o == $n;
print "ok 18\n";

print "not " if $n < $o;
print "ok 19\n";

print "not " if $n > $o;
print "ok 20\n";

print "not " unless $n <= $o;
print "ok 21\n";

print "not " unless $n >= $o;
print "ok 22\n";

# [cpan #5829] d
{
  my @d = $t->is_disjoint($v) ;
  print "not " unless @d == 1 && $d[0];
  print "ok 23\n";
}
