#!perl

use Test::Most;
use Net::Iugu;

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name => 'create',
        args => [
            {
                name  => 'Nome do Cliente',
                email => 'email@email.com',
                notes => 'Anotações Gerais',
            }
        ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/customers',
    },
    {
        name   => 'read',
        args   => ['777'],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/customers/777',
    },
    {
        name   => 'update',
        args   => [ '777', { default_payment_method_id => 999 } ],
        method => 'PUT',
        uri    => 'https://api.iugu.com/v1/customers/777',
    },
    {
        name   => 'delete',
        args   => ['777'],
        method => 'DELETE',
        uri    => 'https://api.iugu.com/v1/customers/777',
    },
    {
        name   => 'list',
        args   => [ { limit => 10 } ],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/customers',
    },
);

check_endpoint( $api->customers, @tests );

done_testing;

##############################################################################

