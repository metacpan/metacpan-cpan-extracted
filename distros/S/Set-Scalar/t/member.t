use Set::Scalar;

print "1..3\n";

my $s = Set::Scalar->new(qw(a b c 0));

print "not " unless $s->member('a') eq 'a';
print "ok 1\n";

print "not " unless $s->element('0') eq '0';
print "ok 2\n";

print "not " if defined $s->member('1');
print "ok 3\n";

