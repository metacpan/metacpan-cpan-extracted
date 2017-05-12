use Set::Scalar;

print "1..9\n";

my $a = Set::Scalar->new(1..2);
my $b = Set::Scalar->new(3..5);

my $c = $a->cartesian_product($b);
my $d = Set::Scalar->cartesian_product($a, $b);
my $e = $a->cartesian_product($a);
my $f = $a->cartesian_product();
my $g = Set::Scalar->cartesian_product($a, $b, $b);
my $h = Set::Scalar->cartesian_product($a, $c);

print "not " unless $c->members == 6;
print "ok 1\n";

print "not " unless $d->members == 6;
print "ok 2\n";

print "not " unless $e->members == 4;
print "ok 3\n";

print "not " unless $f->members == 2;
print "ok 4\n";

sub verify {
    my ($p, @q) = @_;
    my @p = $p->members;
    return unless @p == @q;
    my %p; @p{ map { "@$_" } @p } = @p;
    my %q; @q{ map { "@$_" } @q } = @q;
    my %P = %p; delete @P{ keys %q };
    my %Q = %q; delete @Q{ keys %p };
    return keys %P == 0 && keys %Q == 0;
}

print "not " unless verify($c,
			   [1, 3], [1, 4], [1, 5],
			   [2, 3], [2, 4], [2, 5]);
print "ok 5\n";

print "not " unless verify($d,
			   [1, 3], [1, 4], [1, 5],
			   [2, 3], [2, 4], [2, 5]);
print "ok 6\n";

print "not " unless verify($e,
			   [1, 2], [1, 1],
			   [2, 1], [2, 2]);
print "ok 7\n";

print "not " unless verify($f,
			   [1], [2]);
print "ok 8\n";

print "not " unless verify($g,
			   [1, 3, 3], [1, 4, 3], [1, 5, 3],
			   [2, 3, 3], [2, 4, 3], [2, 5, 3],
			   [1, 3, 4], [1, 4, 4], [1, 5, 4],
			   [2, 3, 4], [2, 4, 4], [2, 5, 4],
			   [1, 3, 5], [1, 4, 5], [1, 5, 5],
			   [2, 3, 5], [2, 4, 5], [2, 5, 5]);
print "ok 9\n";

