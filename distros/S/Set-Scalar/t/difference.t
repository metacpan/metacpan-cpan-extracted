use Set::Scalar;

print "1..28\n";

sub check {
    my ($test, $ok) = @_;
    if ($ok) {
        print "ok $test\n";
    } else {
        print "not ok $test\n";
    }
}

my $a = Set::Scalar->new("a".."e");
my $b = Set::Scalar->new("c".."g");

my $d = $a->difference($b);

check(  1, $d eq "(a b)" );
check(  2, $a eq "(a b c d e)" );
check(  3, $b eq "(c d e f g)" );

my $e = $a - $b;

check(  4, $e eq "(a b)" );
check(  5, $a eq "(a b c d e)" );
check(  6, $b eq "(c d e f g)" );

my $f = $b->difference($a);

check(  7, $f eq "(f g)" );
check(  8, $a eq "(a b c d e)" );
check(  9, $b eq "(c d e f g)" );

my $g = $b - $a;

check( 10, $g eq "(f g)" );
check( 11, $a eq "(a b c d e)" );
check( 12, $b eq "(c d e f g)" );

my $h = $a - "x";

check( 13, $h eq "(a b c d e)" );
check( 14, $a eq "(a b c d e)" );

my $i = "y" - $a;

check( 15, $i eq "(y)" );
check( 16, $a eq "(a b c d e)" );

my $j = $a - "c";

check( 17, $j eq "(a b d e)" );
check( 18, $a eq "(a b c d e)" );

my $k = "e" - $a;

check( 19, $k eq "()" );
check( 20, $a eq "(a b c d e)" );

my $m = new Set::Scalar();
my $n = new Set::Scalar();
my $o = $m - $n;

check( 21, defined($m) && ref($m) && $m->isa("Set::Scalar") );
check( 22, defined($n) && ref($n) && $n->isa("Set::Scalar") );

check( 23, $m eq $n );
check( 24, $n eq $o );
check( 25, $o eq $m );
check( 26, $m == $n );
check( 27, $n == $o );
check( 28, $o == $m );


