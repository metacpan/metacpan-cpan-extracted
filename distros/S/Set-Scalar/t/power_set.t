use Set::Scalar;

print "1..6\n";

my $a = Set::Scalar->new(1..3);
my $b = Set::Scalar->new();

my $c = $a->power_set;
my $d = Set::Scalar->power_set($a);
my $e = $b->power_set;

print "not " unless $c->members == 8;
print "ok 1\n";

print "not " unless $d->members == 8;
print "ok 2\n";

print "not " unless $e->members == 1;
print "ok 3\n";

sub verify {
    my ($p, @q) = @_;
    my @p = $p->members;
    return unless @p == @q;
    @q = map { Set::Scalar->new(@$_) } @q;
    my %p; @p{ map { "$_" } @p } = @p;
    my %q; @q{ map { "$_" } @q } = @q;
    my %P = %p; delete @P{ keys %q };
    my %Q = %q; delete @Q{ keys %p };
    return keys %P == 0 && keys %Q == 0;
}

print "not " unless verify($c,
			   [],
			   [1], [2], [3],
			   [1, 2], [1, 3], [2, 3],
			   [1, 2, 3]);
print "ok 4\n";

print "not " unless verify($d,
			   [],
			   [1], [2], [3],
			   [1, 2], [1, 3], [2, 3],
			   [1, 2, 3]);
print "ok 5\n";

print "not " unless verify($e,
			   []);
print "ok 6\n";
 
			   


