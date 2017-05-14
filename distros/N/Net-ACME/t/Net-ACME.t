package t::Net::ACME;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw(
  Test::ACMEServer
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use JSON ();

use HTTP::Tiny ();
use HTTP::Tiny::UA::Response ();

use Net::ACME::HTTP ();
use Net::ACME::Challenge::Pending::http_01 ();
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
MIIEogIBAAKCAQEAs5hW5M9Zti0UhYyeOAQ3VNZZRKfAwZqGhJ0ZB61r8rFQHgcP
76Q2M5WdbxrILYz6sxGkFu+fwktOxzqdCdQdIyPrWOWuD9JLmnbUK3WyppmyMv7e
p5BpyMnUNfw0+pnYQ56Z/rvqbkJyGYCaSzz2mqOGtTHnDuRVL9UjoI8nfXIi+PDH
lnQpeFD1o6GnLJqfU7Jlfsr/+Y5YBl0T/5OBmEtPq1DM3pcduCfSLRQHFdZU5Le4
e6ffyfkL79/P0rGrBROBEXNnUE8ErRlAtxJVysQSCt8Kzy5Nk81Ro+3EIqie/sK6
2415ihKCkAky+lHtVM86EJ8U6TWnPht4Afp6JwIDAQABAoIBAE9NppkUwm2CTHyI
Ulkz62bn27VISgJzhJDMef/84RzilRkdTzknjtOKbmFgNyJ+DTnDQWzrVOVLsbah
uDRd2JvqwYKYsRrFZqMHc7rZFxEf7yM7jf/58ew6yx0niBFcm7WINEHaorMbXhzK
v9cXTWGNce9S4M+fncooWLoOXIa0gTH7g7GKErsrqVaypWCo8ELcUIa76QvYMzT/
sS8PAlYxBLFSQdqNz9JB79eSsUuWaxvOL9Pq4HcJYgqi29TkeaMuxBtmYGd3ZVhY
v4s5FDEGy9iPOTpeU2p9amwvHNyM4W6etcqBrnRaaRjp52JsaAjpjCNa7SY3Ci9p
kmAVfsECgYEA3JBbB3T8GWA2DDkSyAm8jomFaHNmXiu7q6Z841G9bCcnXnGJGZnD
5nbFut6TbWIiCqnEbW90SGO5krfq0lDKtAQfRkkyjS9dqf8c9oKUZevqVbN57CHr
ng02ce+rszUayxYBcf9F2D2LrfFiD1NcFeQP9b1TNo2u5ejl/htpy2ECgYEA0HL2
0FYkLAmBY/NWjBgiW+DFzZNNWc6XI1PYhxmHMuFcLbaFTJe+TxhkXRb6mXOpDJRE
jHbfHZ+bpnCt/tPlFbP6zwHxpR1lsTKbWGvPfsejYsVBWQMgJupkwsxeOSDGmA0q
KVSp2YZolNg7lai2tgjMmQCDWzYhwTI3KuzEeocCgYACNS+0E2eymVPxK2EUv4Qz
qQy8zurnZmiqfzAg1mCfBIVQXLKSnwdm9yljhXbUUXclxC1DKypuzxC8dzrSgByH
UMM/YNwwrZiyautPTF9P5dyinvlJc81394nj+hIt6QornjzFd1iroXIUe6YPoTX6
wh2myA5dLW3iv0IOGRgmAQKBgDEctRw2/4TEpJC5F44gbY/6MICUESh0rVVsftqt
4BXT1RUMKPH32qXmGFd6f4bCInVNRa1WoJDpNxILAGPG5vWrFw/I5HdDqt8KDmHR
3OyA+vTdht0DCINCvITNA/Ivz7qpd2KPiQkwStmu7LMBMjNHdXUjEs/dvCw5uZfK
eyxnAoGAGFupnklyRuokZyB2lowu6PS8Kk2C7/wqOUUOZ4zZLqwh8Ev7KpDwHvQ9
QM7Vo37ltBF6ewo3Tyu7Z6f3SJXDMpHrHu3jklkZ1ow0c44QEafGeenLebUU7faX
tD1Gh1voIPdhMvtrQSo53Gwlx3REP6SC07MlW2NIGHw20eY4lqg=
-----END RSA PRIVATE KEY-----
END
}

sub _CERT1_haha_tld {
    return <<END;
-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIJAP/wkKfx+zlPMA0GCSqGSIb3DQEBCwUAMBMxETAPBgNV
BAMMCGhhaGEudGxkMB4XDTE2MTEyNDA0NDQzN1oXDTE2MTIyNDA0NDQzN1owEzER
MA8GA1UEAwwIaGFoYS50bGQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQCzmFbkz1m2LRSFjJ44BDdU1llEp8DBmoaEnRkHrWvysVAeBw/vpDYzlZ1vGsgt
jPqzEaQW75/CS07HOp0J1B0jI+tY5a4P0kuadtQrdbKmmbIy/t6nkGnIydQ1/DT6
mdhDnpn+u+puQnIZgJpLPPaao4a1MecO5FUv1SOgjyd9ciL48MeWdCl4UPWjoacs
mp9TsmV+yv/5jlgGXRP/k4GYS0+rUMzelx24J9ItFAcV1lTkt7h7p9/J+Qvv38/S
sasFE4ERc2dQTwStGUC3ElXKxBIK3wrPLk2TzVGj7cQiqJ7+wrrbjXmKEoKQCTL6
Ue1UzzoQnxTpNac+G3gB+nonAgMBAAGjYjBgMB0GA1UdDgQWBBSJMv0enUUb3Jab
OjEIihiImVKLUDAfBgNVHSMEGDAWgBSJMv0enUUb3JabOjEIihiImVKLUDAJBgNV
HRMEAjAAMBMGA1UdEQQMMAqCCGhhaGEudGxkMA0GCSqGSIb3DQEBCwUAA4IBAQBG
7exhTUFPCGDTAnwr6Lw0jCrKM7HVsMQfVTn4I9UbXgMQT9msgVzZxi4kHRl0gbR2
0IwvGyDqxNhucc0BFUfmrvkRxpXagVe4M2PvTd0e8vUocvM5iotX6I0x7FGsYX4b
Atj7KRHSX3bIi6bXKP23BQNwvJqODxzELus3gwBmxv072IQaRZbzpfDnU1qgT0db
BsJcd2PJT+uirg6j5eoxKNdGmpiJX9o5h1LANwTcaFnfnqluWh6vzMGOnONqkGHr
Rq+NZrJmITSNZ7NF08StXpYNhaG8TDLefl/Qgcr+DCWt0v/NbjnilPNOMboWfA7/
7H6ht87VB72MCiDhnbjD
-----END CERTIFICATE-----
END
}

sub _CERT2_haha_tld {
    return <<END;
-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIJAJxlvz9w3OmyMA0GCSqGSIb3DQEBCwUAMBMxETAPBgNV
BAMMCGhhaGEudGxkMB4XDTE2MTEyNDA0NDUzNFoXDTE2MTIyNDA0NDUzNFowEzER
MA8GA1UEAwwIaGFoYS50bGQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQC4RsBX6x8CPjUJ9FogavYJuaqBWfj4ANfKSy8XnUkW/6kDycIXjXh8jlSBM28n
KuFeyligo3WZDVqzvr2J6VYTuzkIBbewGkwO2vamYUprm8IBTg+wVYoxwNQNBE72
U2CkzJIKqUptIQp0BhLB+/iSB65/71Q6Mj+pHxymbnI4nd7El71z0TE+73AvZMY2
JW/5oLH+BGYS5WfuRPSpxqGyaCAiwLA0nzT7SzfH8wzXCSYC6EM0sCQ6/l8oMwN1
59RfVT8jSfF8fj50x9Nb/PkuB2f44jklbdrVWT295NfIWnArwg34G8nqbs4QRixv
QFI9gIt8FidAPELlNa8KFFF9AgMBAAGjYjBgMB0GA1UdDgQWBBQtWsye3RDpRRNa
hOxop53+LDc8CDAfBgNVHSMEGDAWgBQtWsye3RDpRRNahOxop53+LDc8CDAJBgNV
HRMEAjAAMBMGA1UdEQQMMAqCCGhhaGEudGxkMA0GCSqGSIb3DQEBCwUAA4IBAQCt
Y9Gnp9k7cs6o+Jn0eYo3TjB4/VuzT9VN2vZyUnA//tBNw0JF++T2BwWzm17V9UZm
QnOWs5R1WzVeiEQqU0UbMhdQOx1EHLS1v741ephZZcQ72pVjYiT2rmQ8fnAk6GdE
LFiv1g9u1j9gHs/MaotutJfccyVPUwkAuyjNnyzt+pR+skxrsCCvqzS62lHfen2X
/rWxz+JFTMWK8KEoHn9gz7oVbuEj/Elwr3G0V0Vq0VTCsNAZS0pIDRX+tE/Dvvwe
UqyfeY15oR6qcXdvojyXEOIHiVmt9I+jzNJXQIbDuhv+jNpdXolpfecSn12LWesZ
3gUuMFlHdervE5Y/fk+l
-----END CERTIFICATE-----
END
}

sub _CSR_haha_tld {
    return <<END;
-----BEGIN CERTIFICATE REQUEST-----
MIICazCCAVMCAQAwADCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALOY
VuTPWbYtFIWMnjgEN1TWWUSnwMGahoSdGQeta/KxUB4HD++kNjOVnW8ayC2M+rMR
pBbvn8JLTsc6nQnUHSMj61jlrg/SS5p21Ct1sqaZsjL+3qeQacjJ1DX8NPqZ2EOe
mf676m5CchmAmks89pqjhrUx5w7kVS/VI6CPJ31yIvjwx5Z0KXhQ9aOhpyyan1Oy
ZX7K//mOWAZdE/+TgZhLT6tQzN6XHbgn0i0UBxXWVOS3uHun38n5C+/fz9KxqwUT
gRFzZ1BPBK0ZQLcSVcrEEgrfCs8uTZPNUaPtxCKonv7CutuNeYoSgpAJMvpR7VTP
OhCfFOk1pz4beAH6eicCAwEAAaAmMCQGCSqGSIb3DQEJDjEXMBUwEwYDVR0RBAww
CoIIaGFoYS50bGQwDQYJKoZIhvcNAQELBQADggEBAHh/Wh5t0/L+jclvhijn8UJN
eRbicCnxRLBqQay04IyErnoBiR3LhtzWaHRTmWf8csXVOZpwZyRShs8IWIX4wPh9
gglkKCHFzjgcMRZt9ZwhC5RoJNqSyFVne0/yRtfLj4SOzeJ9OPjH7whs5Lh75oCq
xss8hFb5Zc0/+YjKudqSoQgYIUw5t1oWnGVQwkF0q6AX854uu6KHGO40uqD5boJN
2KtDuWP6KiePjIfpmFpWkJlDV7Uk+yNjQyvGe6Fp5Ohg+SPw6AKzjC0tCvbApDFw
sPndpEz0l2d/wexg0TViqgsaY0oJUFdrvhkB8KzlxzrStmex6NIrrcDW/j3BYmQ=
-----END CERTIFICATE REQUEST-----
END
}

sub _ACME_KEY {
    return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCkOYWppsEFfKHqIntkpUjmuwnBH3sRYP00YRdIhrz6ypRpxX6H
c2Q0IrSprutu9/dUy0j9a96q3kRa9Qxsa7paQj7xtlTWx9qMHvhlrG3eLMIjXT0J
4+MSCw5LwViZenh0obBWcBbnNYNLaZ9o31DopeKcYOZBMogF6YqHdpIsFQIDAQAB
AoGAN7RjSFaN5qSN73Ne05bVEZ6kAmQBRLXXbWr5kNpTQ+ZvTSl2b8+OT7jt+xig
N3XY6WRDD+MFFoRqP0gbvLMV9HiZ4tJ/gTGOHesgyeemY/CBLRjP0mvHOpgADQuA
+VBZmWpiMRN8tu6xHzKwAxIAfXewpn764v6aXShqbQEGSEkCQQDSh9lbnpB/R9+N
psqL2+gyn/7bL1+A4MJwiPqjdK3J/Fhk1Yo/UC1266MzpKoK9r7MrnGc0XjvRpMp
JX8f4MTbAkEAx7FvmEuvsD9li7ylgnPW/SNAswI6P7SBOShHYR7NzT2+FVYd6VtM
vb1WrhO85QhKgXNjOLLxYW9Uo8s1fNGtzwJAbwK9BQeGT+cZJPsm4DpzpIYi/3Zq
WG2reWVxK9Fxdgk+nuTOgfYIEyXLJ4cTNrbHAuyU8ciuiRTgshiYgLmncwJAETZx
KQ51EVsVlKrpFUqI4H72Z7esb6tObC/Vn0B5etR0mwA2SdQN1FkKrKyU3qUNTwU0
K0H5Xm2rPQcaEC0+rwJAEuvRdNQuB9+vzOW4zVig6HS38bHyJ+qLkQCDWbbwrNlj
vcVkUrsg027gA5jRttaXMk8x9shFuHB9V5/pkBFwag==
-----END RSA PRIVATE KEY-----
END
}

sub _get_acme {
    return t::Net::ACME::MockService->new( key => _ACME_KEY() );
}

sub test_get_certificate : Tests(3) {
    my ($self) = @_;

    my ( $key, $cert ) = ( _KEY(), _CERT1_haha_tld() );

    die "No cert!" if !$cert;

    my $issuer_cert = _CERT2_haha_tld();

    my $csr = _CSR_haha_tld();

    my $host = t::Net::ACME::MockService::_HOST();

    my %endpoints = (
        'get:directory' => sub { return $self->_server_send_directory() },

        'get:issuer_cert' => sub {
            return(
                200, 'OK',
                {
                    'Content-Type' => 'application/pkix-cert',
                },
                Crypt::Format::pem2der($issuer_cert),
            );
        },

        'post:mock-acme/mock-new-cert' => sub {
            return (
                201 => 'Created',
                {
                    'Content-Type' => 'application/pkix-cert',
                    Link           => qq{<https://$host/issuer_cert>;rel="up"},
                },
                Crypt::Format::pem2der($cert),
            );
        },
    );

    $self->_with_mocked_http_request(
        _ACME_KEY(),
        \%endpoints,
        sub {
            my $acme     = _get_acme();
            my $cert_obj = $acme->get_certificate($csr);

            is(
                Crypt::Format::pem2der( $cert_obj->pem() ),
                Crypt::Format::pem2der($cert),
                'pem()',
            );

            is(
                Crypt::Format::pem2der( ( $cert_obj->issuers_pem() )[0] ),
                Crypt::Format::pem2der($issuer_cert),
                'issuers_pem()',
            );
        },
    );

    my @requests = $self->_get_rest_calls(_ACME_KEY());

    cmp_deeply(
        \@requests,
        [
            ignore(),    #directory
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => '/mock-acme/mock-new-cert',
                    }
                ),
                POST => [
                    ignore(),    #header
                    {
                        resource => 'new-cert',
                        csr      => MIME::Base64::encode_base64url( Crypt::Format::pem2der($csr) ),
                    },
                ],
            },
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => '/issuer_cert',
                    }
                ),
                POST => ignore(),
            },
        ],
        'payload sent to server',
    ) or diag explain \@requests;

    #TODO: Add tests for 202 responses after either a fix for RT 114027
    #or moving this battery of tests not to use an actual HTTP server.

    return;
}

sub test_do_challenge : Tests(1) {
    my ($self) = @_;

    my $host = t::Net::ACME::MockService::_HOST();

    my $challenge = Net::ACME::Challenge::Pending::http_01->new(
        uri   => "https://$host/challenge/0",
        token => 'the_challenge_token',
    );

    $self->_with_mocked_http_request(
        _ACME_KEY(),
        {
            'get:directory' => sub { return $self->_server_send_directory() },
            'post:challenge/0' => sub {
                return (202 => 'Accepted');
            },
        },
        sub {
            my $acme = _get_acme();
            $acme->do_challenge($challenge);
        },
    );

    my @requests = $self->_get_rest_calls(_ACME_KEY());

    cmp_deeply(
        \@requests,
        [
            ignore(),    #directory
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => '/challenge/0',
                    }
                ),
                POST => [
                    ignore(),    #header
                    {
                        resource         => 'challenge',
                        keyAuthorization => re(qr<\Athe_challenge_token\.[0-9a-zA-Z_-]+\z>),
                    },
                ],
            },
        ],
        'payload sent to server',
    ) or diag explain \@requests;

    return;
}

sub test_delete_authz : Tests(1) {
    my ($self) = @_;

    my $host = t::Net::ACME::MockService::_HOST();

    my $authz = Net::ACME::Authorization::Pending->new(
        uri        => "https://$host/my_authz",
        challenges => [
            Net::ACME::Challenge::Pending->new(
                token => 'thetoken',
                uri   => 'http://does/not/matter',
            ),
        ],
    );

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);

    $self->_with_mocked_http_request(
        _ACME_KEY(),
        {
            'get:directory' => sub { return $self->_server_send_directory() },
            'post:my_authz'  => sub {
                my ( $header, $payload ) = @_;

                $self->_dump_file_json( "$tempdir/received", $payload );

                return( 200 => 'OK' );
            },
        },
        sub {
            my $acme = _get_acme();

            $acme->delete_authz($authz);
        },
    );

    is_deeply(
        $self->_load_file_json("$tempdir/received"),
        {
            delete   => JSON::true(),
            resource => 'authz',
        },
        'correct payload sent to authz endpoint',
    );

    return;
}

sub test_start_domain_authz : Tests(3) {
    my ($self) = @_;

    my $domain_name = 'thedomain.tld';

    my @challenges = (
        {
            type  => 'weird-01',
            uri   => 'https://doesnt/matter',
            token => 'weird_token',
        },
        {
            type  => 'http-01',
            uri   => 'https://http/challenge',
            token => 'http_challenge_token',
        },
    );

    my @combinations = ( [0], [1] );

    my $mock_new_authz_cr = sub {
        my ( $header, $payload ) = @_;

        my $domain = $payload->{'identifier'}{'value'};

        return(
            201 => 'Created',
            {
                Location => 'https://authz/' . rand,
            },
            {
                status       => 'pending',
                identifier   => $payload->{'identifier'},
                challenges   => \@challenges,
                combinations => \@combinations,
            },
        );
    };

    $self->_with_mocked_http_request(
        _ACME_KEY(),
        {
            'get:directory'                  => sub { return $self->_server_send_directory() },
            'post:mock-acme/mock-new-authz' => $mock_new_authz_cr,
        },
        sub {
            my $acme = _get_acme();

            my $authz = $acme->start_domain_authz($domain_name);

            isa_ok( $authz, 'Net::ACME::Authorization::Pending', 'return object' );
            cmp_deeply(
                [ $authz->combinations() ],
                [
                    [ isa('Net::ACME::Challenge::Pending') ],
                    [ isa('Net::ACME::Challenge::Pending::http_01') ],
                ],
                'return of start_domain_authz()',
            ) or diag explain [ $authz->combinations() ];
        },
    );

    my @requests = $self->_get_rest_calls(_ACME_KEY());

    cmp_deeply(
        \@requests,
        [
            ignore(),    #directory
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => '/mock-acme/mock-new-authz',
                    }
                ),
                POST => [
                    ignore(),    #header
                    {
                        resource   => 'new-authz',
                        identifier => {
                            type  => 'dns',
                            value => $domain_name,
                        },
                    },
                ],
            },
        ],
    ) or diag explain \@requests;

    return;
}

sub test_registration : Tests(2) {
    my ($self) = @_;

    my $terms = 'http://cp-terms';

    $self->_do_acme_server(
        _ACME_KEY(),
        sub {
            my $acme = _get_acme();

            my $reg = $acme->register('mailto:f@g.tld');

            my %methods = (
                uri       => re(qr</reg/>),
                agreement => undef,
            );

            cmp_deeply(
                $reg,
                methods(
                    %methods,
                    terms_of_service => $terms,
                ),
                'object return from register()',
            );

            $acme->accept_tos($reg->uri(), $terms);
        },
    );

    my @requests = $self->_get_rest_calls(_ACME_KEY());

    cmp_deeply(
        \@requests,
        [
            {
                ENV => superhashof(
                    {
                        REQUEST_URI    => '/directory',
                        REQUEST_METHOD => 'GET',
                        HTTPS          => 'on',
                    },
                ),
                POST => ignore(),
            },
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => '/mock-acme/mock-new-reg',
                    }
                ),
                POST => [
                    ignore(),
                    {
                        resource => 'new-reg',
                        contact  => ['mailto:f@g.tld'],
                    },
                ],
            },
            {
                ENV => superhashof(
                    {
                        REQUEST_URI => re(qr<\A/reg/.+>),
                    }
                ),
                POST => [
                    ignore(),
                    {
                        resource  => 'reg',
                        agreement => $terms,
                    },
                ],
            },
        ],
        'requests to the server',
    );

    return;
}

sub _reset : Tests(setup) {
    my ($self) = @_;

    $self->{'_client_registrations_dir'} = File::Temp::tempdir(CLEANUP => 1);

    $self->{'_registrations_dir'} = File::Temp::tempdir(CLEANUP => 1);

    return;
}

sub runtests {
    my ( $self, @args ) = @_;

    my $scratch_dir = File::Temp::tempdir(CLEANUP => 1);

    local $self->{'_nonce_path'};
    local $self->{'_rest_calls_file'};

    return $self->SUPER::runtests(@args);
}



1;
