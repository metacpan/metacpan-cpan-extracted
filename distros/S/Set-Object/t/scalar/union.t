use Set::Object;

print "1..16\n";

my $a = Set::Object->new("a".."e");
my $b = Set::Object->new("c".."g");

my $d = $a->union($b);

print "not " unless $d eq "Set::Object(a b c d e f g)";
print "ok 1\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 2\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 3\n";

my $e = $a + $b;

print "not " unless $e eq "Set::Object(a b c d e f g)";
print "ok 4\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 5\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 6\n";

my $f = $b->union($a);

print "not " unless $f eq "Set::Object(a b c d e f g)";
print "ok 7\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 8\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 9\n";

my $g = $b + $a;

print "not " unless $g eq "Set::Object(a b c d e f g)";
print "ok 10\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 11\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 12\n";

my $h = $a + "x";

print "not " unless $h eq "Set::Object(a b c d e x)";
print "ok 13\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 14\n";

my $i = "y" + $a;

print "not " unless $i eq "Set::Object(a b c d e y)";
print "ok 15\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 16\n";

