#!perl

use strict;
use warnings;
use Net::Ifstat;
use Test::More qw( no_plan );

BEGIN {
	use_ok( 'Net::Ifstat' );
}

diag( "Testing Net::Ifstat");

my $if = Net::Ifstat->new();
$if->{options} = {'-v' => 1};
$if->exec();
is($? >> 8, 0, "Ifstat found");
