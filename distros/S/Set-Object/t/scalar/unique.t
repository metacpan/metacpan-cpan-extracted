use Set::Object;

print "1..4\n";

my $a = Set::Object->new("a".."e");
my $b = Set::Object->new("c".."g");
my $c = Set::Object->new();

my $d = $a->unique($b);

print "not " unless $d eq "Set::Object(a b f g)";
print "ok 1\n";

my $e = $b->unique($a);

print "not " unless $e eq "Set::Object(a b f g)";
print "ok 2\n";

my $f = $a->unique($c);

print "not " unless $f eq $a;
print "ok 3\n";

my $g = $a->unique($a);

print "not " unless $g eq "Set::Object()";
print "ok 4 # $g\n";





