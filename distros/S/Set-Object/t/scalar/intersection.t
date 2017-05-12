
use Set::Object;
print "1..20\n";

my $a = Set::Object->new("a".."e");
my $b = Set::Object->new("c".."g");

my $d = $a->intersection($b);

Set::Object->as_string_callback(sub { my $self = shift; "(".join(" ", sort $self->members).")" });

print "not " unless $d eq "(c d e)";
print "ok 1\n";

print "not " unless $a eq "(a b c d e)";
print "ok 2\n";

print "not " unless $b eq "(c d e f g)";
print "ok 3\n";

my $e = $a * $b;

print "not " unless $e eq "(c d e)";
print "ok 4\n";

print "not " unless $a eq "(a b c d e)";
print "ok 5\n";

print "not " unless $b eq "(c d e f g)";
print "ok 6\n";

my $f = $b->intersection($a);

print "not " unless $f eq "(c d e)";
print "ok 7\n";

print "not " unless $a eq "(a b c d e)";
print "ok 8\n";

print "not " unless $b eq "(c d e f g)";
print "ok 9\n";

my $g = $b * $a;

print "not " unless $g eq "(c d e)";
print "ok 10\n";

print "not " unless $a eq "(a b c d e)";
print "ok 11\n";

print "not " unless $b eq "(c d e f g)";
print "ok 12\n";

my $h = $a * "x";

print "not " unless $h eq "()";
print "ok 13\n";

print "not " unless $a eq "(a b c d e)";
print "ok 14\n";

my $i = "y" * $a;

print "not " unless $i eq "()";
print "ok 15\n";

print "not " unless $a eq "(a b c d e)";
print "ok 16\n";

my $j = $a * "c";

print "not " unless $j eq "(c)";
print "ok 17\n";

print "not " unless $a eq "(a b c d e)";
print "ok 18\n";

my $k = "e" * $a;

print "not " unless $k eq "(e)";
print "ok 19\n";

print "not " unless $a eq "(a b c d e)";
print "ok 20\n";




