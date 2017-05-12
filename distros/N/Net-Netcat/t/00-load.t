#!perl

use strict;
use warnings;
use Net::Netcat;
use Test::More qw( no_plan );

BEGIN {
	use_ok( 'Net::Netcat' );
}

diag( "Testing Net::Netcat");

my $nc = Net::Netcat->new();
$nc->{options} = {'-v' => 1};
$nc->exec();
is($? >> 8, 1, "Netcat found");
