#!perl

use Test::Most;
use Net::Iugu;

use Sub::Override;

use JSON qw{ from_json };
use File::Slurp qw{ read_file };
use MIME::Base64 qw{ encode_base64 };

use lib 't/lib';
use MyTest qw{ check_endpoint };

## Setup
my $api = Net::Iugu->new( token => '1234567890' );

my @tests = (
    {
        name   => 'create_account',
        args   => [ { name => 'Subconta', commission_percent => 10 } ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/marketplace/create_account',
    },
    {
        name   => 'account_info',
        args   => ['111'],
        method => 'GET',
        uri    => 'https://api.iugu.com/v1/accounts/111',
    },
    {
        name   => 'request_withdraw',
        args   => [ '555', '123.45', { amount => '123.45' } ],
        method => 'POST',
        uri    => 'https://api.iugu.com/v1/accounts/555/request_withdraw',
    },
);

check_endpoint( $api->market_place, @tests );

########################################

my $api_token  = '123';
my $user_token = '456';
my $account_id = '789';

$api = Net::Iugu->new( token => "$api_token:" );

my $request;
my $override = Sub::Override->new;
$override->replace(
    'LWP::UserAgent::request' => sub {
        ( undef, $request ) = @_;

        ## Discard fake response
        return HTTP::Response->new( 200, 'OK', HTTP::Headers->new, '{}' );
    }
);

subtest 'Calling request_account_verification' => sub {
    my $input = _request_account_verification_data();
    my %files = %{ $input->{files} };

    my $res = $api->market_place->request_account_verification(
        $user_token,    ##
        $account_id,    ##
        $input,         ##
    );

    my $req = from_json $request->content;
    ## Request headers
    is(
        $request->headers->header('content-type'),    ##
        'application/json',                           ##
        'Checking header Content-Type',               ##
    );

    is(
        $request->headers->header('authorization'),    ##
        'Basic NDU2Og==',                              ##
        'Checking header Authorization',               ##
    );

    ## Request method
    is( $request->method, 'POST', 'Checking HTTP method' );

    ## Request URI
    is(
        $request->uri . '',
        "https://api.iugu.com/v1/accounts/$account_id/request_verification",
        'Checking URI',
    );

    ## Request data
    is_deeply( $req->{data}, $input->{data}, 'Checking data' );

    ## Files
    is_deeply(
        $req->{files},
        {
            id       => _slurp_image( $files{id} ),
            cpf      => _slurp_image( $files{cpf} ),
            activity => _slurp_image( $files{activity} ),
        }
    );

    ## without files
    delete $input->{files};
    $res = $api->market_place->request_account_verification(
        $user_token,    ##
        $account_id,    ##
        $input,         ##
    );

    ## Request data
    is_deeply( $req->{data}, $input->{data}, 'Checking data without files' );
};

subtest 'Calling configurate_account' => sub {
    my $input = _configurate_account_data();

    my $res = $api->market_place->configurate_account(
        $user_token,    ##
        $input,         ##
    );

    my $req = from_json $request->content;
    ## Request headers
    is(
        $request->headers->header('content-type'),    ##
        'application/json',                           ##
        'Checking header Content-Type',               ##
    );

    is(
        $request->headers->header('authorization'),    ##
        'Basic NDU2Og==',                              ##
        'Checking header Authorization',               ##
    );

    ## Request method
    is( $request->method, 'POST', 'Checking HTTP method' );

    ## Request URI
    is(
        $request->uri . '',
        'https://api.iugu.com/v1/accounts/configuration',
        'Checking URI',
    );

    ## Request data
    is_deeply( $req, $input, 'Checking data' );
};

$override->restore('LWP::UserAgent::request');

done_testing;

##############################################################################

sub _slurp_image {
    my ($path) = @_;

    my $bytes = read_file( $path, { binmode => ':raw' } );
    my $data = 'data:image/jpeg;base64,' . encode_base64 $bytes, '';

    return $data;
}

sub _request_account_verification_data {
    return {
        data => {
            price_range        => 'Até R$ 100,00',
            physical_products  => 'false',
            business_type      => 'Serviços de Limpeza',
            person_type        => 'Pessoa Física',
            automatic_transfer => 'false',
            cpf                => '81564331490',
            name               => 'Nome da Pessoa',
            address            => 'Av. Paulista 320 cj 10',
            cep                => '01419-000',
            city               => 'São Paulo',
            state              => 'São Paulo',
            telephone          => '11-91231-1234',
            bank               => 'Itaú',
            bank_ag            => '1234',
            account_type       => 'Corrente',
            bank_cc            => '11231-2',
        },

        files => {
            id       => 't/share/white.jpg',    ## 10x10 white jpg
            cpf      => 't/share/empty.jpg',    ## empty file
            activity => 't/share/red.jpg',      ## 10x10 red jpg
        },
    };
}

sub _configurate_account_data {
    return {
        commission_percent => 10,
        bank_slip          => {
            active    => 'false',
            extra_due => 0,
        },
        credit_card => {
            active       => 'true',
            installments => 'false',
        },
    };
}

