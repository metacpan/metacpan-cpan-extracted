#!perl

use Test::Most;
use Sub::Override;

use HTTP::Message;

use Net::Iugu;

use JSON qw{ from_json to_json };

## Setup
my $override = Sub::Override->new;
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name          => 'create_token',
        request_data  => _create_token_data(),
        response      => _create_token_response(),
        response_data => _create_token_response_data(),
        method        => 'POST',
        uri           => 'https://api.iugu.com/v1/payment_token',
    },
    {
        name          => 'charge',
        request_data  => _charge_data(),
        response      => _charge_response(),
        response_data => _charge_response_data(),
        method        => 'POST',
        uri           => 'https://api.iugu.com/v1/charge',
    },
);

foreach my $test (@tests) {
    subtest 'Calling ' . $test->{name} => sub {
        _subtest($test);
    };
}

done_testing;
##############################################################################

sub _subtest {
    my ($test) = @_;

    ## Overwriting LWP::UserAgent::request()
    ## to verify request and fake the response
    my $request;
    $override->replace(
        'LWP::UserAgent::request' => sub {
            ( undef, $request ) = @_;
            return $test->{response};
        },
    );

    my $call = $test->{name};
    my $res  = $api->$call( $test->{request_data} );

    ## Request headers
    is(
        $request->headers->header('content-type'),    ##
        'application/json',                           ##
        'Checking header Content-Type',               ##
    );

    is(
        $request->headers->header('authorization'),    ##
        'Basic MTIzNDU2Nzg5MDo=',                      ##
        'Checking header Authorization',               ##
    );

    ## Request method
    is( $request->method, $test->{method}, 'Checking HTTP method' );

    ## Request URI
    is( $request->uri . '', $test->{uri}, 'Checking URI', );

    ## Request data
    my $data = from_json $request->content;
    is_deeply( $data, $test->{request_data}, 'Checking data' );

    ## Inflating response
    is_deeply( $res, $test->{response_data}, 'Inflating response' );
}

sub _create_token_data {
    return {
        account_id => '9876543210',
        method     => 'credit_card',
        test       => 'true',
        data       => {
            number             => '4111111111111111',
            verification_value => '123',
            first_name         => 'Joao',
            last_name          => 'Silva',
            month              => 12,
            year               => 2013,
        },
    };
}

sub _create_token_response {
    my $json = to_json _create_token_response_data();

    return HTTP::Response->new( 200, 'OK', HTTP::Headers->new, $json );
}

sub _create_token_response_data {
    return {
        id     => '77C2565F6F064A26ABED4255894224F0',
        method => 'credit_card',
    };
}

sub _charge_data {
    return {
        token => '123AEAE123EA0kEIEIJAEI',
        email => 'teste@teste.com',
        items => [
            {
                description => 'Item Um',
                quantity    => '1',
                price_cents => '1000',
            },
            {
                description => 'Item Dois',
                quantity    => '2',
                price_cents => '700',
            },
        ],
        payer => {
            cpf_cnpj     => '12312312312',
            name         => 'Nome do Cliente',
            phone_prefix => '11',
            phone        => '12121212',
            email        => 'teste@teste.com',
            address      => {
                street   => 'Rua Tal',
                number   => '700',
                city     => 'São Paulo',
                state    => 'SP',
                country  => 'Brasil',
                zip_code => '12122-000',
            },
        },
    };
}

sub _charge_response {
    my $json = to_json _charge_response_data();

    return HTTP::Response->new( 200, 'OK', HTTP::Headers->new, $json );
}

sub _charge_response_data {
    return {
        'success'    => 'true',
        'message'    => 'Autorizado',
        'invoice_id' => '53B53D39F7AD44C4B8B873E15F067193',
    };
}

