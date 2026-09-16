#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();

# The budget from plan_pool_snooker/02-physics-balls.md: a break under 10 ms, an
# ordinary shot under 2 ms. Measured and reported; asserted only against
# ceilings ten times looser, because a timing assertion on a loaded smoker is a
# failure that says nothing (reference_timing_assertions_smokers).

use Physics::Balls;
use Presets;

plan tests => 2;

my %world = map { $_ => Presets::world_exact($_) } Presets::names();
my %fx = map { ("$_->{table}/$_->{id}" => $_) } Presets::fixtures();

sub best_of {
	my ($runs, $fx) = @_;
	my $best;
	for (1 .. $runs) {
		my $t0 = Time::HiRes::time();
		my $out = Physics::Balls->strike($world{ $fx->{table} }, layout => $fx->{layout}, %{ $fx->{shot} });
		my $dt = (Time::HiRes::time() - $t0) * 1000;
		die $out->message if $out->error;
		$best = $dt if !defined $best || $dt < $best;
	}
	return $best;
}

my $break = best_of(5, $fx{'pool/break'});
my $shot = best_of(5, $fx{'pool/straight'});
diag(sprintf 'pool break %.2f ms (budget 10), straight pot %.2f ms (budget 2)', $break, $shot);
ok $break < 100, 'a break is under ten times its budget';
ok $shot < 20, 'an ordinary shot is under ten times its budget';
