#!perl

use strict;
use warnings;
use Progress::PV;
use Test::More qw( no_plan );

BEGIN {
	use_ok( 'Progress::PV' );
}

diag( "Testing Progress::PV");

my $pv = Progress::PV->new();
$pv->{options} = {'-V' => 1};
$pv->pr();
is($? >> 8, 0, "pv found");
