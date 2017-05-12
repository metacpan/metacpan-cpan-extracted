#!perl

use Test::Most;
use Net::Iugu;

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name   => 'transfer',
        args   => [ { receiver_id => 1, amount_cents => 1234 } ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/transfers',
    },
    {
        name   => 'list',
        args   => [],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/transfers',
    },
);

check_endpoint( $api->transfers, @tests );

done_testing;

##############################################################################

