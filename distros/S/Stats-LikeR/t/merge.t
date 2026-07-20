use strict;
use warnings;
use Test::More;
use Test::Exception; # dies_ok / throws_ok
use Stats::LikeR 'merge';

# Import no_leaks_ok at compile time so its (&;$) prototype is in scope for the
# block-style calls below. Absent module -> the leak tests are skipped.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

# Canonical, order-independent signature of a result frame (AoH or HoA):
# a sorted multiset of "col=val|col=val" strings, one per row.
sub sig {
	my $df = shift;
	if (ref $df eq 'HASH') {                 # HoA -> AoH
		my @cols = keys %$df;
		my $n = @cols ? scalar @{ $df->{$cols[0]} } : 0;
		$df = [ map { my $i = $_; +{ map { $_ => $df->{$_}[$i] } @cols } } 0 .. $n - 1 ];
	}
	my @rows;
	for my $r (@$df) {
		push @rows, join '|', map { "$_=" . (defined $r->{$_} ? $r->{$_} : 'UNDEF') }
		                      sort keys %$r;
	}
	return join "\n", sort @rows;
}

sub same {
	my ($got, $want, $name) = @_;
	is sig($got), sig($want), $name;
}

# ---------------------------------------------------------------------------
my $emp = [
	{ id => 1, name => 'Alice', dept => 10 },
	{ id => 2, name => 'Bob',   dept => 20 },
	{ id => 3, name => 'Carol', dept => 30 },
	{ id => 4, name => 'Dave',  dept => 10 },
	{ id => 5, name => 'Eve',   dept => undef },   # undef key never matches
];
my $dept = [
	{ dept => 10, dname => 'Sales',       name => 'HQ'    },
	{ dept => 20, dname => 'Engineering', name => 'Lab'   },
	{ dept => 40, dname => 'Legal',       name => 'Annex' },
];

# ---- inner join ----
same( merge($emp, $dept, how => 'inner', on => 'dept'),
	[ { dept => 10, id => 1, 'name.x' => 'Alice', dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 10, id => 4, 'name.x' => 'Dave',  dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 20, id => 2, 'name.x' => 'Bob',   dname => 'Engineering', 'name.y' => 'Lab' } ],
	'inner join, colliding non-key column "name" suffixed .x/.y' );

# ---- left join ----
same( merge($emp, $dept, how => 'left', on => 'dept'),
	[ { dept => 10, id => 1, 'name.x' => 'Alice', dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 20, id => 2, 'name.x' => 'Bob',   dname => 'Engineering', 'name.y' => 'Lab' },
	  { dept => 30, id => 3, 'name.x' => 'Carol', dname => undef, 'name.y' => undef },
	  { dept => 10, id => 4, 'name.x' => 'Dave',  dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => undef, id => 5, 'name.x' => 'Eve', dname => undef, 'name.y' => undef } ],
	'left join keeps all left rows; undef key is left-only' );

# ---- right join ----
same( merge($emp, $dept, how => 'right', on => 'dept'),
	[ { dept => 10, id => 1, 'name.x' => 'Alice', dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 10, id => 4, 'name.x' => 'Dave',  dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 20, id => 2, 'name.x' => 'Bob',   dname => 'Engineering', 'name.y' => 'Lab' },
	  { dept => 40, id => undef, 'name.x' => undef, dname => 'Legal', 'name.y' => 'Annex' } ],
	'right join keeps all right rows (dept 40 unmatched)' );

# ---- outer join ----
same( merge($emp, $dept, how => 'outer', on => 'dept'),
	[ { dept => 10, id => 1, 'name.x' => 'Alice', dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => 20, id => 2, 'name.x' => 'Bob',   dname => 'Engineering', 'name.y' => 'Lab' },
	  { dept => 30, id => 3, 'name.x' => 'Carol', dname => undef, 'name.y' => undef },
	  { dept => 10, id => 4, 'name.x' => 'Dave',  dname => 'Sales', 'name.y' => 'HQ'  },
	  { dept => undef, id => 5, 'name.x' => 'Eve', dname => undef, 'name.y' => undef },
	  { dept => 40, id => undef, 'name.x' => undef, dname => 'Legal', 'name.y' => 'Annex' } ],
	'outer join = union of left and right' );

# ---- cross join ----
{
	my $L = [ { a => 1 }, { a => 2 } ];
	my $R = [ { b => 'x' }, { b => 'y' }, { b => 'z' } ];
	my $c = merge($L, $R, how => 'cross');
	is scalar @$c, 6, 'cross join is the Cartesian product (2 x 3 = 6)';
	same( $c,
		[ { a => 1, b => 'x' }, { a => 1, b => 'y' }, { a => 1, b => 'z' },
		  { a => 2, b => 'x' }, { a => 2, b => 'y' }, { a => 2, b => 'z' } ],
		'cross join content' );
}

# ---- natural join (no keys given -> intersection of column names) ----
same( merge($emp, $dept, how => 'inner'),
	merge($emp, $dept, how => 'inner', on => ['dept', 'name']),
	'natural join uses the intersection {dept,name} as keys' );

# ---- multi-key join ----
{
	my $a = [ {k1=>1,k2=>'x',v=>'a'}, {k1=>1,k2=>'y',v=>'b'}, {k1=>2,k2=>'x',v=>'c'} ];
	my $b = [ {k1=>1,k2=>'x',w=>'A'}, {k1=>2,k2=>'x',w=>'C'}, {k1=>2,k2=>'z',w=>'Z'} ];
	same( merge($a, $b, on => ['k1','k2'], how => 'inner'),
		[ { k1=>1, k2=>'x', v=>'a', w=>'A' },
		  { k1=>2, k2=>'x', v=>'c', w=>'C' } ],
		'multi-key inner join matches on the (k1,k2) tuple' );
}

# ---- left.on / right.on with differently-named keys ----
{
	my $orders = [ {oid=>1, cust=>'c1'}, {oid=>2, cust=>'c2'}, {oid=>3, cust=>'c9'} ];
	my $cust   = [ {cid=>'c1', city=>'NYC'}, {cid=>'c2', city=>'LA'} ];
	same( merge($orders, $cust, how => 'left', 'left.on' => 'cust', 'right.on' => 'cid'),
		[ { cust=>'c1', oid=>1, city=>'NYC'   },
		  { cust=>'c2', oid=>2, city=>'LA'    },
		  { cust=>'c9', oid=>3, city=>undef   } ],
		'left.on/right.on: single output key column keeps the left name' );
}

# ---- many-to-many ----
{
	my $m1 = [ {k=>1,l=>'a'}, {k=>1,l=>'b'} ];
	my $m2 = [ {k=>1,r=>'X'}, {k=>1,r=>'Y'} ];
	is scalar @{ merge($m1, $m2, on => 'k') }, 4,
		'many-to-many inner join produces the per-key Cartesian product';
}

# ---- custom suffixes ----
same( merge($emp, $dept, on => 'dept', how => 'inner', suffixes => ['_emp','_dept']),
	[ { dept => 10, id => 1, 'name_emp' => 'Alice', dname => 'Sales', 'name_dept' => 'HQ'  },
	  { dept => 10, id => 4, 'name_emp' => 'Dave',  dname => 'Sales', 'name_dept' => 'HQ'  },
	  { dept => 20, id => 2, 'name_emp' => 'Bob',   dname => 'Engineering', 'name_dept' => 'Lab' } ],
	'custom suffixes rename colliding columns' );

# ---- HoA inputs, HoA output ----
{
	my $L = { id => [1,2,3], grp => ['a','b','a'] };
	my $R = { grp => ['a','b'], score => [100,200] };
	my $got = merge($L, $R, on => 'grp', how => 'left', 'output.type' => 'hoa');
	is ref $got, 'HASH', 'output.type => hoa returns a hash of arrays';
	same( $got,
		[ { grp=>'a', id=>1, score=>100 },
		  { grp=>'b', id=>2, score=>200 },
		  { grp=>'a', id=>3, score=>100 } ],
		'HoA-in, HoA-out left join transposes correctly' );
}

# ---- inputs are not mutated ----
{
	my $L = [ { a => 1, x => 'L' } ];
	my $R = [ { a => 1, x => 'R' } ];
	merge($L, $R, on => 'a');
	is_deeply $L, [ { a => 1, x => 'L' } ], 'left frame is untouched';
	is_deeply $R, [ { a => 1, x => 'R' } ], 'right frame is untouched';
}

# ---- error handling ----
throws_ok { merge([{a=>1}], [{a=>1}], how => 'bogus') } qr/merge: how must be/, 'bad how dies';
throws_ok { merge([{a=>1}], [{b=>1}], on => 'a') } qr/right frame has no join column/, 'missing key dies';
throws_ok { merge([{a=>1}], [{b=>1}]) } qr/no common columns/, 'no common columns dies';
throws_ok { merge([{a=>1}], [{a=>1}], on => 'a', 'left.on' => 'a') } qr/not both/, 'on + left.on dies';
throws_ok { merge([{a=>1}], [{a=>1}], how => 'cross', on => 'a') } qr/cross join takes no join keys/, 'cross + on dies';
throws_ok { merge([[1,2]], [{a=>1}], on => 'a') } qr/array-of-arrays/, 'AoA input dies';

# ---- no memory leaks ----
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
SKIP: {
	skip 'Test::LeakTrace not installed', 1 unless $HAVE_LEAKTRACE;
	no_leaks_ok {
		merge($emp, $dept, how => 'inner', on => 'dept');
		merge($emp, $dept, how => 'left',  on => 'dept');
		merge($emp, $dept, how => 'right', on => 'dept');
		merge($emp, $dept, how => 'outer', on => 'dept');
		merge($emp, $dept, how => 'cross');
		merge($emp, $dept, on => 'dept', 'output.type' => 'hoa');
	} 'merge does not leak across all join types';
}

done_testing();
