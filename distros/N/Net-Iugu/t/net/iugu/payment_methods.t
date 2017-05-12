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
            '888',
            {
                description => 'Meu Cartão de Crédito',
                item_type   => 'credit_card',
                data        => {
                    number             => '4111111111111111',
                    verification_value => '123',
                    first_name         => 'Joao',
                    last_name          => 'Silva',
                    month              => '12',
                    year               => '2013',
                },
            }
        ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/customers/888/payment_methods',
    },
    {
        name   => 'read',
        args   => [ '111', '999' ],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/customers/111/payment_methods/999',
    },
    {
        name => 'update',
        args => [ '111', '999', { description => 'Novo Cartão de Crédito' } ],
        method => 'PUT',
        uri    => 'https://api.iugu.com/v1/customers/111/payment_methods/999',
    },
    {
        name   => 'delete',
        args   => [ '111', '999' ],
        method => 'DELETE',
        uri    => 'https://api.iugu.com/v1/customers/111/payment_methods/999',
    },
    {
        name   => 'list',
        args   => ['111'],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/customers/111/payment_methods',
    },
);

check_endpoint( $api->payment_methods, @tests );

done_testing;

##############################################################################

