#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps = 1e-7 if not defined $eps;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}

# Reference values from R's epitools::ageadjust.direct algorithm (Fay-Feuer
# gamma CI) replicated in base R with qgamma.
my @count  = (5, 20, 55, 60);
my @pop    = (1000, 3000, 4000, 2000);
my @stdpop = (2000, 3000, 3000, 2000);

# --- positional form ------------------------------------------------------
{
	my $r = age_standardize(\@count, \@pop, \@stdpop);
	is_approx($r->{crude_rate}, 0.0140000000, 'crude rate');
	is_approx($r->{adj_rate},   0.0131250000, 'directly standardized rate');
	is_approx($r->{'conf.int'}[0], 0.0109781852, 'gamma CI lower');
	is_approx($r->{'conf.int'}[1], 0.0156960916, 'gamma CI upper');
	is_approx($r->{'conf.level'}, 0.95, 'default conf.level', 1e-9);
}

# --- per-100,000 scaling --------------------------------------------------
{
	my $r = age_standardize(\@count, \@pop, \@stdpop, per => 100_000);
	is_approx($r->{adj_rate},      1312.5000, 'adj rate per 100k', 1e-3);
	is_approx($r->{'conf.int'}[0], 1097.8185, 'CI lower per 100k', 1e-3);
	is_approx($r->{'conf.int'}[1], 1569.6092, 'CI upper per 100k', 1e-3);
}

# --- named-argument form and rate input give the same answer --------------
{
	my $r = age_standardize(count => \@count, pop => \@pop, stdpop => \@stdpop);
	is_approx($r->{adj_rate}, 0.0131250000, 'named-arg form matches');

	my @rate = map { $count[$_] / $pop[$_] } 0 .. $#count;
	my $r2 = age_standardize(rate => \@rate, pop => \@pop, stdpop => \@stdpop);
	is_approx($r2->{adj_rate}, 0.0131250000, 'rate input matches count input');
}

# --- error handling -------------------------------------------------------
throws_ok { age_standardize(\@count, [1,2,3], \@stdpop) } qr/length/, 'pop length mismatch rejected';
throws_ok { age_standardize(pop => \@pop, stdpop => \@stdpop) } qr/count.*or.*rate/, 'needs count or rate';
throws_ok { age_standardize(\@count, \@pop, \@stdpop, conf_level => 1.5) } qr/conf.level/, 'bad conf.level rejected';

no_leaks_ok {
	age_standardize(\@count, \@pop, \@stdpop);
	age_standardize(\@count, \@pop, \@stdpop, per => 100_000, conf_level => 0.9);
} 'age_standardize does not leak';

done_testing();
