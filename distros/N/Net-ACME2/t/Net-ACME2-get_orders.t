#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use Digest::MD5;
use HTTP::Status;
use URI;
use JSON;

use Crypt::Format ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;

#----------------------------------------------------------------------

{
    package MyCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

my $_P256_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKDv8TBijBVbTYB7lfUnwLn4qjqWD0GD7XOXzdp0wb61oAoGCCqGSM49
AwEHoUQDQgAEBJIULcFadtIBc0TuNzT80UFcfkQ0U7+EPqEJNXamG1H4/z8xVgE7
3hoBfX4xbN2Hx2p26eNIptt+1jj2H/M44g==
-----END EC PRIVATE KEY-----
END

subtest 'get_orders() returns order URLs' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    # No orders yet
    my @orders = $acme->get_orders();
    is( scalar @orders, 0, 'no orders initially' );

    # Create an order
    $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    @orders = $acme->get_orders();
    is( scalar @orders, 1, 'one order after create_order()' );
    like( $orders[0], qr{/order/1$}, 'order URL points to correct order' );

    # Create a second order
    $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.org' },
        ],
    );

    @orders = $acme->get_orders();
    is( scalar @orders, 2, 'two orders after second create_order()' );
    like( $orders[1], qr{/order/2$}, 'second order URL correct' );
};

subtest 'get_orders() without account creation throws' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );

    throws_ok(
        sub { $acme->get_orders() },
        qr/orders.*URL/i,
        'get_orders() dies without orders URL',
    );
};

subtest 'get_orders() works for existing account' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );

    # First registration
    $acme->create_account( termsOfServiceAgreed => 1 );

    # Create an order
    $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    # Second call returns existing account (HTTP 200)
    my $acme2 = MyCA->new( key => $_P256_KEY );
    my $created = $acme2->create_account();
    is( $created, 0, 'account already existed' );

    # orders URL should still be available from 200 response
    my @orders = $acme2->get_orders();
    is( scalar @orders, 1, 'get_orders() works after retrieving existing account' );
};

done_testing();
