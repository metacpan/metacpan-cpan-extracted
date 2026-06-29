#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

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

# ============================================================================
# 1. min / max (Baseline Sanity Checks)
# ============================================================================
is_approx( min(1, 2, 2.33, 3), 1, 'min of scalars');
is_approx( max(1, 2, 2.33, 3), 3, 'max of scalars');

no_leaks_ok {
    eval { min(1, 2, 2.33, 3) }
} 'min(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#
# 2. assign()
#
 my $aoh = [ { a => 1, b => 2 }, { a => 3, b => 4 } ];
 my $hoa = { a => [1, 3], b => [2, 4] };

 # AoH assignment
 my $res_aoh = assign($aoh, sum_ab => sub { $_->{a} + $_->{b} });
 is($res_aoh->[0]{sum_ab}, 3, 'assign AoH: row 0 correct');
 is($res_aoh->[1]{sum_ab}, 7, 'assign AoH: row 1 correct');

 # HoA assignment
 my $res_hoa = assign($hoa, sum_ab => sub { $_->{a} + $_->{b} });
 is_deeply($res_hoa->{sum_ab}, [3, 7], 'assign HoA: column added correctly');

 # Exceptions
 dies_ok { assign("not a ref", x => sub { 1 }) } 'assign dies on non-reference';
 dies_ok { assign($aoh, 'odd_list') } 'assign dies on odd number of arguments';
 dies_ok { assign($aoh, bad_code => "not a sub") } 'assign dies if value is not a coderef';

no_leaks_ok {
    eval { assign([ {x=>1} ], 'y' => sub { $_->{x} + 1 }) }
} 'assign(): no memory leaks' unless $INC{'Devel/Cover.pm'};


# 3. col() and filter()
my $df = [
  { id => 1, age => 20, grp => 'a' },
  { id => 2, age => 17, grp => 'b' },
  { id => 3, age => 25, grp => 'a' }
];

# Basic numeric comparison (col() predicate)
my $adults = filter($df, col('age') >= 18);
is(scalar @$adults, 2, 'filter AoH: col() >= operator');
is($adults->[0]{id}, 1, 'filter AoH: kept correct row 1');

# operands may be written in either order
is(scalar @{ filter($df, 18 <= col('age')) }, 2, 'filter AoH: col() operand order');

# String comparison combined with &
my $grp_a = filter($df, (col('grp') eq 'a') & (col('age') > 18));
is(scalar @$grp_a, 2, 'filter AoH: col() & with string eq');

# HoA filtering
my $hoa_df = { id => [1, 2, 3], age => [20, 17, 25] };
$res_hoa = filter($hoa_df, col('age') < 20);
is_deeply($res_hoa->{id}, [2], 'filter HoA: col() kept correct column slice');

# A coderef predicate expresses anything col() can't (here, modulo). filter()
# accepts a CODE ref or a col() expression interchangeably.
my $code_res = filter($df, sub { $_->{age} % 2 == 0 });
is(scalar @$code_res, 1, 'filter AoH: coderef predicate');

# HoH input (new): matching keys are preserved by default
my $hoh_df = { r1 => { age => 20 }, r2 => { age => 17 }, r3 => { age => 25 } };
my $hoh_keep = filter($hoh_df, col('age') >= 18);
is_deeply([ sort keys %$hoh_keep ], ['r1', 'r3'], 'filter HoH: matching keys preserved');

# output.type (new): convert the result shape while filtering
my $as_hoa = filter($df, col('age') >= 18, 'output.type' => 'hoa');
is_deeply([ sort { $a <=> $b } @{ $as_hoa->{age} } ], [20, 25], 'filter: output.type => hoa');
my $as_aoh = filter($hoa_df, col('age') < 20, 'output.type' => 'aoh');
is_deeply([ map { $_->{id} } @$as_aoh ], [2], 'filter: HoA input -> output.type => aoh');

no_leaks_ok { filter($df, col('age') >= 18) } 'filter(): no memory leaks' unless $INC{'Devel/Cover.pm'};


#
# 4. dropna()
#
$aoh = [
  { a => 1,     b => 2 },
  { a => undef, b => 3 },
  { a => 4,     b => undef }
];

# AoH: any vs all
my $drop_any = dropna($aoh, cols => ['a', 'b'], how => 'any');
is(scalar @$drop_any, 1, 'dropna AoH cols/any: keeps complete rows only');

my $drop_all = dropna($aoh, cols => ['a', 'b'], how => 'all');
is(scalar @$drop_all, 3, 'dropna AoH cols/all: keeps partials');

# HoA: rows literal drop
$hoa = { x => [10, 20, 30] };
my $drop_rows = dropna($hoa, rows => [1]);
is_deeply($drop_rows->{x}, [10, 30], 'dropna HoA rows: drops explicit index');

# Exceptions
dies_ok { dropna($aoh, bad_arg => 1) } 'dropna dies on unknown args';
dies_ok { dropna($aoh, cols => ['a'], rows => [1]) } 'dropna dies if both cols and rows passed';

#
# 5. read_table()
#
my $csv_content = <<'EOF';
# This is a comment
id,name,val
1,Alice,10.5
2,Bob,
3,Charlie,15.2
EOF

my $fh = File::Temp->new(SUFFIX => '.csv', DIR => '/tmp', UNLINK => 1);
print $fh $csv_content;
close $fh;
say 'writing ' . $fh->filename;

# Basic AoH reading
$aoh = read_table($fh->filename, sep => ',', comment => '#');
is(scalar @$aoh, 3, 'read_table AoH: read 3 rows');
is($aoh->[0]{name}, 'Alice', 'read_table AoH: parsed field correctly');
is($aoh->[1]{val}, undef, 'read_table AoH: empty field parsed as undef');

# HoH reading with row.names
my $hoh = read_table($fh->filename, 'output.type' => 'hoh', 'row.names' => 'id');
is($hoh->{1}{name}, 'Alice', 'read_table HoH: row name mapping correct');

# Reading with inline filter
my $filtered = read_table($fh->filename, filter => { 'val' => sub { defined $_ && $_ > 11 } });
is(scalar @$filtered, 1, 'read_table: inline filter applied');
is($filtered->[0]{name}, 'Charlie', 'read_table: filter kept correct row');

#
# 6. Data Transformations (aoh2hoa, hoh2hoa)
#
# aoh2hoa
$aoh = [ { a => 1, b => 2 }, { a => 3 } ];
$hoa = aoh2hoa($aoh);
is_deeply($hoa->{a}, [1, 3], 'aoh2hoa: column a transposed');
is_deeply($hoa->{b}, [2, undef], 'aoh2hoa: ragged column b padded with undef');

# hoh2hoa
$hoh = { r1 => { a => 1, b => 2 }, r2 => { a => 3, c => 9 } };
my $hoa_from_h = hoh2hoa($hoh, 'undef.val' => 'NA');
is_deeply($hoa_from_h->{a}, [1, 3], 'hoh2hoa: dense column');
is_deeply($hoa_from_h->{b}, [2, 'NA'], 'hoh2hoa: fill applied to missing cell');

no_leaks_ok {
	eval { aoh2hoa([ { a => 1 } ]) }
} 'aoh2hoa(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#
# 7. Statistics XS Wrappers (Mock/Documented Functionality Checks)
#
# chisq_test (1D goodness of fit)
my $chi_1d = chisq_test([10, 20, 30]);
is($chi_1d->{'method'}, 'Chi-squared test for given probabilities', 'chisq_test 1D: Correct method');
is_deeply($chi_1d->{'expected'}, [20, 20, 20], 'chisq_test 1D: Expected values calculated');

# fisher_test
my $fish_matrix = [ [10, 2], [3, 15] ];
my $fish_res = fisher_test($fish_matrix);
is($fish_res->{'method'}, "Fisher's Exact Test for Count Data", 'fisher_test: Method name');
ok(exists $fish_res->{'p_value'}, 'fisher_test: Returned a p-value');

# dnorm
my $dnorm_val = dnorm(0, mean => 0, sd => 1, log => 0);
ok(looks_like_number($dnorm_val), 'dnorm returns a numeric value');
is_approx($dnorm_val, 0.39894228, 'dnorm at mean 0 sd 1 (standard normal) is ~0.3989', 1e-5);

#
# 8. col2col
#
my %data = (
  'x' => [1, 2, 3, 4],
  'y' => [2, 4, 6, 8],
  z => [1, 1, 1, 1]
);

my $res = col2col(\%data, 'cor', undef, 'skip.errors' => 1);

# Should calculate perfect correlation
is_approx($res->{x}{y}, 1.0, 'col2col: cor(x,y) = 1.0');

# Should catch errors safely if standard dev is 0 (z column)
ok(!looks_like_number($res->{x}{z}), 'col2col: skips errors and returns message string for constant vector');

#
# 9. glm & aov 
#
my $glm_data = {
  'x' => [1, 2, 3, 4, 5],
  'y' => [2.1, 3.9, 6.2, 8.1, 10.0]
};

# We expect glm to parse the formula, fit, and return a structured hash
my $glm_res = glm(data => $glm_data, formula => 'y ~ x', family => 'gaussian');
ok(exists $glm_res->{coefficients}, 'glm: Returns coefficients');
ok(exists $glm_res->{aic}, 'glm: Returns AIC');
is($glm_res->{family}, 'gaussian', 'glm: Maintains family parameter');

# aov implicit stacking 
my $aov_data = {
  ctrl  => [1, 1, 1],
  yield => [4.5, 4.8, 4.2]
};
my $aov_res = aov($aov_data);
ok(exists $aov_res->{Residuals}, 'aov: Evaluates and returns Residuals table without formula');

done_testing();
