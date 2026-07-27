#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
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

#
# Exceptions & Input Validation
#
dies_ok {
	prcomp();
} 'prcomp: dies with no data';

dies_ok {
	prcomp("string data");
} 'prcomp: dies with non-reference data';

dies_ok {
	prcomp([ [1, 2] ], 'center');
} 'prcomp: dies with odd number of named arguments';

dies_ok {
	prcomp([]);
} 'prcomp: dies with empty array matrix';

dies_ok {
	prcomp([ [1, 2], [1, 2], [1, 2] ], scale => 1);
} 'prcomp: dies when scaling a zero-variance column';

dies_ok {
	prcomp([ 1, 2, 3 ]);
} 'prcomp: dies when an ArrayRef holds neither ArrayRefs (AoA) nor HashRefs (AoH)';

dies_ok {
	prcomp([ {}, {} ]);
} 'prcomp (AoH): dies when the row hashes are empty';

# ==============================================================================
# Matrix (Array of Arrays) Base Calculations
# ==============================================================================
my $aoa = [ 
	[2, 4], 
	[4, 2], 
	[6, 6] 
];

my $pca = prcomp($aoa);

my $n_keys = scalar keys %{ $pca };
if ($n_keys == 5) { # sdev, rotation, x, center, scale
	pass('prcomp (AoA): returns the correct # of hash keys (5)');
} else {
	fail("prcomp (AoA): returned $n_keys keys, expected 5");
}

# Values for this specific test matrix:
# Col 1: var = 4. Col 2: var = 4. Cov = 2.
# Eigenvalues of Cov Matrix [4 2 ; 2 4] are 6 and 2.
# Sdev = sqrt(6), sqrt(2) = 2.4494897, 1.4142135
is_approx($pca->{sdev}[0], 2.44948974, 'prcomp (AoA): PC1 standard deviation', 1e-7);
is_approx($pca->{sdev}[1], 1.41421356, 'prcomp (AoA): PC2 standard deviation', 1e-7);

# Center should be the column means (4 and 4)
is_approx($pca->{center}[0], 4.0, 'prcomp (AoA): center var1', 1e-13);
is_approx($pca->{center}[1], 4.0, 'prcomp (AoA): center var2', 1e-13);

# Rotations (Eigenvectors) span 1D spaces, so sign is arbitrary. Test magnitude.
is_approx(abs($pca->{rotation}[0][0]), 0.70710678, 'prcomp (AoA): rotation magnitude PC1', 1e-7);
is_approx(abs($pca->{rotation}[0][1]), 0.70710678, 'prcomp (AoA): rotation magnitude PC2', 1e-7);

no_leaks_ok {
	prcomp($aoa);
} 'prcomp: no leaks when given Array of Arrays' unless $INC{'Devel/Cover.pm'};

# ==============================================================================
# Array of Hashes (AoH)
# ==============================================================================
# Columns are taken from the first row hash and sorted alphabetically: A, B.
# A -> [2, 4, 6]
# B -> [4, 2, 6]
# This is the identical mathematical matrix as the AoA above, so every result
# must match it exactly.
my $aoh = [
	{ B => 4, A => 2 },
	{ B => 2, A => 4 },
	{ B => 6, A => 6 }
];

$pca = prcomp($aoh);

$n_keys = scalar keys %{ $pca };
if ($n_keys == 6) { # sdev, rotation, x, center, scale, +varnames
	pass('prcomp (AoH): returns the correct # of hash keys (6)');
} else {
	fail("prcomp (AoH): returned $n_keys keys, expected 6");
}

is_deeply($pca->{varnames}, ['A', 'B'], 'prcomp (AoH): column names are parsed and sorted alphabetically');

is_approx($pca->{sdev}[0], 2.44948974, 'prcomp (AoH): PC1 standard deviation identically matches AoA', 1e-7);
is_approx($pca->{sdev}[1], 1.41421356, 'prcomp (AoH): PC2 standard deviation identically matches AoA', 1e-7);

is_approx($pca->{center}[0], 4.0, 'prcomp (AoH): center of column A', 1e-13);
is_approx($pca->{center}[1], 4.0, 'prcomp (AoH): center of column B', 1e-13);

is_approx(abs($pca->{rotation}[0][0]), 0.70710678, 'prcomp (AoH): rotation magnitude PC1', 1e-7);
is_approx(abs($pca->{rotation}[0][1]), 0.70710678, 'prcomp (AoH): rotation magnitude PC2', 1e-7);

my $x_rows_aoh = scalar @{ $pca->{x} };
if ($x_rows_aoh == 3) {
	pass('prcomp (AoH): rotated data retains one row per observation');
} else {
	fail("prcomp (AoH): expected rotated data to have 3 rows, got $x_rows_aoh");
}

# Row order of an AoH is meaningful (unlike a HoH), so the scores must line up
# row-for-row with the equivalent AoA input.
my $pca_aoa_ref = prcomp($aoa);
foreach my $i (0 .. 2) {
	foreach my $m (0 .. 1) {
		is_approx($pca->{x}[$i][$m], $pca_aoa_ref->{x}[$i][$m],
			"prcomp (AoH): score [$i][$m] matches the equivalent AoA input", 1e-9);
	}
}

# Insertion order of the row hashes' keys must not matter: columns are sorted.
my $aoh_shuffled = [
	{ A => 2, B => 4 },
	{ A => 4, B => 2 },
	{ A => 6, B => 6 }
];
my $pca_shuffled = prcomp($aoh_shuffled);
is_deeply($pca_shuffled->{varnames}, $pca->{varnames},
	'prcomp (AoH): varnames are independent of hash key insertion order');
is_approx($pca_shuffled->{sdev}[0], $pca->{sdev}[0],
	'prcomp (AoH): sdev is independent of hash key insertion order', 1e-13);

# scale => 1 over an AoH: Cov becomes [1, 0.5 ; 0.5, 1], eigenvalues 1.5 & 0.5
my $pca_aoh_scaled = prcomp($aoh, scale => 1);
is_approx($pca_aoh_scaled->{sdev}[0], 1.22474487, 'prcomp (AoH): scaled PC1 standard deviation', 1e-7);
is_approx($pca_aoh_scaled->{sdev}[1], 0.70710678, 'prcomp (AoH): scaled PC2 standard deviation', 1e-7);

# rank restriction still applies to named-column input
my $pca_aoh_rank = prcomp($aoh, rank => 1);
my $n_sdev_aoh = scalar @{ $pca_aoh_rank->{sdev} };
if ($n_sdev_aoh == 1) {
	pass('prcomp (AoH): rank limit restricts the number of components');
} else {
	fail("prcomp (AoH): expected 1 component, got $n_sdev_aoh");
}

# retx => 0 suppresses the rotated data for AoH as well
my $pca_aoh_noretx = prcomp($aoh, retx => 0);
if (not exists $pca_aoh_noretx->{x}) {
	pass('prcomp (AoH): retx => 0 omits the x key');
} else {
	fail('prcomp (AoH): retx => 0 still returned an x key');
}

#---------------------------------------
# AoH: listwise deletion of unusable rows
#---------------------------------------
# Row 2 carries a non-numeric value, so it is dropped. The surviving matrix is
# C1 = [2, 6] (mean 4), C2 = [4, 6] (mean 5) => [8 4 ; 4 2], eigenvalues 10 & 0.
my $aoh_na = [
	{ A => 2, B => 4 },
	{ A => 4, B => 'NA' },
	{ A => 6, B => 6 }
];
my $pca_aoh_na = prcomp($aoh_na);
my $x_rows_na = scalar @{ $pca_aoh_na->{x} };
if ($x_rows_na == 2) {
	pass('prcomp (AoH): listwise deletion drops rows holding non-numeric cells');
} else {
	fail("prcomp (AoH): expected rotated data to have 2 rows, got $x_rows_na");
}
is_approx($pca_aoh_na->{sdev}[0], 3.16227766, 'prcomp (AoH): math adjusts dynamically for new N-1', 1e-7);
is_approx($pca_aoh_na->{sdev}[1], 0.0, 'prcomp (AoH): collinear matrix component is zero', 1e-7);

# A ragged row that is missing a column entirely is dropped the same way.
my $aoh_ragged = [
	{ A => 2, B => 4 },
	{ A => 4 },
	{ A => 6, B => 6 }
];
my $pca_ragged = prcomp($aoh_ragged);
my $x_rows_ragged = scalar @{ $pca_ragged->{x} };
if ($x_rows_ragged == 2) {
	pass('prcomp (AoH): rows missing a column are dropped listwise');
} else {
	fail("prcomp (AoH): expected rotated data to have 2 rows, got $x_rows_ragged");
}
is_approx($pca_ragged->{sdev}[0], 3.16227766, 'prcomp (AoH): ragged input yields the N=2 solution', 1e-7);

dies_ok {
	prcomp([ { A => 1, B => 2 }, { A => 1, B => 2 } ], scale => 1);
} 'prcomp (AoH): dies when scaling a zero-variance column';

dies_ok {
	prcomp([ { A => 'x', B => 'y' } ]);
} 'prcomp (AoH): dies when no row survives listwise deletion';

no_leaks_ok {
	prcomp($aoh);
} 'prcomp: no leaks when given Array of Hashes' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	prcomp($aoh_ragged, scale => 1, rank => 1);
} 'prcomp: no leaks for Array of Hashes with listwise deletion and options' unless $INC{'Devel/Cover.pm'};

#---------------------
# Hash of Arrays (HoA)
#---------------------
# Keys will be sorted alphabetically internally: A, B. 
# A -> [2, 4, 6]
# B -> [4, 2, 6]
# This yields the identical mathematical matrix as above.
my $hoa = { B => [4, 2, 6], A => [2, 4, 6] };
$pca = prcomp($hoa);

$n_keys = scalar keys %{ $pca };
if ($n_keys == 6) { # sdev, rotation, x, center, scale, +varnames
	pass('prcomp (HoA): returns the correct # of hash keys (6)');
} else {
	fail("prcomp (HoA): returned $n_keys keys, expected 6");
}

is_deeply($pca->{varnames}, ['A', 'B'], 'prcomp (HoA): column names are parsed and sorted alphabetically');
is_approx($pca->{sdev}[0], 2.44948974, 'prcomp (HoA): PC1 standard deviation identically matches AoA', 1e-7);

no_leaks_ok {
	prcomp($hoa);
} 'prcomp: no leaks when given Hash of Arrays' unless $INC{'Devel/Cover.pm'};

#
# Hash of Hashes (HoH)
#
my $hoh = {
	row1 => { A => 2, B => 4 },
	row2 => { A => 4, B => 2 },
	row3 => { A => 6, B => 6 }
};
$pca = prcomp($hoh);

is_deeply($pca->{varnames}, ['A', 'B'], 'prcomp (HoH): column names are parsed and sorted alphabetically');
is_approx($pca->{sdev}[0], 2.44948974, 'prcomp (HoH): PC1 standard deviation identically matches AoA/HoA', 1e-7);

no_leaks_ok {
	prcomp($hoh);
} 'prcomp: no leaks when given Hash of Hashes' unless $INC{'Devel/Cover.pm'};

#
# Parameters: scale => 1
#s
$pca = prcomp($aoa, scale => 1);

# When scaled to unit variance, Cov Matrix is [1, 0.5 ; 0.5, 1].
# Eigenvalues are 1.5 and 0.5.
# Sdev = sqrt(1.5), sqrt(0.5)
is_approx($pca->{sdev}[0], 1.22474487, 'prcomp (Scale): scaled PC1 standard deviation', 1e-7);
is_approx($pca->{sdev}[1], 0.70710678, 'prcomp (Scale): scaled PC2 standard deviation', 1e-7);

if (ref $pca->{scale} eq 'ARRAY') {
	pass('prcomp (Scale): scale key returns an ARRAY reference when enabled');
} else {
	fail('prcomp (Scale): scale key did not return an ARRAY reference');
}

# ==============================================================================
# Parameters: tol & rank restrictions
# ==============================================================================
# The original Sdevs are ~2.449 and ~1.414
# Setting tol to 0.6 creates a threshold of 2.449 * 0.6 = 1.469
# 1.414 is less than 1.469, so PC2 should be omitted.
my $pca_tol = prcomp($aoa, tol => 0.6);

my $n_sdev = scalar @{ $pca_tol->{sdev} };
if ($n_sdev == 1) {
	pass('prcomp (Tol): successfully restricted components by tolerance threshold');
} else {
	fail("prcomp (Tol): expected 1 component, got $n_sdev");
}

my $pca_rank = prcomp($aoa, rank => 1);
$n_sdev = scalar @{ $pca_rank->{sdev} };
if ($n_sdev == 1) {
	pass('prcomp (Rank): successfully restricted components by explicit rank limit');
} else {
	fail("prcomp (Rank): expected 1 component, got $n_sdev");
}

my $rot_cols = scalar @{ $pca_rank->{rotation}[0] };
if ($rot_cols == 1) {
	pass('prcomp (Rank): rotation matrix dimensions restricted correctly');
} else {
	fail("prcomp (Rank): rotation matrix expected 1 column, got $rot_cols");
}

# ==============================================================================
# Missing Data / Listwise Deletion
# ==============================================================================
my $aoa_na = [ 
	[2, 4], 
	[4, 'NA'], 
	[6, 6] 
];

# Data matrix becomes N=2 implicitly after NA dropping
my $pca_na = prcomp($aoa_na);
my $x_rows = scalar @{ $pca_na->{x} };

if ($x_rows == 2) {
	pass('prcomp (NA): seamlessly performed listwise deletion of incomplete rows');
} else {
	fail("prcomp (NA): expected rotated data to have 2 rows, got $x_rows");
}

# Standard deviations of N=2 data:
# C1 = [2, 6] (mean=4), C2 = [4, 6] (mean=5)
# Var1 = ((-2)^2 + 2^2) / 1 = 8
# Var2 = ((-1)^2 + 1^2) / 1 = 2
# Cov = (-2*-1 + 2*1) / 1 = 4
# Matrix = [8 4 ; 4 2]. Eigenvalues = 10, 0. Sdevs = sqrt(10), 0.
is_approx($pca_na->{sdev}[0], 3.16227766, 'prcomp (NA): math adjusts dynamically for new N-1', 1e-7);
is_approx($pca_na->{sdev}[1], 0.0, 'prcomp (NA): collinear matrix component is zero', 1e-7);

done_testing();
