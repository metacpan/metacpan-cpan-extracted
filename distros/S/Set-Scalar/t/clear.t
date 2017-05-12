use Set::Scalar;

print "1..2\n";

my $s = Set::Scalar->new(0..99);

$s->clear;

print "not " unless $s->is_null;
print "ok 1\n";

print "not " unless $s->members == 0;
print "ok 2\n";

