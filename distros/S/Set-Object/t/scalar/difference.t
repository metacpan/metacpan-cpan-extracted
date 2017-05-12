
use Set::Object;
print "1..28\n";

sub check {
    my ($test, $ok) = @_;
    if ($ok) {
        print "ok $test\n";
    } else {
        print "not ok $test\n";
    }
}

my $a = Set::Object->new("a".."e");
my $b = Set::Object->new("c".."g");

my $d = $a->difference($b);

check(  1, $d eq "Set::Object(a b)" );
check(  2, $a eq "Set::Object(a b c d e)" );
check(  3, $b eq "Set::Object(c d e f g)" );

my $e = $a - $b;

check(  4, $e eq "Set::Object(a b)" );
check(  5, $a eq "Set::Object(a b c d e)" );
check(  6, $b eq "Set::Object(c d e f g)" );

my $f = $b->difference($a);

check(  7, $f eq "Set::Object(f g)" );
check(  8, $a eq "Set::Object(a b c d e)" );
check(  9, $b eq "Set::Object(c d e f g)" );

my $g = $b - $a;

check( 10, $g eq "Set::Object(f g)" );
check( 11, $a eq "Set::Object(a b c d e)" );
check( 12, $b eq "Set::Object(c d e f g)" );

my $h = $a - "x";

check( 13, $h eq "Set::Object(a b c d e)" );
check( 14, $a eq "Set::Object(a b c d e)" );

my $i = "y" - $a;

check( 15, $i eq "Set::Object(y)" );
check( 16, $a eq "Set::Object(a b c d e)" );

my $j = $a - "c";

check( 17, $j eq "Set::Object(a b d e)" );
check( 18, $a eq "Set::Object(a b c d e)" );

my $k = "e" - $a;

check( 19, $k eq "Set::Object()" );
check( 20, $a eq "Set::Object(a b c d e)" );

my $m = Set::Object->new();
my $n = Set::Object->new();
my $o = $m - $n;

check( 21, defined($m) && ref($m) && $m->isa("Set::Object") );
check( 22, defined($n) && ref($n) && $n->isa("Set::Object") );

check( 23, $m eq $n );
check( 24, $n eq $o );
check( 25, $o eq $m );
check( 26, $m == $n );
check( 27, $n == $o );
check( 28, $o == $m );


sub show {
    my $z = shift;

    print "# set: ".sprintf("SV = %x, addr = %x", Set::Object::refaddr($z), $$z)."\b";
    print "# size is: ",($z->size),"\n";
    print "# stringified: $z\n";
    print "# universe is: ",($z->universe),"\n";
}

