#!/usr/local/cpanel/3rdparty/bin/perl -w
package t::Net::ACME::Certificate::Pending;

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

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::ACME ();

use Net::ACME::Certificate::Pending ();

use Net::ACME::HTTP::Response ();

#for overriding
use Net::ACME::HTTP ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_new : Tests(4) {
    my ($self) = @_;

    my $class = 'Net::ACME::Certificate::Pending';

    my $pcert = $class->new( uri => 'http://where/to' );
    is(
        $pcert->is_time_to_poll(),
        1,
        'if no “retry-after” header, is_time_to_poll() is true',
    );

    is( $pcert->uri(), 'http://where/to', 'uri() method' );

    $pcert = $class->new(
        uri         => 'http://where/to',
        retry_after => 9999999,             #if this breaks, we have issues!
    );

    is(
        $pcert->is_time_to_poll(),
        0,
        'if “retry-after” header indicates way into the future, is_time_to_poll() is false',
    );

    $pcert = $class->new(
        uri         => 'http://where/to',
        retry_after => 1,                   #if this breaks, we have issues!
    );

    sleep 2;

    is(
        $pcert->is_time_to_poll(),
        1,
        'if “retry-after” header indicates a bit of time, is_time_to_poll() is true after that time',
    );

    return;
}

sub test_poll : Tests(4) {
    my ($self) = @_;

    my $class = 'Net::ACME::Certificate::Pending';

    my $pcert = $class->new( uri => 'http://where/to' );

    Test::ACME::test_poll_response($pcert);

    my $get_todo_cr;

    no warnings 'redefine';
    local *Net::ACME::HTTP::get = sub {
        my ( undef, $url ) = @_;
        die "unknown url: “$url”" if $url ne 'http://where/to';

        $get_todo_cr->();
    };

    #----------------------------------------------------------------------

    $get_todo_cr = sub {
        return Net::ACME::HTTP::Response->new(
            {
                status  => 201,
                content => _LE_CERT(),
                headers => {
                    'content-type' => 'application/pkix-cert',
                    link           => ['<http://issuer/cert>;rel="up"'],
                },
            },
        );
    };

    isa_ok(
        $pcert->poll(),
        'Net::ACME::Certificate',
        'poll() return when there’s a new certificate',
    );

    return;
}

sub _LE_CERT {
    return Crypt::Format::pem2der(<<END);
-----BEGIN CERTIFICATE-----
MIIFETCCA/mgAwIBAgITAPquR6j7Ldkgff9DUWmrbnSc3zANBgkqhkiG9w0BAQsFADAiMSAwHgYD
VQQDDBdGYWtlIExFIEludGVybWVkaWF0ZSBYMTAeFw0xNjA0MjUxOTE4MDBaFw0xNjA3MjQxOTE4
MDBaMC8xLTArBgNVBAUTJGZhYWU0N2E4ZmIyZGQ5MjA3ZGZmNDM1MTY5YWI2ZTc0OWNkZjCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMBNCgbhnskPD3stiC0myIpLTyOB3XExSYPyWwGM
z/+IHYkr8bnJjYu5dYCkXiXoxeeUwUVhZ61zZNo9rYSb+ycDPihLGKiOurQpjsdD92K8Je5CwRme
JHcUMZZr/dUX9L6aLk557ivn+PSatmuj2qjdJEyNcPBz38/krH4pxitEWvHeBrq693sFirrCXTW6
Q8WvHQWQy9Qh3mIB0owJweNDgArYeQecFqJMbLfGrJ/0N9GnK3bLPJxpL0/zJai4a5yvj66OSw2j
dG3Hr5o5h7hLH23MS2pDjiVhPLz8c3PMwO4RkON46wwXzlN/rTJKNNxVH7KeUY1Vvo3FhUK9qHkC
AwEAAaOCAjEwggItMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUH
AwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQULXIimILCGT7ysTeB+Ik1r7IY/5gwHwYDVR0jBBgw
FoAUwMwDRrlYIMxccnDz4S7LIKb1aDoweAYIKwYBBQUHAQEEbDBqMDMGCCsGAQUFBzABhidodHRw
Oi8vb2NzcC5zdGctaW50LXgxLmxldHNlbmNyeXB0Lm9yZy8wMwYIKwYBBQUHMAKGJ2h0dHA6Ly9j
ZXJ0LnN0Zy1pbnQteDEubGV0c2VuY3J5cHQub3JnLzAzBgNVHREELDAqghFjcGFuZWxzc2x0ZXN0
Lm9yZ4IVd3d3LmNwYW5lbHNzbHRlc3Qub3JnMIH+BgNVHSAEgfYwgfMwCAYGZ4EMAQIBMIHmBgsr
BgEEAYLfEwEBATCB1jAmBggrBgEFBQcCARYaaHR0cDovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwgasG
CCsGAQUFBwICMIGeDIGbVGhpcyBDZXJ0aWZpY2F0ZSBtYXkgb25seSBiZSByZWxpZWQgdXBvbiBi
eSBSZWx5aW5nIFBhcnRpZXMgYW5kIG9ubHkgaW4gYWNjb3JkYW5jZSB3aXRoIHRoZSBDZXJ0aWZp
Y2F0ZSBQb2xpY3kgZm91bmQgYXQgaHR0cHM6Ly9sZXRzZW5jcnlwdC5vcmcvcmVwb3NpdG9yeS8w
DQYJKoZIhvcNAQELBQADggEBAKerrTO9mif5MH6guvOv8LS+ubugcGFyT9ri+BtHfe6sc+QHMzkJ
DnU3N2CSSVSxkWrDpSbsq+cULzDe2L7p/stjTVSVy8v4ijZxfqQYU6k8FSvCj57MSj7r+cKqjzmF
wK4t1E1L9tb8xJyu8Qmllnl3nPI+n7mTvE54AZEy3833tcHAD9h0uXSTr5QIR8deftwGDDE+Oqu3
9E8/nE+/6hw+p3bw1pFKu0dDtkmdIArYr56k/NQoRWHcoB3Mf/TgQsnMTQRq7V0zET7Q2E4tFdlK
mnAi87MzfIlUEexQTtq9b6hE+J1iX340MpULfyG3kNDM14VmvxnqXDF2QxOl7YI=
-----END CERTIFICATE-----
END
}

1;
