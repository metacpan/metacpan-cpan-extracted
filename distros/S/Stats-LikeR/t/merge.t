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

	my $HL = { a => [1], x => ['L'] };
	my $HR = { a => [1], x => ['R'] };
	merge($HL, $HR, on => 'a', 'output.type' => 'hoa');
	is_deeply $HL, { a => [1], x => ['L'] }, 'left HoA frame is untouched';
	is_deeply $HR, { a => [1], x => ['R'] }, 'right HoA frame is untouched';
}

# ---- a HoA whose columns are ragged ----
# merge reads a HoA column by column rather than transposing it into rows
# first, so a column that stops short has to keep reading as undef, which is
# what padding the transpose used to do.
{
	my $L = { id => [ 1, 2, 3 ], v => [ 'a' ] };          # v is two cells short
	same( merge($L, { id => [ 1, 2, 3 ], w => [ 'x', 'y', 'z' ] },
	            on => 'id', how => 'inner'),
		[ { id => 1, v => 'a',   w => 'x' },
		  { id => 2, v => undef, w => 'y' },
		  { id => 3, v => undef, w => 'z' } ],
		'a short HoA column reads as undef past its end' );
}

# ---- against a reference implementation, over every shape combination ----
# The join reads HoA frames column-wise and AoH/HoH frames row-wise, and
# writes AoH or HoA directly; that is six input/output paths through the same
# semantics, and they have to agree with each other and with the documented
# rules.  ref_join spells those rules out in plain Perl: stringified keys, an
# undef key cell that never matches, the left name kept for a join column, a
# key value taken from the left when it has one, and non-key columns present
# on both sides suffixed.
{
	sub ref_join {
		my ($L, $R, $keys, $how) = @_;
		my (%lall, %rall);
		$lall{$_} = 1 for map { keys %$_ } @$L;
		$rall{$_} = 1 for map { keys %$_ } @$R;
		my %kset  = map { $_ => 1 } @$keys;
		my @lc    = grep { !$kset{$_} } sort keys %lall;
		my @rc    = grep { !$kset{$_} } sort keys %rall;
		my %lcset = map { $_ => 1 } @lc;
		my %rcset = map { $_ => 1 } @rc;

		my $key_of = sub {
			my $r = shift;
			my @p;
			for my $k (@$keys) {
				return undef unless defined $r->{$k};
				push @p, length($r->{$k}) . "\x1e" . $r->{$k};
			}
			return join "\x1e", @p;
		};
		my $emit = sub {
			my ($l, $r) = @_;
			my %o;
			for my $k (@$keys) {
				$o{$k} = (defined $l && defined $l->{$k}) ? $l->{$k}
				       : (defined $r) ? $r->{$k} : undef;
			}
			$o{ $rcset{$_} ? "$_.x" : $_ } = defined $l ? $l->{$_} : undef for @lc;
			$o{ $lcset{$_} ? "$_.y" : $_ } = defined $r ? $r->{$_} : undef for @rc;
			return \%o;
		};

		my @out;
		if ($how eq 'cross') {
			for my $l (@$L) { push @out, $emit->($l, $_) for @$R }
			return \@out;
		}
		my %idx;
		for my $j (0 .. $#$R) {
			my $k = $key_of->($R->[$j]);
			push @{ $idx{$k} }, $j if defined $k;
		}
		my %matched;
		for my $l (@$L) {
			my $k = $key_of->($l);
			my $m = defined $k ? $idx{$k} : undef;
			if ($m) { for my $j (@$m) { push @out, $emit->($l, $R->[$j]); $matched{$j} = 1 } }
			elsif ($how eq 'left' || $how eq 'outer') { push @out, $emit->($l, undef) }
		}
		if ($how eq 'right' || $how eq 'outer') {
			push @out, $emit->(undef, $R->[$_]) for grep { !$matched{$_} } 0 .. $#$R;
		}
		return \@out;
	}

	sub to_hoa {
		my ($aoh, $cols) = @_;
		return { map { my $c = $_; ($c => [ map { $_->{$c} } @$aoh ]) } @$cols };
	}

	srand 20260802;                       # a fixed corpus, so a failure repeats
	my @lcols = qw(k1 k2 a shared);
	my @rcols = qw(k1 k2 b shared);
	my @vals  = (1, 2, '2', 'x', undef);  # 2 and '2' collide; undef never matches
	my $mk = sub {
		my ($cols, $n) = @_;
		return [ map { +{ map { $_ => $vals[ rand @vals ] } @$cols } } 1 .. $n ];
	};

	my $mismatch = '';
	my $cases = 0;
	TRIAL: for my $trial (1 .. 120) {
		my $L    = $mk->(\@lcols, 1 + int rand 5);
		my $R    = $mk->(\@rcols, 1 + int rand 5);
		my $keys = (int rand 2) ? ['k1'] : ['k1', 'k2'];
		my $how  = (qw(inner left right outer cross))[ int rand 5 ];
		my @args = $how eq 'cross' ? (how => 'cross') : (how => $how, on => $keys);
		my $want = ref_join($L, $R, $how eq 'cross' ? [] : $keys, $how);

		for my $lshape (qw(aoh hoa)) {
			for my $rshape (qw(aoh hoa)) {
				for my $oshape (qw(aoh hoa)) {
					my $got = merge($lshape eq 'aoh' ? $L : to_hoa($L, \@lcols),
					                $rshape eq 'aoh' ? $R : to_hoa($R, \@rcols),
					                @args, 'output.type' => $oshape);
					$cases++;
					next if sig($got) eq sig($want);
					$mismatch = "trial $trial: how=$how on=[@$keys] "
					          . "$lshape+$rshape -> $oshape\ngot:\n" . sig($got)
					          . "\nwant:\n" . sig($want);
					last TRIAL;
				}
			}
		}
	}
	is $mismatch, '', "every shape combination matches the reference ($cases joins)";
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

#--------
# Numeric join keys.  mg_key() renders plain integers and doubles itself
# rather than through SvPV (nk_num_pv in LikeR.xs), so a numeric-keyed join
# has to match exactly the join a plain Perl string hash would produce.
#--------
{
	srand(1234);
	my $bad = 0;
	for my $round (1 .. 20) {
		my @id  = map { $_ % 3 == 0 ? int rand 500 : rand() * 1000 } 1 .. 300;
		my @rid = map { $id[ int rand @id ] } 1 .. 300;
		my $L = { id => [ @id  ], v => [ 1 .. scalar @id  ] };
		my $R = { id => [ @rid ], w => [ 1 .. scalar @rid ] };
		my %ridx;
		push @{ $ridx{"$rid[$_]"} }, $_ for 0 .. $#rid;
		my $want = 0;
		$want += @{ $ridx{"$_"} || [] } for @id;
		my $got = merge($L, $R, how => 'inner', on => 'id');
		$bad++ unless @{ $got->{id} } == $want;
	}
	is($bad, 0, 'numeric join keys match a string-keyed join');
}

done_testing();