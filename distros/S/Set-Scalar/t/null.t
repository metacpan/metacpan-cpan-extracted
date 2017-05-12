use Set::Scalar;

my $s0 = Set::Scalar->new;
my $s1 = Set::Scalar->new(qw(a b c));

print "1..8\n";

print $s0->is_null  ? "ok 1\n"     : "not ok 1\n";
print $s1->is_null  ? "not ok 2\n" : "ok 2\n";

print $s0->is_empty ? "ok 3\n"     : "not ok 3\n";
print $s1->is_empty ? "not ok 4\n" : "ok 4\n";

print $s0 == $s0->null  ? "ok 5\n"     : "not ok 5\n";
print $s1 == $s1->null  ? "not ok 6\n" : "ok 6\n";

print $s0 == $s0->empty ? "ok 7\n"     : "not ok 7\n";
print $s1 == $s0->empty ? "not ok 8\n" : "ok 8\n";

 

