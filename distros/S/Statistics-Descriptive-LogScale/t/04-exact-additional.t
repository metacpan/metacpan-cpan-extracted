#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;
use Data::Dumper;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new (floor => 0.5, base => 2);

$stat->add_data(1, 2, 4, 8, 16);

# note "log 2 = ".log 2;
# note Dump($stat);

is ($stat->mean, 6.2, "mean (this tests nothing new)");
is ($stat->geometric_mean, 4, "geometric");
is ($stat->harmonic_mean, 5/(2-1/16), "harmonic");

is ($stat->quantile(0), 1, "Q0");
is ($stat->quantile(1), 2, "Q1");
is ($stat->quantile(2), 4, "Q2");
is ($stat->quantile(3), 8, "Q3");
is ($stat->quantile(4), 16, "Q4");
eval {
	$stat->quantile(5)
};
my $err = $@;
like( $err, qr(tics::Descr.*must), "Q5 dies" );

# check integration...
is ($stat->sum_of( sub{ 1 }, 2, 8, ), 2, "sum_of(1, 2, 8)");
is ($stat->sum_of( sub{ 1 }, 1, 2, ), 1, "sum_of(1, 1, 2)");
is ($stat->sum_of( sub{ 1 }, undef, 5 )+$stat->sum_of( sub{ 1 }, 5, undef ),
	$stat->sum_of( sub{ 1 } ), "sum (1, -inf..+inf)");

is ($stat->sum_of( sub{ $_[0] }, 2, 8, ), 2/2 + 4 + 8/2, "sum(x, 2, 8)");
is (
	 $stat->sum_of( sub{ $_[0] }, undef, 5 )
	+$stat->sum_of( sub{ $_[0] }, 5, undef ),
	 $stat->sum_of( sub{ $_[0] } ), "sum(x, -inf..+inf)");

is ($stat->trimmed_mean( 0.25 ), (1+4+4) / 2, "Trimmed mean");

# check cache deletion
note explain $stat->{cache};
$stat->add_data(1, 1);
ok (!exists $stat->{cache}, "Cache deleted on add");
