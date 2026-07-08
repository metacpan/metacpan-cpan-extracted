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

# ==============================================================================
# Exceptions & Input Validation
# ==============================================================================
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

# ==============================================================================
# Hash of Hashes (HoH)
# ==============================================================================
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

# ==============================================================================
# Parameters: scale => 1
# ==============================================================================
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
