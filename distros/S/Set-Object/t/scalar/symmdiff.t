use Set::Object;

print "1..21\n";

my $a = Set::Object->new("a".."e");
my $b = Set::Object->new("c".."g");

my $d = $a->symmetric_difference($b);

print "not " unless $d eq "Set::Object(a b f g)";
print "ok 1\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 2\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 3\n";

my $e = $a % $b;

print "not " unless $e eq "Set::Object(a b f g)";
print "ok 4\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 5\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 6\n";

my $f = $b->symmetric_difference($a);

print "not " unless $f eq "Set::Object(a b f g)";
print "ok 7\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 8\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 9\n";

my $g = $b % $a;

print "not " unless $g eq "Set::Object(a b f g)";
print "ok 10\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 11\n";

print "not " unless $b eq "Set::Object(c d e f g)";
print "ok 12\n";

my $h = $a % "x";

print "not " unless $h eq "Set::Object(a b c d e x)";
print "ok 13\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 14\n";

my $i = "y" % $a;

print "not " unless $i eq "Set::Object(a b c d e y)";
print "ok 15\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 16\n";

my $j = $a % "c";

print "not " unless $j eq "Set::Object(a b d e)";
print "ok 17\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 18\n";

my $k = "e" % $a;

print "not " unless $k eq "Set::Object(a b c d)";
print "ok 19\n";

print "not " unless $a eq "Set::Object(a b c d e)";
print "ok 20\n";

my $l = Set::Object->new("a", "b");
my $m = Set::Object->new("b", "c");

print "not " unless $l % $m eq "Set::Object(a c)";
print "ok 21\n";
