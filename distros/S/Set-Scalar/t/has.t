use Set::Scalar;

print "1..3\n";

my $s = Set::Scalar->new(qw(a b c 0));

print "not " unless $s->has('a');
print "ok 1\n";

print "not " unless $s->contains('0');
print "ok 2\n";

print "not " if $s->has('1');
print "ok 3\n";

