#!/usr/bin/perl -w

use strict;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new;
# let's do some ad-hoc statistics =)
my ($n, $sum, $sum2);

$stat->add_data(1..10);

note "Histogram test - 5 intervals";
my $hist = $stat->frequency_distribution_ref(5);
note explain $hist;

($n, $sum, $sum2) = (0,0,0);
for (values %$hist) {
	$n++;
	$sum  += $_;
	$sum2 += $_*$_;
};
is ($n, 5, "Number of intervals as expected");
is ($sum, $stat->count, "histogram sum == count");
my $std_dev = sqrt( $sum2 / $n - ($sum / $n)**2 );
cmp_ok( $std_dev, "<", 0.1, "Histogram is level");

# check newer histogram interface
my $hist2 = $stat->histogram(count => 5);
my %hist2pp = map { $_->[2] => $_->[0] } @$hist2;
is_count_hash ( \%hist2pp, $hist, "histogram == freq_distr_ref");

note "arbitrary cut: (-inf, 3, 6, 9, 12)";
$hist  = $stat->frequency_distribution_ref([3, 6, 9, 12]);
note explain $stat->{data};
note explain $hist;

($n, $sum, $sum2) = (0,0,0);
for (values %$hist) {
	$n++;
	$sum  += $_;
	$sum2 += $_*$_;
};

is ($n, 4, "Number of intervals as expected");
is ($sum, $stat->count, "histogram sum == count");

# check newer histogram interface
$hist2 = $stat->histogram(index => [ -9**9, 3, 6, 9, 12 ]);
%hist2pp = map { $_->[2] => $_->[0] } @$hist2;
is_count_hash ( \%hist2pp, $hist, "histogram == freq_distr_ref");

$hist2 = $stat->histogram( count =>4, min => 0, max => 12 );
note explain $hist2;
%hist2pp = map { $_->[2] => $_->[0] } @$hist2;
is_count_hash ( \%hist2pp, $hist, "histogram == freq_distr_ref");

# check hist2 chaining
my @upper = map { $_->[2] } @$hist2;
my @lower = map { $_->[1] } @$hist2;
shift @lower;
pop @upper;
is_deeply( \@upper, \@lower, "upper == lower");

# checking histogram normalization
my $hist3 = $stat->histogram(
	count =>4, min => 0, max => 12, normalize_to => 10 );
note explain $hist3;
my $max = 0;
$max < $_->[0] and $max = $_->[0] for @$hist3;
is ($max, 10, "normalize works (max holds)");

# let's spoil hist2 now and check normalize better
$max = 0;
$max < $_->[0] and $max = $_->[0] for @$hist2;
$_->[0] *= 10/$max for @$hist2;

my %as_hash_2 = map { ($_->[1]+$_->[2])/2, $_->[0] } @$hist2;
my %as_hash_3 = map { ($_->[1]+$_->[2])/2, $_->[0] } @$hist3;

is_count_hash( \%as_hash_3, \%as_hash_3, "normalize works (ratios hold)");

done_testing;

sub is_count_hash {
	my ($got, $expect, $message) = @_;

	# diff the hashes
	my %diff;
	$diff{$_} += $got->{$_}    for keys %$got;
	$diff{$_} -= $expect->{$_} for keys %$expect;

	# join keys that are too close
	my @keys = sort { $a <=> $b } keys %diff;
	for (my $i = 1; $i<@keys; $i++) {
		($keys[$i] - $keys[$i-1]) / (abs($keys[$i]) + abs($keys[$i-1])) < 1E-12
			or next;
		$diff{ $keys[$i] } += delete $diff{ $keys[$i-1] };
	};

	# filter out near-zeros
	abs($diff{$_}) > 1E-12 or delete $diff{$_} for keys %diff;

	ok (!%diff, $message)
		or diag "got = "  , explain $got,
			"expected = " , explain $expect,
			"diff = "     , explain \%diff;
	return !%diff;
};
