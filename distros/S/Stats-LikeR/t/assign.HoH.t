#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'refaddr';
use Test::Exception; # dies_ok, throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR;

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
	  next if defined $arg;
	  die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
	  $i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
	  pass("$test_name: within $epsilon");
	  return 1;
	} else {
	  fail($test_name);
	  diag("         got: $got\n    expected: $expected; diff = $diff");
	  return 0;
	}
}

# --------
# Setup basic test HoH
# --------
my $hoh = {
	Alice => { weight => 65, height => 1.70 },
	Bob   => { weight => 90, height => 1.85 },
};

# --------
# Standard Assignment & Chaining Operations
# --------
my $returned_ref = assign($hoh,
    bmi   => sub { $_->{weight} / ($_->{height} ** 2) },
    class => sub { $_->{bmi} > 25 ? 'high' : 'ok' }
);

# 1. Output structure check
is($hoh->{'Alice'}{'class'}, 'ok', 'Chained column uses earlier calculated column properly (Alice)');
is($hoh->{'Bob'}{'class'}, 'high', 'Chained column uses earlier calculated column properly (Bob)');

# 2. Math check via is_approx
is_approx($hoh->{'Alice'}{'bmi'}, 22.49134948, 'BMI dynamically calculated correctly');
is_approx($hoh->{'Bob'}{'bmi'}, 26.29656683, 'BMI dynamically calculated correctly');

# 3. Check exact reference returned
is(refaddr($returned_ref), refaddr($hoh), 'assign() successfully returned original hash reference for chaining');

# --------
# Indexing ($_[1]) and Row Key ($_[2]) Context checks
# --------
my $metadata_hoh = { 'Row A' => { data => 1 }, 'Row B' => { data => 2 } };

assign($metadata_hoh,
    numeric_index => sub { $_[1] },
    row_key_name  => sub { $_[2] }
);

is($metadata_hoh->{'Row A'}{'numeric_index'}, 0, 'First alphabetically sorted row gets index 0');
is($metadata_hoh->{'Row B'}{'numeric_index'}, 1, 'Second alphabetically sorted row gets index 1');
is($metadata_hoh->{'Row A'}{'row_key_name'}, 'Row A', '$_[2] context exposes exact outer hash key successfully');

# --------
# Whole-column coderef: a list return (>1 value) fills the whole column,
# aligned to sorted key order
# --------
my $wc = {
	a => { v => 30 },
	b => { v => 10 },
	c => { v => 20 },
};
assign($wc, col => sub { (100, 200, 300) });
is($wc->{a}{col}, 100, 'HoH: whole-column coderef aligns to sorted key a');
is($wc->{b}{col}, 200, 'HoH: whole-column coderef aligns to sorted key b');
is($wc->{c}{col}, 300, 'HoH: whole-column coderef aligns to sorted key c');

# --------
# Arrayref value: a ready-made column, aligned to sorted key order, copied in
# --------
my $av = { a => {}, b => {}, c => {} };
my @src = (7, 8, 9);
assign($av, num => \@src);
is($av->{a}{num}, 7, 'HoH: arrayref value aligns to sorted key a');
is($av->{b}{num}, 8, 'HoH: arrayref value aligns to sorted key b');
is($av->{c}{num}, 9, 'HoH: arrayref value aligns to sorted key c');
$src[0] = 999;
is($av->{a}{num}, 7, 'HoH: arrayref value is copied, not aliased');

# --------
# A single arrayref return is a per-row cell, NOT a column
# --------
my $sc = { a => {}, b => {} };
assign($sc, cell => sub { [1, 2] });
is_deeply($sc->{a}{cell}, [1, 2], 'HoH: single arrayref return stays a per-row cell (a)');
is_deeply($sc->{b}{cell}, [1, 2], 'HoH: single arrayref return stays a per-row cell (b)');

# --------
# rank() integration -- the motivating whole-column use case
# --------
SKIP: {
	skip 'rank() not available', 3 unless defined &rank;
	my $rh = { a => { v => 30 }, b => { v => 10 }, c => { v => 20 } };
	assign($rh, r => sub { rank( map { $rh->{$_}{v} } sort keys %$rh ) });
	is($rh->{a}{r}, 3, 'HoH: rank() whole-column, a(30) -> rank 3');
	is($rh->{b}{r}, 1, 'HoH: rank() whole-column, b(10) -> rank 1');
	is($rh->{c}{r}, 2, 'HoH: rank() whole-column, c(20) -> rank 2');
}

# --------
# Overwriting an existing column
# --------
my $ow = { a => { x => 1 }, b => { x => 2 } };
assign($ow, x => sub { $_->{x} * 10 });
is($ow->{a}{x}, 10, 'HoH: overwrites existing column (a)');
is($ow->{b}{x}, 20, 'HoH: overwrites existing column (b)');

# --------
# map_cell: in-place per-cell edit; $_ is the cell, return value ignored
# --------
my $mc = {
	Alice => { 'Res.' => 'A:foo' },
	Bob   => { 'Res.' => 'B:bar' },
};
my $mc_ret = assign($mc, 'Res.' => map_cell { s/^[A-Z]:// });
is(refaddr($mc_ret), refaddr($mc), 'HoH map_cell: returns the original ref for chaining');
is($mc->{Alice}{'Res.'}, 'foo', 'HoH map_cell: in-place s/// (Alice), return value ignored');
is($mc->{Bob}{'Res.'}, 'bar', 'HoH map_cell: in-place s/// (Bob)');

# map_cell exposes the row as $_[0], the index as $_[1], and the row key as $_[2]
my $mk = { a => { v => 'x' }, b => { v => 'y' } };
assign($mk, v => map_cell { $_ = "$_-$_[1]-$_[2]" });
is($mk->{a}{v}, 'x-0-a', 'HoH map_cell: $_[1] index and $_[2] row key (a)');
is($mk->{b}{v}, 'y-1-b', 'HoH map_cell: $_[1] index and $_[2] row key (b)');

# map_cell leaves undef cells untouched (undef in -> undef out)
my $mu = { a => { 'Res.' => 'A:foo' }, b => { 'Res.' => undef }, c => {} };
my $mu_ran = 0;
assign($mu, 'Res.' => map_cell { $mu_ran++; s/^[A-Z]:// });
is($mu_ran, 1, 'HoH map_cell: block runs only for the defined cell');
is($mu->{a}{'Res.'}, 'foo', 'HoH map_cell: defined cell edited');
ok(!defined $mu->{b}{'Res.'}, 'HoH map_cell: undef cell stays undef');
ok(!exists $mu->{c}{'Res.'}, 'HoH map_cell: missing cell stays missing');

# --------
# Length mismatch dies for both column-value kinds
# --------
throws_ok { assign({ a => {}, b => {} }, bad => [1]) }
	qr/1 values but data frame has 2 rows/,
	'HoH: arrayref column length mismatch dies';
throws_ok { assign({ a => {}, b => {} }, bad => sub { (1, 2, 3) }) }
	qr/produced 3 values but data frame has 2 rows/,
	'HoH: whole-column length mismatch dies';

# --------
# Exception Trapping
# --------
dies_ok { assign('not a ref', a => sub {}) } 'assign dies gracefully on non-reference frame';
dies_ok { assign($hoh, 'lone_key') } 'assign dies gracefully on odd number of arguments (missing code block)';
dies_ok { assign($hoh, new_col => 'not a code ref') } 'assign dies gracefully when value is neither CODE nor ARRAY ref';
dies_ok { assign({ bad => 'string' }, col => sub {}) } 'assign dies gracefully if an inner HoH row is not a hashref';

# --------
# Memory Integrity
# --------
no_leaks_ok {
    eval {
        my $tmp_frame = { r1 => { val => 10 } };
        assign($tmp_frame, new_val => sub { $_[0]->{val} * 2 });
    }
} 'assign(HoH): no memory leaks (per-row)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
    eval {
        my $t = { a => {}, b => {}, c => {} };
        assign($t, col => sub { (1, 2, 3) });
    }
} 'assign(HoH): no memory leaks (whole-column coderef)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
    eval {
        my $t = { a => {}, b => {} };
        assign($t, num => [10, 20]);
    }
} 'assign(HoH): no memory leaks (arrayref value)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
    eval {
        my $t = { a => { s => 'A:1' }, b => { s => 'B:2' } };
        assign($t, s => map_cell { s/^[A-Z]:// });
    }
} 'assign(HoH): no memory leaks (map_cell)' unless $INC{'Devel/Cover.pm'};

done_testing();
