use Set::Scalar;

print "1..24\n";

my $a = Set::Scalar->new("a".."e");
my $b = Set::Scalar->new("c".."g");

my $d = $a->intersection($b);

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

{
	# Josh@allDucky.com
	my $x = new Set::Scalar(1,2,3);
	my $y = new Set::Scalar(1,2,3,5);
	my $i = $x->intersection($y);
	$i->insert(4);
	print "not " unless $x eq "(1 2 3)";
	print "ok 21\n";
	print "not " unless $i eq "(1 2 3 4)";
	print "ok 22\n";
	print "not " unless $y eq "(1 2 3 5)";
	print "ok 23\n";
}

print "not " unless join("", sort @{
	new Set::Scalar \$1,\$2,\$3,->intersection(
		new Set::Scalar \$2,\$3,\$4
	)
}) eq join "", sort \$2,\$3;
print "ok 24\n";



