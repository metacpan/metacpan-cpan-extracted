#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Number::Delta within => 1E-12;

use Statistics::Descriptive::LogScale;

ok_persistent( {}, [1..5] );
ok_persistent( { base => 1.1, linear_width => 0.1 }, [1..5] );
ok_persistent( { base => 1.1, linear_thresh => 2 }, [1..5] );

my $empty = Statistics::Descriptive::LogScale->new;
my $raw = $empty->TO_JSON;

is(     $raw->{CLASS},       ref $empty,        "[TO_JSON]: ref");
like(   $raw->{VERSION},     qr(^\d+(\.\d+)?$), "[TO_JSON]: Version present" );
cmp_ok( $raw->{base},        ">", 1,            "[TO_JSON]: bin base returned correctly" );
is(     $raw->{linear_width},   0,                 "[TO_JSON]: Default linear_width = 0" );
is(     $raw->{linear_thresh}, 0,                 "[TO_JSON]: Default linear_thresh = 0" );

done_testing;

my $n_test;
sub ok_persistent {
	my ($setup, $sample) = @_;
	$n_test++;
	my $fail = 0;

	my $stat1 = Statistics::Descriptive::LogScale->new( %$setup );
	$stat1->add_data( @$sample );

	my $raw = $stat1->TO_JSON;
	my $sub;
	foreach my $stat2 (
		Statistics::Descriptive::LogScale->new(%$raw), $stat1->clone) {
		$sub++;

		is_deeply( $stat2->TO_JSON, $raw,
			"[$n_test/$sub] TO_JSON consistent" ) or $fail++;
		note explain($stat1->TO_JSON, $stat2->TO_JSON );
		is_deeply( $stat2->get_data_hash, $stat1->get_data_hash,
			"[$n_test/$sub] Data hash consistent" ) or $fail++;

		foreach my $method (qw(count mean median std_dev skewness kurtosis)) {
			delta_ok( $stat2->$method, $stat1->$method,
				"[$n_test/$sub] $method holds" )
					or $fail++;
		};

		# TODO or should I be using subtest here?
		ok (!$fail, "TO_JSON()/new() persistence test $n_test")
			or diag "setup was: ", explain($setup), "\n",
				, "sample was: ", explain($sample);
	};
	return !$fail;
};
