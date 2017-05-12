#!perl

use Test::Most;
use Net::Iugu;

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name   => 'cancel',
        args   => ['222'],
        method => 'PUT',
        uri    => 'https://api.iugu.com/v1/invoices/222/cancel',
    },
    {
        name   => 'refund',
        args   => ['333'],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/invoices/333/refund',
    },
);

check_endpoint( $api->invoices, @tests );

done_testing;

##############################################################################

