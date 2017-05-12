use Set::Scalar;

print "1..4\n";

my $a = Set::Scalar->new("a".."e");
my $b = Set::Scalar->new("c".."g");
my $c = Set::Scalar->new();

my $d = $a->unique($b);

print "not " unless $d eq "(a b f g)";
print "ok 1\n";

my $e = $b->unique($a);

print "not " unless $e eq "(a b f g)";
print "ok 2\n";

my $f = $a->unique($c);

print "not " unless $f eq $a;
print "ok 3\n";

my $g = $a->unique($a);

print "not " unless $g eq "()";
print "ok 4 # $g\n";





