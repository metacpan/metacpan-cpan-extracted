#!perl

use Test::Most;
use Net::Iugu;

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name   => 'read_by_identifier',
        args   => ['555'],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/plans/identifier/555',
    },
);

check_endpoint( $api->plans, @tests );

done_testing;

##############################################################################

