use Set::Scalar 0.9;

use strict;

$| = 1;

print STDERR "# (WARNING: this can take awhile)...\n";

my $t = 1;

use Carp;

sub bite_dust { confess @_ }

local $SIG{__DIE__ } = \&bite_dust;

my $a = Set::Scalar->new("a", "b", "c");
my $b = Set::Scalar->new("c", "d", "e");
my $c = Set::Scalar->new("e", "f", "g");
my $n = $a->null;
my $u = $a->universe;

sub check {
    my ($l, $p, $q, $x, $y, $z) = @_;

    print "# $l\n";
    unless ($p == $q || ($p->size == 0 && $p->size == $q->size)) {
        print "# got $p, expected $q\n";
        print "# x = $x, y = $y, z = $z, n = $n, u = $u\n";
	print "not $t\n";
	exit(1);
    }
    print "ok ", $t++, "\n";
}

my @a = ($a, $b, $c, $n, $u);

print "1..", 19 * @a ** 3, "\n";

for my $x ( @a ) {
    for my $y ( @a ) {
	for my $z ( @a ) {

#  --X == X
#	    print "# --x = ", -(-$x), "\n";
#	    print "#   x = ",    $x , "\n";
	    &check('Double Complement', -(-$x), $x,		$x, $y, $z);

#  -(X + Y) == -X * -Y
#	    print "# -(x +  y) = -(", $x, " + ", $y, ")  = ", -($x + $y), "\n";
#	    print "#  -x * -y  = ", -$x, " * ", -$y, " = ", -$x * -$y, "\n";
	    &check('DeMorgan -+', -($x + $y), -$x * -$y,		$x, $y, $z);

#  -(X * Y) == -X + -Y
#	    print "# -(x *  y) = -(", $x, " * ", $y, ")  = ", -($x * $y), "\n";
#	    print "#  -x + -y  = ", -$x, " + ", -$y, " = ", -$x + -$y, "\n";
	    &check('DeMorgan -*', -($x * $y), -$x + -$y,	$x, $y, $z);

#  X + Y == Y + X
#	    print "# x + y = ", $x + $y, "\n";
#	    print "# y + x = ", $y + $x, "\n";
	    &check('Commutative +', $x + $y, $y + $x,		$x, $y, $z);

#  X * Y == Y * X
#	    print "# x * y = ", $x * $y, "\n";
#	    print "# y * x = ", $y * $x, "\n";
	    &check('Commutative *', $x * $y, $y * $x,		$x, $y, $z);

#  X + (Y + Z) == (X + Y) + Z
#	    print "# x + (y + z) = ", $x + ($y + $z), "\n";
#	    print "# (x + y) + z = ", ($x + $y) + $z, "\n";
	    &check('Associative +', $x + ($y + $z), ($x + $y) + $z,		$x, $y, $z);

#  X * (Y * Z) == (X * Y) * Z
#	    print "#     (y * z) = ", ($y * $z),      "\n";
#	    print "# x * (y * z) = ", $x * ($y * $z), "\n";
#	    print "# (x * y)     = ", ($x * $y),      "\n";
#	    print "# (x * y) * z = ", ($x * $y) * $z, "\n";
	    &check('Associative *', $x * ($y * $z), ($x * $y) * $z,		$x, $y, $z);

#  X + (Y * Z) == (X + Y) * (X + Z)
#	    print "#     y * z = ", $y * $z, "\n";
#	    print "#     x + y = ", $x + $y, "\n";
#	    print "#     x + z = ", $x + $z, "\n";
#	    print "# x + (y * z)       = ", $x + ($y * $z), "\n";
#	    print "# (x + y) * (x + z) = ", ($x + $y) * ($x + $z), "\n";
	    &check('Distributive +*', $x + ($y * $z), ($x + $y) * ($x + $z),	$x, $y, $z);

#  X * (Y + Z) == (X * Y) + (X * Z)
#	    print "# y + z = ", $y + $z, "\n";
#	    print "# x * y = ", $x * $y, "\n";
#	    print "# x * z = ", $x * $z, "\n";
#	    print "# x * (y + z)       = ", $x * ($y + $z), "\n";
#	    print "# (x * y) + (x * z) = ", ($x * $y) + ($x * $z), "\n";
	    &check('Distributive *+', $x * ($y + $z), ($x * $y) + ($x * $z),	$x, $y, $z);

#  X + X == X
#	    print "# x + x = ", $x + $x, "\n";
#	    print "# x     = ", $x,      "\n";
	    &check('Idempotency +', $x + $x, $x,	$x, $y, $z);

#  X * X == X
#	    print "# x * x = ", $x * $x, "\n";
#	    print "# x     = ", $x,      "\n";
	    &check('Idempotency *', $x * $x, $x,	$x, $y, $z);

#	    print "# x + n = ", $x + $n, "\n";
#	    print "# x     = ", $x,      "\n";
#  X + N == X
	    &check('Identity +N', $x + $n, $x,		$x, $y, $z);

#  X * U == X
#	    print "# x * u = ", $x * $u, "\n";
#	    print "# x     = ", $x,      "\n";
	    &check('Identity *U', $x * $u, $x,		$x, $y, $z);

#  X + -X == U
#	    print "# x + -x = ", $x + -$x, "\n";
#	    print "# u      = ", $u,       "\n";

	    &check('Inverse +-', $x + -$x, $u,		$x, $y, $z);

#  X * -X == N
#	    print "# x * -x = ", $x * -$x, "\n";
#	    print "# n      = ", $n,       "\n";
	    &check('Inverse *-', $x * -$x, $n,		$x, $y, $z);

#  X + U == U
#	    print "# x + u = ", $x + $u, "\n";
#	    print "# u     = ", $u,      "\n";
	    &check('Domination +U', $x + $u, $u,		$x, $y, $z);

#  X * N == N
#	    print "# x * u = ", $x * $n, "\n";
#	    print "# n     = ", $n,      "\n";
	    &check('Domination *N', $x * $n, $n,	$x, $y, $z);

# X + (X * Y) == X
#	    print "# x + (x * y) = ", $x + ($x * $y), "\n";
#	    print "# x           = ", $x,             "\n";
	    &check('Absorption +*', $x + ($x * $y), $x,		$x, $y, $z);

# X * (X + Y) == X
#	    print "# x * (x + y) = ", $x * ($x + $y), "\n";
#	    print "# x           = ", $x,             "\n";
	    &check('Absorption *+', $x * ($x + $y), $x,		$x, $y, $z);
	}
    }
}
