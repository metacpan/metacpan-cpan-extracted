#!perl

use Test::Most;
use Net::Iugu;

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name   => 'suspend',
        args   => ['111'],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/subscriptions/111/suspend',
    },
    {
        name   => 'activate',
        args   => ['222'],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/subscriptions/222/activate',
    },
    {
        name   => 'change_plan',
        args   => [ '111', '222' ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/subscriptions/111/change_plan/222',
    },
    {
        name   => 'add_credits',
        args   => [ '333', '4567', { quantity => 4567 } ],
        method => 'PUT',
        uri    => 'https://api.iugu.com/v1/subscriptions/333/add_credits',
    },
    {
        name   => 'remove_credits',
        args   => [ '444', '9989', { quantity => 9989 } ],
        method => 'PUT',
        uri    => 'https://api.iugu.com/v1/subscriptions/444/remove_credits',
    },
);

check_endpoint( $api->subscriptions, @tests );

done_testing;

##############################################################################

