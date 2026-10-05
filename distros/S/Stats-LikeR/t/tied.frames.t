#!/usr/bin/env perl
#
# filter(), merge() and drop_duplicates() over frames whose columns and rows
# are tied.
#
# All three read a column or a row by walking AvARRAY() directly, which is the
# whole reason they are fast, and which is wrong for a tied array: its cells do
# not exist until FETCH has run and AvARRAY() on one is not the block the
# elements live in -- on an array that has never held a real element it is a
# null pointer.  av_fetch() is the way in, and what it hands back for a tied
# element is a mortal PVLV that only acquires the value once get magic has run
# on it, so SvOK() or SvROK() on one, tested before mg_get(), reports every
# cell of every tied frame as undef and every row as "not a reference".
# t/hot_path.t pins the same pair of mistakes for the reduction functions;
# this file pins them for the three frame functions.
#
# Up to 0.301 all three were wrong, silently and in four different directions:
#
#   * filter() on a tied HoA returned an empty frame whatever the predicate,
#     because flt_row_hoa() read the wrong block and saw no cell as numeric;
#     on a tied AoH it croaked "AoH element 0 is not a HASH reference".
#   * merge() on a tied HoA matched nothing, because mg_key() read every key
#     cell as undef and an undef key matches nothing by design -- so an inner
#     join came back empty and an outer join came back as two disjoint halves,
#     both of them well-formed and neither of them right.
#   * drop_duplicates() read every cell of a tied frame as undef, which made
#     every row identical and collapsed the frame to one row.
#   * drop_duplicates() on a tied AoH segfaulted, in _aoh_key_union, which
#     indexed AvARRAY() with no guard at all.
#
# The shape of every case is the same: run the call over tied input and over an
# identical plain-array copy, and require the two answers to be equal.  A fixed
# expected value would pin the plain answer as well, which t/filter.t, t/merge.t
# and t/drop_duplicates.t already do; what has to be pinned here is that the two
# routes agree.
#
# 0.3213 added four more, each of which read a tied array's AvARRAY() or
# tested a fetched row before its get magic had run:
#
#   * sample() on a tied array segfaulted: AvARRAY() is a null pointer there.
#   * vals() and avals() on a HoA with a tied column returned one undef per
#     row, and on a tied AoH croaked "AoH row 0 is undef".
#   * col2col() on a tied AoH croaked "no usable columns found".
#   * chisq_test() and fisher_test() read an AoA's tied row, and chisq_test()
#     a tied vector, before its get magic had run, and croaked "cell [0][0] is
#     undef" (fisher_test: "array cell is undef").
#
# And later in 0.3213, more that tested a fetched cell or row before its get
# magic had run:
#
#   * group_by() on a HoA with tied columns returned {}.
#   * kruskal_test(), aov() and oneway_test() with tied groups croaked "all
#     groups must contain data", "fewer than 2 complete observations" and
#     "observation 0 is undefined or non-numeric".
#   * lm() and glm() on a HoA with tied columns croaked "0 degrees of freedom".
#   * hoa2hoh() with a tied key column croaked "has an undefined value at row
#     0".
#   * binom_test() on a tied vector croaked "successes is undef", and
#     epi_2x2(), survfit() and coxph() on tied vectors "... at index 0 is
#     undef".
#   * fisher_test() on a tied AoA (the outer array tied) croaked "each row must
#     be an array ref".
#
# Not covered here: a tied *frame* hash (the outer hash of a HoA or HoH), which
# t/tied.hashes.t covers, and how many FETCHes any of this costs, which
# t/tied.fetch.once.t does.  A tied column, a tied row array and a tied row hash
# are what this file is about.
#
# Tie::StdArray and Tie::StdHash are core (Tie::Array, Tie::Hash) and have been
# since well before 5.10, so nothing here is skippable.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(merge filter col drop_duplicates sample vals avals col2col chisq_test fisher_test
                    group_by kruskal_test aov oneway_test lm glm hoa2hoh binom_test epi_2x2 survfit coxph);

# Imported at compile time so the (&;$) prototype is in scope for the block
# call at the end, as t/merge.t does.  Absent module -> that one test is
# skipped; everything above it still runs.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

{	package TiedArray;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
{	package TiedHash;
	require Tie::Hash;
	our @ISA = ('Tie::StdHash');
}

# A tied array holding the same elements as @$src.
sub ta {
	my ($src) = @_;
	my @a;
	tie @a, 'TiedArray';
	@a = @$src;
	return \@a;
}

# A tied hash holding the same pairs as %$src.
sub th {
	my ($src) = @_;
	my %h;
	tie %h, 'TiedHash';
	%h = %$src;
	return \%h;
}

# Canonical, order-independent text for a result frame of any shape, so two
# frames can be compared with one is().  Rows are sorted, because a join's row
# order is not what this file is testing.
sub sig {
	my ($df) = @_;
	my @rows;
	if (ref $df eq 'ARRAY') {			# AoH, or AoA read positionally
		@rows = map { my $r = $_;
		              ref $r eq 'ARRAY'
		                ? +{ map { ("[$_]" => $r->[$_]) } 0 .. $#$r }
		                : $r } @$df;
	} elsif (ref $df eq 'HASH') {
		my @cols = sort keys %$df;
		if (@cols && ref $df->{ $cols[0] } eq 'ARRAY') {	# HoA
			my $n = scalar @{ $df->{ $cols[0] } };
			@rows = map { my $i = $_; +{ map { $_ => $df->{$_}[$i] } @cols } }
			        0 .. $n - 1;
		} else {					# HoH: the row key is part of the row
			@rows = map { +{ %{ $df->{$_} }, '#row' => $_ } } @cols;
		}
	}
	return join "\n", sort map {
		my $r = $_;
		join '|', map { "$_=" . (defined $r->{$_} ? $r->{$_} : 'UNDEF') }
		          sort keys %$r;
	} @rows;
}

# is_deeply() with numbers compared to 1e-12, relative above 1 and absolute
# below it.  oneway_test() over a hash of groups sums them in hash-walk order,
# and the untied copy of a tied hash is a different hash from the plain one it
# is compared with, so the two can walk in different orders: perl-5.42.3
# differed in the last digit of Pr(>F), 1e-17 on 0.0046.  1e-12 leaves five
# orders of magnitude over that, and is still far below any difference a
# misread cell would make.
sub near_deeply {
	my ($got, $want, $name) = @_;
	my @diff = near_diff($got, $want, '$got');
	ok !@diff, $name or diag @diff;
}
# The first place two structures differ, as a message, or () when they agree.
sub near_diff {
	my ($g, $w, $at) = @_;
	return () if !defined $g && !defined $w;
	return "$at: one side is undef" if !defined $g || !defined $w;
	return "$at: " . (ref $g || 'scalar') . ' vs ' . (ref $w || 'scalar') if ref $g ne ref $w;
	if (ref $w eq 'HASH') {
		my $gk = join "\0", sort keys %$g;
		return "$at: keys differ" if $gk ne join "\0", sort keys %$w;
		for my $k (sort keys %$w) {
			my @d = near_diff($g->{$k}, $w->{$k}, "$at\{$k}");
			return @d if @d;
		}
		return ();
	}
	if (ref $w eq 'ARRAY') {
		return "$at: lengths differ" if @$g != @$w;
		for my $i (0 .. $#$w) {
			my @d = near_diff($g->[$i], $w->[$i], "$at\[$i]");
			return @d if @d;
		}
		return ();
	}
	my $num = qr/^\s*[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*$/;
	if ($g =~ $num && $w =~ $num) {
		my $scale = abs($w) > 1 ? abs($w) : 1;
		return abs($g - $w) <= 1e-12 * $scale ? () : "$at: $g vs $w";
	}
	return $g eq $w ? () : "$at: '$g' vs '$w'";
}

# The one assertion this file makes, over and over.
sub agree {
	my ($tied, $plain, $name) = @_;
	is sig($tied), sig($plain), $name;
}

# The data.  cat carries an undef, so the undef-key and undef-cell paths are
# exercised as well; id is deliberately not sorted and not gap-free.
my @id  = ( 3, 1, 4, 1, 5 );
my @x   = ( -2.5, 0.5, 7, -1, 0 );
my @cat = ( 'a', 'b', undef, 'b', 'a' );

my $plain = { id => [@id], x => [@x], cat => [@cat] };
my $tied  = { id => ta(\@id), x => ta(\@x), cat => ta(\@cat) };

# filter()
for my $out (undef, 'hoa', 'aoh') {
	my $label = defined $out ? $out : 'default';
	my @opt = defined $out ? ('output_type' => $out) : ();

	agree( filter($tied, col('x') > 0,      @opt),
	       filter($plain, col('x') > 0,     @opt), "filter col() numeric, $label" );
	agree( filter($tied, col('cat') eq 'b', @opt),
	       filter($plain, col('cat') eq 'b',@opt), "filter col() string, $label" );
	agree( filter($tied,  (col('x') > 0) | (col('id') == 1), @opt),
	       filter($plain, (col('x') > 0) | (col('id') == 1), @opt),
	       "filter col() boolean, $label" );
	agree( filter($tied,  sub { $_->{x} > 0 }, @opt),
	       filter($plain, sub { $_->{x} > 0 }, @opt), "filter coderef, $label" );
	agree( filter($tied,  sub { $_[1] < 2 },  @opt),
	       filter($plain, sub { $_[1] < 2 },  @opt), "filter on row index, $label" );
}

# The specific 0.301 symptom: not merely "the same as plain", but non-empty.
{
	my $got = filter($tied, col('x') > 0);
	is scalar @{ $got->{x} }, 2, 'filter over a tied HoA keeps the matching rows';
	is_deeply [ @{ $got->{id} } ], [ 1, 4 ], 'and the right ones, in input order';
}

# A tied AoH: the rows are a tied array, and one of them is a tied hash.
{
	my @rows = map { +{ id => $id[$_], x => $x[$_] } } 0 .. $#id;
	my $paoh = [ map { +{ %$_ } } @rows ];
	my $taoh = ta([ map { th($_) } @rows ]);
	agree( filter($taoh, col('x') > 0), filter($paoh, col('x') > 0),
	       'filter over a tied AoH of tied row hashes' );
	agree( filter($taoh, col('x') > 0, 'output_type' => 'hoa'),
	       filter($paoh, col('x') > 0, 'output_type' => 'hoa'),
	       'filter tied AoH -> HoA' );
}

# A HoH whose rows are tied hashes.  The frame hash itself is not tied: a tied
# *frame* hash is a separate matter and is not supported -- filter() reads the
# shape off HeVAL(hv_iternext(...)), which for a tied hash is not the value at
# all, and merge() reads its HoA columns the same way.  Nothing here pretends
# otherwise; the case that is fixed is a tied column or a tied row.
{
	my %prows = map { ("r$_" => { id => $id[$_], x => $x[$_] }) } 0 .. $#id;
	my $phoh = { map { ($_ => { %{ $prows{$_} } }) } keys %prows };
	my $thoh = { map { ($_ => th($prows{$_})) } keys %prows };
	agree( filter($thoh, col('x') > 0), filter($phoh, col('x') > 0),
	       'filter over a HoH of tied row hashes' );
}

# merge()
my @rid = ( 1, 4, 4, 9 );
my @w   = ( 'p', 'q', 'r', 's' );
my $rplain = { id => [@rid], w => [@w] };
my $rtied  = { id => ta(\@rid), w => ta(\@w) };

# id 4 appears twice on the right, so the chain through next[] is walked; id 9
# is right-only and id 3/5 are left-only, so every outer branch is reached.
for my $how (qw(inner left right outer)) {
	for my $out (qw(aoh hoa)) {
		agree( merge($tied,  $rtied,  how => $how, on => 'id', 'output_type' => $out),
		       merge($plain, $rplain, how => $how, on => 'id', 'output_type' => $out),
		       "merge $how, tied both sides, $out out" );
		agree( merge($tied,  $rplain, how => $how, on => 'id', 'output_type' => $out),
		       merge($plain, $rplain, how => $how, on => 'id', 'output_type' => $out),
		       "merge $how, tied left only, $out out" );
		agree( merge($plain, $rtied,  how => $how, on => 'id', 'output_type' => $out),
		       merge($plain, $rplain, how => $how, on => 'id', 'output_type' => $out),
		       "merge $how, tied right only, $out out" );
	}
}

# The specific 0.301 symptom, again as an absolute rather than a comparison.
{
	# left  ids 3 1 4 1 5, right ids 1 4 4 9, walked in left-row order:
	# 3 misses, 1 pairs once, 4 pairs with both right 4s, 1 pairs once, 5 misses.
	my $got = merge($tied, $rtied, how => 'inner', on => 'id');
	is scalar @{ $got->{id} }, 4, 'inner join over tied frames matches rows';
	is_deeply [ @{ $got->{id} } ], [ 1, 4, 4, 1 ],
		'and pairs each left row with every right row carrying its key';
}

# A multi-column key: mg_key() length-prefixes each cell only when there is
# more than one, so the two-key path renders its cells differently.
{
	my @k1 = qw(a a b b);
	my @k2 = ( 1, 2, 1, 2 );
	my @v  = qw(w x y z);
	my $lp = { k1 => [@k1], k2 => [@k2], v => [@v] };
	my $lt = { k1 => ta(\@k1), k2 => ta(\@k2), v => ta(\@v) };
	my @j1 = qw(a b b);
	my @j2 = ( 2, 1, 9 );
	my @u  = qw(P Q R);
	my $rp = { k1 => [@j1], k2 => [@j2], u => [@u] };
	my $rt = { k1 => ta(\@j1), k2 => ta(\@j2), u => ta(\@u) };
	for my $how (qw(inner outer)) {
		agree( merge($lt, $rt, how => $how, on => ['k1','k2']),
		       merge($lp, $rp, how => $how, on => ['k1','k2']),
		       "merge $how on two tied key columns" );
	}
}

# left_on / right_on, and a cross join, which takes no key at all.
{
	agree( merge($tied, $rtied,  how => 'left', 'left_on' => 'id', 'right_on' => 'id'),
	       merge($plain, $rplain, how => 'left', 'left_on' => 'id', 'right_on' => 'id'),
	       'merge left_on/right_on over tied frames' );
	agree( merge($tied,  $rtied,  how => 'cross'),
	       merge($plain, $rplain, how => 'cross'),
	       'cross join over tied frames' );
}

# A tied AoH and a tied HoH on either side of the join, so the row-frame
# branch of mg_cell() is covered too.
{
	my @lrows = map { +{ id => $id[$_], x => $x[$_] } } 0 .. $#id;
	my $laoh_p = [ map { +{ %$_ } } @lrows ];
	my $laoh_t = ta([ map { th($_) } @lrows ]);
	for my $how (qw(inner left outer)) {
		agree( merge($laoh_t, $rtied,  how => $how, on => 'id'),
		       merge($laoh_p, $rplain, how => $how, on => 'id'),
		       "merge $how with a tied AoH on the left" );
	}
	my %hrows = map { ("r$_" => { id => $id[$_], x => $x[$_] }) } 0 .. $#id;
	my $hoh_p = { map { ($_ => { %{ $hrows{$_} } }) } keys %hrows };
	my $hoh_t = { map { ($_ => th($hrows{$_})) } keys %hrows };
	agree( merge($hoh_t, $rtied,  how => 'inner', on => 'id'),
	       merge($hoh_p, $rplain, how => 'inner', on => 'id'),
	       'merge with a HoH of tied rows on the left' );
}

# drop_duplicates()
# Rows 0 and 3 are duplicates of each other; row 4 duplicates nothing.  That
# separates keep => 'first' from 'last' from 0, which is the whole of what the
# survivor bookkeeping does.
{
	my @dk  = ( 'a', 'b', 'a', 'a', 'c' );
	my @dv  = (  1,   2,   9,   1,   3  );
	my $dp  = { k => [@dk], v => [@dv] };
	my $dt  = { k => ta(\@dk), v => ta(\@dv) };
	for my $keep ('first', 'last', 0) {
		agree( drop_duplicates($dt, keep => $keep),
		       drop_duplicates($dp, keep => $keep),
		       "drop_duplicates HoA tied columns, keep => '$keep'" );
	}
	agree( drop_duplicates($dt, subset => 'k'), drop_duplicates($dp, subset => 'k'),
	       'drop_duplicates HoA tied columns, subset' );

	# the specific 0.301 symptom: every cell read as undef, so one row survived
	my $got = drop_duplicates($dt);
	is scalar @{ $got->{k} }, 4, 'drop_duplicates over a tied HoA keeps four rows';
	is_deeply [ @{ $got->{k} } ], [ qw(a b a c) ], 'and the right ones, in input order';

	# AoH: a tied outer array (which used to segfault in _aoh_key_union) and
	# tied row hashes.
	my @drows = map { +{ k => $dk[$_], v => $dv[$_] } } 0 .. $#dk;
	my $paoh  = [ map { +{ %$_ } } @drows ];
	for my $keep ('first', 'last', 0) {
		agree( drop_duplicates(ta([ map { +{ %$_ } } @drows ]), keep => $keep),
		       drop_duplicates($paoh, keep => $keep),
		       "drop_duplicates tied AoH outer array, keep => '$keep'" );
		agree( drop_duplicates([ map { th($_) } @drows ], keep => $keep),
		       drop_duplicates($paoh, keep => $keep),
		       "drop_duplicates AoH of tied row hashes, keep => '$keep'" );
	}

	# AoA: a tied outer array and tied row arrays.
	my @daoa = map { [ $dk[$_], $dv[$_] ] } 0 .. $#dk;
	my $paoa = [ map { [ @$_ ] } @daoa ];
	for my $keep ('first', 'last', 0) {
		agree( drop_duplicates(ta([ map { [ @$_ ] } @daoa ]), keep => $keep),
		       drop_duplicates($paoa, keep => $keep),
		       "drop_duplicates tied AoA outer array, keep => '$keep'" );
		agree( drop_duplicates([ map { ta($_) } @daoa ], keep => $keep),
		       drop_duplicates($paoa, keep => $keep),
		       "drop_duplicates AoA of tied row arrays, keep => '$keep'" );
	}
	agree( drop_duplicates([ map { ta($_) } @daoa ], subset => 0),
	       drop_duplicates($paoa, subset => 0),
	       'drop_duplicates AoA of tied row arrays, subset' );

	# An empty tied frame of each shape: _aoh_key_union indexed AvARRAY() with
	# no bounds check, and on an array that never held an element AvARRAY() is
	# a null pointer, so this is the case that crashed rather than lied.
	{
		my @none; tie @none, 'TiedArray';
		is_deeply drop_duplicates(\@none), [], 'drop_duplicates on an empty tied array';
		my %nocol; $nocol{k} = ta([]);
		is_deeply drop_duplicates(\%nocol), { k => [] },
			'drop_duplicates on a tied but empty column';
	}

	# What survives is shared, not copied -- except from a tied column, which
	# has no cell SV to share, so those are copied.  Both halves are behaviour,
	# not accident, so both are pinned.
	{
		my $plain = { k => [@dk], v => [@dv] };
		my $out   = drop_duplicates($plain);
		$out->{v}[0] = 'touched';
		is $plain->{v}[0], 'touched', 'a plain HoA survivor shares its cell with the input';

		my @tv = @dv;
		my $ti = { k => ta(\@dk), v => ta(\@tv) };
		my $to = drop_duplicates($ti);
		$to->{v}[0] = 'touched';
		is $ti->{v}[0], $dv[0], 'a tied HoA survivor is copied, so the input is untouched';
	}
}

# sample(): the same draws from a tied array as from a plain one, given the
# same seed -- both shuffle the same index array with the same Drand01() calls
{
	my @pop = ( 10 .. 29 );
	my $tp  = ta( \@pop );
	for my $n ( 0, 1, 7, 20 ) {
		srand(20261002);
		my $want = sample( [@pop], $n );
		srand(20261002);
		my $got = sample( $tp, $n );
		is_deeply $got, $want, "sample: $n from a tied array, as from a plain one";
	}
	my $r = sample( $tp, 20 );
	is_deeply [ sort { $a <=> $b } @$r ], [@pop], 'sample: a full draw from a tied array is a permutation of it';
	ok !tied( @$r ), 'sample: the result is a plain array, not tied';
	eval { sample( $tp, 21 ) };
	like $@, qr/cannot take a sample of 21 from a population of 20/, 'sample: a tied array still refuses more than it holds';
}

# vals(), avals(): a tied column of a HoA, and a tied AoH frame
{
	is_deeply vals( $tied, 'x' ), vals( $plain, 'x' ), 'vals: a tied HoA column';
	is_deeply [ avals( $tied, 'x' ) ], [ avals( $plain, 'x' ) ], 'avals: a tied HoA column';
	is_deeply vals( $tied, 'cat' ), [@cat], 'vals: a tied column with an undef cell';
	my @aoh = map { +{ id => $id[$_], x => $x[$_] } } 0 .. $#id;
	my $taoh = ta( \@aoh );
	is_deeply vals( $taoh, 'x' ), [@x], 'vals: a tied AoH frame';
	is_deeply [ avals( $taoh, 'x' ) ], [@x], 'avals: a tied AoH frame';
	is_deeply vals( [ map { th($_) } @aoh ], 'x' ), [@x], 'vals: an AoH of tied rows';
	my $cp = vals( $tied, 'x' );
	$cp->[0] = 'touched';
	is $tied->{x}[0], $x[0], 'vals: the result is a copy of a tied column, not an alias to it';
}

# col2col(): a tied AoH frame, a tied AoH frame of tied rows, and tied columns
{
	my @aoh = map { +{ id => $id[$_], x => $x[$_] } } 0 .. $#id;
	my $want = col2col( \@aoh, 'cor', [ 'id', 'x' ] );
	is_deeply col2col( ta( \@aoh ), 'cor', [ 'id', 'x' ] ), $want, 'col2col: a tied AoH frame';
	is_deeply col2col( ta( [ map { th($_) } @aoh ] ), 'cor', [ 'id', 'x' ] ), $want, 'col2col: a tied AoH frame of tied rows';
	is_deeply col2col( { id => ta( \@id ), x => ta( \@x ) }, 'cor', [ 'id', 'x' ] ), $want, 'col2col: tied HoA columns';
}

# chisq_test(), fisher_test(): an AoA of tied rows, and a tied vector
{
	my @t = ( [ 10, 20 ], [ 30, 15 ] );
	my $tt = [ map { ta($_) } @t ];
	is_deeply chisq_test($tt), chisq_test( [@t] ), 'chisq_test: an AoA of tied rows';
	is_deeply fisher_test($tt), fisher_test( [@t] ), 'fisher_test: an AoA of tied rows';
	is_deeply chisq_test( ta( [ 10, 20, 30 ] ) ), chisq_test( [ 10, 20, 30 ] ), 'chisq_test: a tied vector';
}

# group_by(): tied HoA columns, a tied AoH, and an AoH of tied rows
{
	my @aoh = map { +{ id => $id[$_], x => $x[$_], cat => $cat[$_] } } 0 .. $#id;
	my $want = group_by( $plain, 'x', 'id' );
	is_deeply group_by( $tied, 'x', 'id' ), $want, 'group_by: tied HoA columns';
	ok scalar( keys %$want ), 'group_by: and the answer is not empty';
	is_deeply group_by( ta( \@aoh ), 'x', 'id' ), $want, 'group_by: a tied AoH';
	is_deeply group_by( [ map { th($_) } @aoh ], 'x', 'id' ), $want, 'group_by: an AoH of tied rows';
	is_deeply group_by( $tied, 'x', 'id', { x => sub { $_[0] > 0 } } ),
	          group_by( $plain, 'x', 'id', { x => sub { $_[0] > 0 } } ), 'group_by: a filter over a tied column';
}

# kruskal_test(), aov(), oneway_test(): tied groups, in every input form
my %grp = ( a => [ 1, 2, 3, 2.5 ], b => [ 4, 5, 6.5 ], c => [ 7, 8.5, 9, 6 ] );
my $tgrp = { map { ( $_ => ta( $grp{$_} ) ) } keys %grp };
my @gy = map { @{ $grp{$_} } } sort keys %grp;
my @gg = map { ($_) x @{ $grp{$_} } } sort keys %grp;
{
	is_deeply kruskal_test($tgrp), kruskal_test( {%grp} ), 'kruskal_test: a hash of tied groups';
	is_deeply kruskal_test( x => ta( \@gy ), g => ta( \@gg ) ), kruskal_test( x => [@gy], g => [@gg] ),
	          'kruskal_test: tied x and g';
	is_deeply aov($tgrp), aov( {%grp} ), 'aov: a hash of tied groups';
	is_deeply aov( $tied, 'x ~ cat' ), aov( $plain, 'x ~ cat' ), 'aov: a formula over tied columns';
	near_deeply( oneway_test($tgrp), oneway_test( {%grp} ), 'oneway_test: a hash of tied groups' );
	is_deeply oneway_test( { y => ta( \@gy ), g => ta( \@gg ) }, formula => 'y ~ g' ),
	          oneway_test( { y => [@gy], g => [@gg] }, formula => 'y ~ g' ), 'oneway_test: a formula over tied columns';
	my @aoa = map { $grp{$_} } sort keys %grp;
	is_deeply oneway_test( [ map { ta($_) } @aoa ] ), oneway_test( [@aoa] ), 'oneway_test: an AoA of tied rows';
	is_deeply oneway_test( ta( [@aoa] ) ), oneway_test( [@aoa] ), 'oneway_test: a tied AoA';
}

# lm(), glm(): tied HoA columns.  b is 0/1 and not separable by x.
{
	my @xx = ( 1 .. 8 );
	my @yy = ( 1, 2, 3, 4, 5, 6.5, 1.5, 3.7 );
	my @bb = ( 0, 1, 0, 1, 1, 1, 0, 1 );
	my $p = { x => [@xx], y => [@yy], b => [@bb] };
	my $t = { x => ta( \@xx ), y => ta( \@yy ), b => ta( \@bb ) };
	is_deeply lm( formula => 'y ~ x', data => $t ), lm( formula => 'y ~ x', data => $p ), 'lm: tied HoA columns';
	is_deeply glm( formula => 'b ~ x', data => $t, family => 'binomial' ),
	          glm( formula => 'b ~ x', data => $p, family => 'binomial' ), 'glm: tied HoA columns';
}

# hoa2hoh(): a tied key column, and tied other columns
{
	my $p = { id => [ 3, 1, 4 ], x => [ -2.5, 0.5, 7 ] };
	is_deeply hoa2hoh( { id => ta( $p->{id} ), x => ta( $p->{x} ) }, 'id' ), hoa2hoh( $p, 'id' ),
	          'hoa2hoh: tied key and value columns';
}

# binom_test(), epi_2x2(), survfit(), coxph(): tied vectors
{
	is_deeply binom_test( ta( [ 7, 3 ] ) ), binom_test( [ 7, 3 ] ), 'binom_test: a tied [successes, failures]';
	eval { binom_test( ta( [ 7, undef ] ) ) };
	like $@, qr/binom_test: failures is undef/, 'binom_test: a tied undef is still refused';
	eval { binom_test( ta( [ 7, 'z' ] ) ) };
	like $@, qr/binom_test: failures is not a number/, 'binom_test: a tied non-number is still refused';
	is_deeply epi_2x2( ta( [ 10, 20, 30, 40 ] ) ), epi_2x2( [ 10, 20, 30, 40 ] ), 'epi_2x2: a tied vector';
	is_deeply epi_2x2( [ ta( [ 10, 20 ] ), ta( [ 30, 40 ] ) ] ), epi_2x2( [ [ 10, 20 ], [ 30, 40 ] ] ),
	          'epi_2x2: tied rows';
	my @tm = ( 5, 8, 12, 3, 9, 15, 2, 7 );
	my @st = ( 1, 0, 1, 1, 0, 1, 1, 0 );
	my @cv = ( 0.5, 1.2, -0.3, 2.0, 0.1, -1.1, 1.7, 0.4 );
	is_deeply survfit( ta( \@tm ), ta( \@st ) ), survfit( [@tm], [@st] ), 'survfit: tied time and status';
	is_deeply coxph( ta( \@tm ), ta( \@st ), ta( \@cv ) ), coxph( [@tm], [@st], [@cv] ),
	          'coxph: tied time, status and covariate';
}

# fisher_test(): a tied outer AoA, of plain rows and of tied rows
{
	my @t = ( [ 1, 5 ], [ 6, 2 ] );
	is_deeply fisher_test( ta( [@t] ) ), fisher_test( [@t] ), 'fisher_test: a tied AoA';
	is_deeply fisher_test( ta( [ map { ta($_) } @t ] ) ), fisher_test( [@t] ), 'fisher_test: a tied AoA of tied rows';
}

# The input must come back untouched: FETCH is allowed, STORE is not.
{
	is_deeply [ @{ $tied->{id} } ],  [@id],  'tied id column unchanged by the calls above';
	is_deeply [ @{ $tied->{x} } ],   [@x],   'tied x column unchanged';
	is_deeply [ @{ $rtied->{id} } ], [@rid], 'tied right id column unchanged';
}

# No leaks.  av_row_keep() hands back a fresh reference for a tied row and the
# caller's own for a plain one, which is two ownership rules in one place.
SKIP: {
	skip 'Test::LeakTrace not installed', 1 unless $HAVE_LEAKTRACE;
	skip 'Devel::Cover perturbs refcounts', 1 if $INC{'Devel/Cover.pm'};
	no_leaks_ok {
		drop_duplicates({ k => ta([qw(a b a)]), v => ta([1,2,1]) });
		drop_duplicates(ta([ { k => 'a' }, { k => 'a' } ]));
		drop_duplicates(ta([ ['a'], ['a'] ]));
		filter($tied, col('x') > 0);
		filter($tied, col('x') > 0, 'output_type' => 'aoh');
		filter($tied, sub { $_->{x} > 0 });
		merge($tied, $rtied, how => $_, on => 'id') for qw(inner left right outer);
		merge($tied, $rtied, how => 'cross');
		sample(ta([1 .. 5]), 3);
		vals($tied, 'x');
		avals($tied, 'x');
		vals(ta([ { x => 1 }, { x => 2 } ]), 'x');
		col2col(ta([ { a => 1, b => 2 }, { a => 2, b => 1 }, { a => 3, b => 5 } ]), 'cor', [ 'a', 'b' ]);
		group_by($tied, 'x', 'id');
		kruskal_test($tgrp);
		oneway_test($tgrp);
		aov($tgrp);
		lm(formula => 'x ~ id', data => $tied);
		hoa2hoh({ k => ta([1, 2]), v => ta([3, 4]) }, 'k');
		binom_test(ta([7, 3]));
		epi_2x2(ta([10, 20, 30, 40]));
		fisher_test(ta([ [1, 5], [6, 2] ]));
	} 'no leaks over the tied paths';
}

done_testing();
