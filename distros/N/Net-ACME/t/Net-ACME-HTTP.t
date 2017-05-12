package t::Net::ACME::HTTP;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Crypt ();

use JSON ();

use HTTP::Tiny::UA::Response ();

use Net::ACME::HTTP ();
use Net::ACME::X ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub _KEY {
    return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAtDxWn2hMQWw7hhSW1LOvTOzrsvC3/n2Y9DA1VObSCGWsA0fI
WV3Q4aWjUL1Gov4FWnPwC3jQ4exXUAFb2+Xck31g1TNzQKKIgvTQVz1gMdktrbT0
+LbZEhwtIGwGee73NUnWcjFJtMHfDRtj0BM/F6numjHNk7kkPtaaGgq7Rx+pfRA/
5DESrWR6NuPDaw9CyAA2MNG4CAYwJPowCpzkeqgVfw38i9M3FIQ2yrCosksYmCQk
97IfmKA5C7hHPYB5Pvu+0BT4Hx29IOByYj4gBKK9x9EN5udI1F7oAZIWls3m14EO
x6e/guA6hKwfJ3xUSR2XPXYfVnvOBjS/LkB7dwIDAQABAoIBAQCGQkg4mKXtOiWg
/Gda7LrR786nzh8RaRfuFpcztnmQncQj8W3x/CukWxGsDEK5GcZ9Gc4fjZD0Kmzk
AQ8fYDwOdiAS0S+yXyCXhKxJwEOO/nvDYP/24aYTkn+fHjk4zWTDAkzHZaXFC4IP
Lm8Mybl+9Cv0GtNLjmfMk2nZqlLVaCQcFxNTWkO8AyP8MVUDP25z+TVTNPY+e1en
vS7UoovlF8rx4+eu0idVvQSSp/KS++QICMb92E65jFRMCPtouc+0Y6mlHtMTMBq4
H5FS/ZTv8zyXWtadJ17VnPev/QErDs+AJfOXuBQ4AP9ytcj+CH1Wd3J1zpEJDf2K
EvJInY1xAoGBAOvM56V75eH+PJucCerMdbbSJse/cIkRuyMMuCCLCd2LRZODeMEx
FXKkGGmzZAkmd6KM2rq4shnNLM9a6IcirVy3XRacLS++DymhzJYnlhaESFUDfsJV
/W8uRml8G2gZRap8yHTAsHBcaPFDlqrKKfLLfZEOZKswNB4iQCu7W2dPAoGBAMOs
5rTlqoM58hVSpC9Gyf22mYSHITC0ueJ45Is2YkBMsMBNbLWkiKK/dxbryHStkVy3
dZ2JzAQrfelwjpqGCMJVlg6TFDkyCh/mSSViH0cSbjJdLX/KKoB2GYPkK1j1Gk+g
MyrywLCAiIqUGnbIbNQzTLx+7UGUaVQcsP8Y2R9ZAoGAHmNz3xHOmIdpTCyZ4pai
/QKsWMXFPQT59xRmjlsc1F5kgxRIda1btECNnOGvnLZGaL56WeH/oe+dPMPcf73q
Va6T4pwR/rshvR3K/fbwEsrNf5dJuMXYOYHfNSz3Yz0Oi2A1fUZv9qsSIzWwryYK
re2nqxANzToTHWcQmhI1P2UCgYAE6uB1ZVwuphMmZAhKQ94pqSAci4TTA4e0YFNm
CDzZ3tOGUavMuNDSPjuQ8OX9wKrpiJbFGcRtymYEqtZ6nam0sI/v19RnR5GnkZL/
BINCtvzb+Sl+j6cXyWAEx4QrXSWHIMCIcMdU6DYGPYiYuZq6jnt8NThjMIahHYN5
NbenKQKBgQCcdLYVlMeHw9esSNR4n5Dkz7QWqzVUPw9LHMjWZtVcAuW4eXs17lBd
yqHZkgBwJy0liPWspScIe4DayQ4uwNZivQrX8a6fI+e/Mygk9L8qsOSCWnChaQrA
bGrQ//km5dLiXZqn9L403eyC1hHZc8fq6kGslDVcknRQ0MSv2A88JQ==
-----END RSA PRIVATE KEY-----
END
}

sub test_get_and_post : Tests(8) {
    my ($self) = @_;

    my $key_pem = _KEY();

    my $ua = Net::ACME::HTTP->new(
        key => $key_pem,
    );

    throws_ok(
        sub { $ua->post( 'no importa', { haha => 1 } ) },
        qr<nonce>,
        'post() before nonce is set dies',
    );

    my $server_err = Net::ACME::X::create(
        'HTTP::Protocol',
        {
            method  => 'HAHA',
            url     => 'http://the/url',
            status  => '400',
            reason  => 'Generic',
            headers => {
                $Net::ACME::HTTP::_NONCE_HEADER => '123123',
                BlahBlah                           => 'ohh',
            },
            content => JSON::encode_json(
                {
                    type   => 'urn:ietf:params:acme:error:malformed',
                    detail => 'fofo',
                },
            ),
        }
    );

    #A nonsense request. Simplest case, doesn’t return anything useful.
    #----------------------------------------------------------------------
    throws_ok(
        sub { $ua->get(rand) },
        'Net::ACME::X::HTTP::Network',
        'get() with an invalid URL',
    );

    my @request_args;
    my $ua_request_cr;

    no warnings 'redefine';
    local *Net::ACME::HTTP::_ua_request = sub {
        my ( $self, @args ) = @_;

        @request_args = @args;

        return $ua_request_cr->(@args);
    };

    #A get() that the server will reject.
    #----------------------------------------------------------------------

    $ua_request_cr = sub { die $server_err };

    throws_ok(
        sub { $ua->get('doesn’t matter') },
        'Net::ACME::X::Protocol',
        'HTTP::Server error converts to Protocol',
    );
    my $err = $@;

    is_deeply(
        \@request_args,
        [ 'get', 'doesn’t matter' ],
        'get() passes args to UA request()',
    );

    cmp_deeply(
        $err,
        methods(
            [ get => 'url' ]     => 'http://the/url',
            [ get => 'status' ]  => '400',
            [ get => 'reason' ]  => 'Generic',
            [ get => 'headers' ] => superhashof( { BlahBlah => 'ohh' } ),
            [ get => 'type' ]    => 'urn:ietf:params:acme:error:malformed',
            [ get => 'detail' ]  => re(qr<\Afofo\s+\(.+\)\z>),
        ),
        'Protocol error method returns',
    ) or diag explain $err;

    #A post() that the server will accept.
    #----------------------------------------------------------------------

    $ua_request_cr = sub {
        return HTTP::Tiny::UA::Response->new(
            {
                headers => {
                    $Net::ACME::HTTP::_NONCE_HEADER => '234234',
                },
            }
        );
    };
    $ua->post( 'doesn’t matter', { foo => 123 } );

    my $jwt = $request_args[2]->{'content'};

    my ( $header, $payload ) = Test::Crypt::decode_jwt(
        token         => $jwt,
        key           => $key_pem,
    );

    is(
        $header->{'nonce'},
        123123,
        'after an error, JWS sent to post() includes the previous result’s nonce',
    ) or diag explain $header;

    cmp_deeply(
        $payload,
        { foo => 123 },
        'JWS sent to post() includes the payload',
    ) or diag explain $payload;

    #A post() that the server will reject.
    #----------------------------------------------------------------------

    $ua_request_cr = sub { die $server_err };

    #cf. eval_bug.readme
    my $eval_err = $@;

    eval { $ua->post( 'doesn’t matter', { foo => 123 } ) };

    $@ = $eval_err;

    $jwt = $request_args[2]->{'content'};

    ( $header, $payload ) = Test::Crypt::decode_jwt(
        token         => $jwt,
        key           => $key_pem,
    );

    is(
        $header->{'nonce'},
        234234,
        'after success, JWS sent to post() includes the previous result’s nonce',
    ) or diag explain $header;

    return;
}

1;
