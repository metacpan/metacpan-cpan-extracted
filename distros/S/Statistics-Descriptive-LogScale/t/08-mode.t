#!/usr/bin/perl -w

use strict;
use Test::More;

use Carp;
$SIG{__WARN__} = sub { $_[0] =~ /DEBUG/ ? warn $_[0]: Carp::confess($_[0]) };

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new;

$stat->add_data(1) for 1..5;
is ($stat->mode, 1, "mode(1)");

$stat->clear;
$stat->add_data(0) for 1..5;
is ($stat->mode, 0, "mode(0)");

$stat->clear;
$stat->add_data(1,0) for 1..5;
is ($stat->mode, 0, "mode(0,1)");

note "Triangle => mode == mean";
$stat->clear;
$stat->add_data_hash(triangle(10, 11));
is ($stat->count, 121, "self-test: count == 121");
note "expected mode = 10, real mode = " . $stat->mode
	. ", mean = ", $stat->mean;
my @index_show = map { sprintf "%5.2f", $_ } @{ $stat->_sort };
note "index       = @index_show";
cmp_ok( $stat->mode, "<", $stat->mean+1, "mode ~ mean");
cmp_ok( $stat->mode, ">", $stat->mean-1, "mode ~ mean");

# check for huge peak near zero
$stat->clear();
$stat->add_data( (1)x 100, 1000..1010 );
is ($stat->mode, 1, "peak detected in 1 x 100, 1000..1010");

# check for huge peak near infinity
$stat->clear();
$stat->add_data( (1000)x 20, 1..10 );
is ($stat->mode, $stat->_round(1000), "peak detected in 1000 x 20, 1..10");

# check triangle vs big tail

TODO: {
	local $TODO = "Combining bins requires much work";
	$stat->clear();
	$stat->add_data_hash( { 1000 => 2000 } );
	$stat->add_data_hash( triangle( 2, 100, 0.001 ) );
	is ($stat->mode, $stat->_round(2), "Dense triangle outweights big tail");
};

done_testing();
# TODO more tests!

sub triangle {
	my ($center, $size, $step) = @_;

	$step ||= 1;

	my %freq;
	for (my $i=$size; $i-->0; ) {
		$freq{$center+$i*$step} = $size - $i;
	};
	for (my $i=$size; $i-->1; ) {
		$freq{$center-$i*$step} = $size - $i;
	};

	return \%freq;
};
