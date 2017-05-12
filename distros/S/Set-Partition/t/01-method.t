# 01-method.t
#
# Test suite for Set::Partition
# Test the module methods
#
# copyright (C) 2006 David Landgren

use strict;

eval qq{use Test::More tests => 81};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Set::Partition;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

{
    my $s = Set::Partition->new( list => [qw(x y z)] );
    my $p = $s->next;
    is_deeply( $p, [[ qw(x y z) ]], 'unpartitioned set' );

    $p = $s->next;
    ok( !defined($p), '...exhausted');

    $p = $s->reset;
    $p = $s->next;
    is_deeply( $p, [[ qw(x y z) ]], 'unpartitioned reset' );
}

{
    eval { my $s = Set::Partition->new( list => ['m'], partition => [1, 2] ) };
    ok( $@, 'die on out-of-range partitioning' );
}

{
    my $s = Set::Partition->new( list => [qw(g h)], partition => [1, 1] );
    my $p = $s->next;
    is_deeply( $p, [ [qw(g)], [qw(h)] ], 'set 1,1 first' );
    $p = $s->next;
    is_deeply( $p, [ [qw(h)], [qw(g)] ], 'set 1,1 second' );
    $p = $s->next;
    ok( !defined($p), 'set 1,1 exhausted');
}

{
    my $s = Set::Partition->new( list => [qw(p q r s)], partition => [3] );
    my $p = $s->next;
    is_deeply( $p, [ [qw(p q r)], [qw(s)] ], 'set 3,1 first' );
    $p = $s->next;
    is_deeply( $p, [ [qw(p q s)], [qw(r)] ], 'set 3,1 second' );
    $p = $s->next;
    is_deeply( $p, [ [qw(p r s)], [qw(q)] ], 'set 3,1 third' );
    $p = $s->next;
    is_deeply( $p, [ [qw(q r s)], [qw(p)] ], 'set 3,1 fourth' );
    $p = $s->next;
    ok( !defined($p), 'set 3,1 exhausted');
}

{
    my $s = Set::Partition->new( list => [qw(p q r s)], partition => [3, 0, 1] );
    my $p = $s->next;
    is_deeply( $p, [ [qw(p q r)], undef, [qw(s)] ], 'set 3,0,1 first' );
    $p = $s->next;
    is_deeply( $p, [ [qw(p q s)], undef, [qw(r)] ], 'set 3,0,1 second' );
    $p = $s->next;
    is_deeply( $p, [ [qw(p r s)], undef, [qw(q)] ], 'set 3,0,1 third' );
    $p = $s->next;
    is_deeply( $p, [ [qw(q r s)], undef, [qw(p)] ], 'set 3,0,1 fourth' );
    $p = $s->next;
    ok( !defined($p), 'set 3,0,1 exhausted');
}

{
    my $s = Set::Partition->new(
		list => {
			a => 'apple',
			b => 'banana',
			c => 'cherry',
		},
		partition => [2, 1],
	);
	my @p = ($s->next, $s->next, $s->next);
    ok( !defined($s->next), 'set hash exhausted');

	my $result;
	for my $p (@p) {
		$result->{join(';', map {join( '+', sort keys %$_)} @$p)}
			= join(',', map {join( '+', sort values %$_)} @$p);
	}
	is_deeply( $result,
		{
			'a+b;c' => 'apple+banana,cherry',
			'a+c;b' => 'apple+cherry,banana',
			'b+c;a' => 'banana+cherry,apple',
		},
		'hash partitions'
	);
}

{
    my $s = Set::Partition->new( list => ['a' .. 'f'], partition => [3, 1, 2] );
    my $nr = 0;
    while (defined(my $expected = <DATA>)) {
        chomp $expected;
        my $p = $s->next;
        my $actual = join( ' ', map {"(@$_)"} @$p );
        ++$nr;
        is( $expected, $actual, "a..f by 3,1,2 $nr" );
    }
    my $p = $s->next;
    ok( !defined($p), 'a..f by 3,1,2 exhausted');
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );

__DATA__
(a b c) (d) (e f)
(a b c) (e) (d f)
(a b c) (f) (d e)
(a b d) (c) (e f)
(a b e) (c) (d f)
(a b f) (c) (d e)
(a b d) (e) (c f)
(a b d) (f) (c e)
(a b e) (d) (c f)
(a b f) (d) (c e)
(a b e) (f) (c d)
(a b f) (e) (c d)
(a c d) (b) (e f)
(a c e) (b) (d f)
(a c f) (b) (d e)
(a d e) (b) (c f)
(a d f) (b) (c e)
(a e f) (b) (c d)
(a c d) (e) (b f)
(a c d) (f) (b e)
(a c e) (d) (b f)
(a c f) (d) (b e)
(a c e) (f) (b d)
(a c f) (e) (b d)
(a d e) (c) (b f)
(a d f) (c) (b e)
(a e f) (c) (b d)
(a d e) (f) (b c)
(a d f) (e) (b c)
(a e f) (d) (b c)
(b c d) (a) (e f)
(b c e) (a) (d f)
(b c f) (a) (d e)
(b d e) (a) (c f)
(b d f) (a) (c e)
(b e f) (a) (c d)
(c d e) (a) (b f)
(c d f) (a) (b e)
(c e f) (a) (b d)
(d e f) (a) (b c)
(b c d) (e) (a f)
(b c d) (f) (a e)
(b c e) (d) (a f)
(b c f) (d) (a e)
(b c e) (f) (a d)
(b c f) (e) (a d)
(b d e) (c) (a f)
(b d f) (c) (a e)
(b e f) (c) (a d)
(b d e) (f) (a c)
(b d f) (e) (a c)
(b e f) (d) (a c)
(c d e) (b) (a f)
(c d f) (b) (a e)
(c e f) (b) (a d)
(d e f) (b) (a c)
(c d e) (f) (a b)
(c d f) (e) (a b)
(c e f) (d) (a b)
(d e f) (c) (a b)
