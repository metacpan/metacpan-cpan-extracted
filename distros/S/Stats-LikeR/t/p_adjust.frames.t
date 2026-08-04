use strict;
use warnings;
use Test::More;
use Stats::LikeR 'p_adjust';

# Optional leak testing: import at compile time so the no_leaks_ok prototype
# is in scope, and skip cleanly when the module is not installed.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

# The five shapes all pool their p-values into one family and hand the
# adjusted values back where they came from.

my @p = (0.01, 0.04, 0.03, 0.20, 0.005, 0.7);
my @cols = qw(c0 c1 c2);
my $nc = scalar @cols;
my $nr = @p / $nc;

sub flat_of { return [ p_adjust([@p], $_[0]) ] }

# row-major: AoA, AoH and HoH walk rows, then columns in name order
sub rows_of { my $q = shift; [ map { [ @$q[$_ * $nc .. $_ * $nc + $nc - 1] ] } 0 .. $nr - 1 ] }

# column-major: HoA walks columns in name order, then rows
sub cols_of {
	my $q = shift;
	[ map { my $j = $_; [ map { $q->[$_ * $nc + $j] } 0 .. $nr - 1 ] } 0 .. $nc - 1 ];
}

sub aoa { [ map { my $i = $_; [ @p[$i * $nc .. $i * $nc + $nc - 1] ] } 0 .. $nr - 1 ] }
sub aoh { [ map { my $i = $_; +{ map { ($cols[$_] => $p[$i * $nc + $_]) } 0 .. $nc - 1 } } 0 .. $nr - 1 ] }
sub hoa { +{ map { my $j = $_; ($cols[$j] => [ map { $p[$_ * $nc + $j] } 0 .. $nr - 1 ]) } 0 .. $nc - 1 } }
sub hoh { +{ map { my $i = $_; ("r$i" => { map { ($cols[$_] => $p[$i * $nc + $_]) } 0 .. $nc - 1 }) } 0 .. $nr - 1 } }

sub near {
	my ($got, $want, $name) = @_;
	my $err = 0;
	$err += abs($got->[$_] - $want->[$_]) for 0 .. $#$want;
	ok(@$got == @$want && $err < 1e-12, $name)
		or diag("error $err over " . scalar(@$got) . ' of ' . scalar(@$want) . ' values');
}

for my $method (qw(holm hochberg hommel bonferroni BH BY fdr none)) {
	my $q = flat_of($method);
	is(scalar @$q, scalar @p, "$method: the flat form still returns a flat list");

	my $rows = rows_of($q);
	my $colw = cols_of($q);

	my $a = p_adjust(aoa(), $method);
	is(ref $a, 'ARRAY', "$method: AoA in, AoA out");
	near([ map { @$_ } @$a ], [ map { @$_ } @$rows ], "$method: AoA values and order");

	my $h = p_adjust(aoh(), $method);
	near([ map { my $r = $_; map { $r->{$_} } @cols } @$h ],
	     [ map { @$_ } @$rows ], "$method: AoH values and order");
	is_deeply([ sort keys %{ $h->[0] } ], [ @cols ], "$method: AoH keeps its columns");

	my $ha = p_adjust(hoa(), $method);
	near([ map { @{ $ha->{$_} } } @cols ], [ map { @$_ } @$colw ],
	     "$method: HoA values and order");

	my $hh = p_adjust(hoh(), $method);
	near([ map { my $r = $hh->{$_}; map { $r->{$_} } @cols } sort keys %$hh ],
	     [ map { @$_ } @$rows ], "$method: HoH values and order");
	is_deeply([ sort keys %$hh ], [ map { "r$_" } 0 .. $nr - 1 ],
	          "$method: HoH keeps its row labels");
}

# columns => picks the p-value columns and leaves everything else alone

my @genes = qw(BRCA1 TP53 EGFR KRAS);
my @gp    = (0.01, 0.04, 0.03, 0.20);
my @gq    = p_adjust([@gp], 'BH');

{
	my $df = [ map { +{ gene => $genes[$_], n => $_ + 1, p_value => $gp[$_] } } 0 .. $#gp ];
	my $out = p_adjust($df, 'BH', columns => 'p_value');
	is_deeply([ map { $_->{gene} } @$out ], \@genes, 'AoH: untouched columns pass through');
	is_deeply([ map { $_->{n} } @$out ], [ 1 .. 4 ], 'AoH: numeric non-p column is not adjusted');
	near([ map { $_->{p_value} } @$out ], \@gq, 'AoH: only the named column is adjusted');
	is_deeply($df, [ map { +{ gene => $genes[$_], n => $_ + 1, p_value => $gp[$_] } } 0 .. $#gp ],
	          'AoH: the input frame is not modified');
}

{
	my $df = { gene => [@genes], p_value => [@gp] };
	my $out = p_adjust($df, 'BH', columns => ['p_value']);
	is_deeply($out->{gene}, \@genes, 'HoA: untouched column passes through');
	near($out->{p_value}, \@gq, 'HoA: only the named column is adjusted');
}

{
	my $df = { map { ($genes[$_] => { p_value => $gp[$_], label => $genes[$_] }) } 0 .. $#gp };
	my $out = p_adjust($df, 'BH', columns => 'p_value');
	is_deeply([ sort keys %$out ], [ sort @genes ], 'HoH: row labels survive');
	is($out->{TP53}{label}, 'TP53', 'HoH: untouched column passes through');
	# family order here is by row label, not by input order
	my @by_label = p_adjust([ map { $df->{$_}{p_value} } sort @genes ], 'BH');
	near([ map { $out->{$_}{p_value} } sort @genes ], \@by_label,
	     'HoH: only the named column is adjusted');
}

{
	# AoA columns are 0-based positions
	my $df  = [ map { [ $genes[$_], $gp[$_] ] } 0 .. $#gp ];
	my $out = p_adjust($df, 'BH', columns => 1);
	is_deeply([ map { $_->[0] } @$out ], \@genes, 'AoA: column 0 passes through');
	near([ map { $_->[1] } @$out ], \@gq, 'AoA: column 1 is adjusted');
}

# method may be positional, a key, or defaulted
{
	my $df = [ { p => 0.01 }, { p => 0.04 } ];
	my $a = p_adjust($df, 'BH', columns => 'p');
	my $b = p_adjust($df, method => 'BH', columns => 'p');
	my $c = p_adjust($df, columns => 'p');
	is_deeply($a, $b, 'method reads the same positionally and as a key');
	near([ map { $_->{p} } @$c ], [ p_adjust([ 0.01, 0.04 ]) ],
	     'method defaults to holm for frames too');
}

# edges and errors

is_deeply(p_adjust({}), {}, 'an empty hash comes back an empty hash');
is_deeply(p_adjust([ [], [] ]), [ [], [] ], 'empty AoA rows come back empty');
is_deeply([ p_adjust([]) ], [], 'an empty arrayref still returns an empty list');

{
	# undef counts as 1, the way the flat form has always treated it
	my $out = p_adjust([ [ 0.01, undef ] ], 'bonferroni');
	near($out->[0], [ 0.02, 1 ], 'undef cells count toward the family as 1');
}

{
	my $single = p_adjust([ [0.003] ], 'BH');
	near($single->[0], [0.003], 'a one-cell frame returns its p-value unchanged');
}

my $labelled = [ { gene => 'BRCA1', p => 0.01 } ];
eval { p_adjust($labelled, 'BH') };
like($@, qr/is not a p-value/, 'a label column without columns => is an error');
like($@, qr/columns => /, 'the error says how to fix it');

eval { p_adjust($labelled, 'BH', columns => 'pvalue') };
like($@, qr/no column named 'pvalue'/, 'a column name that is not there is an error');

eval { p_adjust([ 0.1, 0.2 ], columns => 'p') };
like($@, qr/needs a data frame/, "columns => on a flat list is an error");

eval { p_adjust([ [0.1], { p => 0.2 } ]) };
like($@, qr/not an ARRAY reference/, 'a frame of mixed row types is an error');

eval { p_adjust({ p => 0.1 }) };
like($@, qr/must hold ARRAY references/, 'a flat hash is not a frame');

eval { p_adjust([ [0.1] ], 'BH', bogus => 1) };
like($@, qr/unknown argument 'bogus'/, 'unknown options are rejected');

eval { p_adjust([ [0.1] ], 'not-a-method') };
like($@, qr/Unknown p-value adjustment method/, 'the method is still validated');

if ($HAVE_LEAKTRACE && !$INC{'Devel/Cover.pm'}) {
	for my $case (
		[ 'AoA', sub { p_adjust(aoa(), 'BH') } ],
		[ 'AoH', sub { p_adjust(aoh(), 'hommel') } ],
		[ 'HoA', sub { p_adjust(hoa(), 'BY') } ],
		[ 'HoH', sub { p_adjust(hoh(), 'holm') } ],
		[ 'columns', sub { p_adjust($labelled, 'BH', columns => 'p') } ],
		[ 'bad column', sub { eval { p_adjust($labelled, 'BH', columns => 'zzz') } } ],
		[ 'label column', sub { eval { p_adjust($labelled, 'BH') } } ],
		[ 'bad method', sub { eval { p_adjust(aoa(), 'zzz') } } ],
	) {
		my ($name, $code) = @$case;
		no_leaks_ok { $code->() } "p_adjust: no memory leaks ($name)";
	}
}

done_testing();
