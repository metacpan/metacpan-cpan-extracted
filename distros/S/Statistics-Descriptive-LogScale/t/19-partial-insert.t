#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new;

$stat->add_data( 1..5 );

eval { $stat->add_data( undef ); };
like ($@, qr(uninitialized), "Exception thrown: undef");

eval { $stat->add_data( "foo bar" ); };
like ($@, qr(numeric), "Exception thrown: numeric");

is ($stat->count, 5, "count consistent");

eval { $stat->add_data( 6,7, "foobar", 8 ) };
like ($@, qr(numeric), "Exception thrown: numeric");

is ($stat->count, 7, "Two inserted, third thrown");
is_consistent($stat);

my $forget = $stat->get_data_hash;
$_ *= -2 for values %$forget;
$stat->add_data_hash( $forget );

is_consistent( $stat );
is ($stat->count, 0, "Forgot all");

$stat->add_data(1..5, 1..5);

$stat->add_data_hash( { 1=>-1, 2=>-2, 3 => 3} );
is_consistent($stat);

is ($stat->_count(0.5, 1.5), 1, "Probability of 1 as expected");
is ($stat->_count(1.5, 2.5), 0, "Probability of 2 as expected");
is ($stat->_count(2.5, 3.5), 5, "Probability of 3 as expected");

my $check_data = $stat->get_data_hash;

# add_data_hash non-numeric insert
eval {
	$stat->add_data_hash( { 5=>-1, 6=>"foobar", 7 => 1} );
};
like ($@, qr(numeric), "Exception: non-numeric (add_data_hash)");
is_deeply($stat->get_data_hash, $check_data, "Nothing changed - bad data");
is_consistent($stat);

# add_data_hash +inf insert
eval {
	$stat->add_data_hash( { 1 => 9**9**9 } );
};
like ($@, qr([iI]nfin), "Exception: infinity (add_data_hash)");
is_deeply($stat->get_data_hash, $check_data, "Nothing changed - bad data");
is_consistent($stat);


# infinity & forgetting check
$stat->clear;
$stat->add_data(1, -1);
$stat->add_data_hash({ 1 => -9**9**9, 2=>-1, 3=>-9**9**9, -1 => -3 });
is_consistent($stat);
is($stat->count, 0, "Destroyed all data");

done_testing;

sub is_consistent {
	my ($stat, $msg) = @_;

	use warnings FATAL => qw(uninitialized numeric);

	my $hash = $stat->get_data_hash;
	my $count = 0;
	my @fail;
	foreach (keys %$hash) {
		eval { $count += $hash->{$_} };
		push @fail, $_ if ($@);
	};
	if (!@fail) {
		return cmp_ok( $stat->count, "==", $count, $msg || "Count consistent and equals $count");
	} else {
		fail( "Inconsistent get_data_hash: bad values in hash" );
		diag "manual count = $count, returned count = ".$stat->count;
		note explain $hash;
		return 0;
	};
};
