package t::Net::ACME::Certificate;

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

use Crypt::Format ();

use Net::ACME::Certificate ();

#for overriding
use Net::ACME::HTTP ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

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

sub _ISSUER_CERT {
    return Crypt::Format::pem2der(<<END);
-----BEGIN CERTIFICATE-----
MIIDzzCCAregAwIBAgIDAWweMA0GCSqGSIb3DQEBBQUAMIGNMQswCQYDVQQGEwJB
VDFIMEYGA1UECgw/QS1UcnVzdCBHZXMuIGYuIFNpY2hlcmhlaXRzc3lzdGVtZSBp
bSBlbGVrdHIuIERhdGVudmVya2VociBHbWJIMRkwFwYDVQQLDBBBLVRydXN0LW5R
dWFsLTAzMRkwFwYDVQQDDBBBLVRydXN0LW5RdWFsLTAzMB4XDTA1MDgxNzIyMDAw
MFoXDTE1MDgxNzIyMDAwMFowgY0xCzAJBgNVBAYTAkFUMUgwRgYDVQQKDD9BLVRy
dXN0IEdlcy4gZi4gU2ljaGVyaGVpdHNzeXN0ZW1lIGltIGVsZWt0ci4gRGF0ZW52
ZXJrZWhyIEdtYkgxGTAXBgNVBAsMEEEtVHJ1c3QtblF1YWwtMDMxGTAXBgNVBAMM
EEEtVHJ1c3QtblF1YWwtMDMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQCtPWFuA/OQO8BBC4SAzewqo51ru27CQoT3URThoKgtUaNR8t4j8DRE/5TrzAUj
lUC5B3ilJfYKvUWG6Nm9wASOhURh73+nyfrBJcyFLGM/BWBzSQXgYHiVEEvc+RFZ
znF/QJuKqiTfC0Li21a8StKlDJu3Qz7dg9MmEALP6iPESU7l0+m0iKsMrmKS1GWH
2WrX9IWf5DMiJaXlyDO6w8dB3F/GaswADm0yqLaHNgBid5seHzTLkDx4iHQF63n1
k3Flyp3HaxgtPVxO59X4PzF9j4fsCiIvI+n+u33J4PTs63zEsMMtYrWacdaxaujs
2e3Vcuy+VwHOBVWf3tFgiBCzAgMBAAGjNjA0MA8GA1UdEwEB/wQFMAMBAf8wEQYD
VR0OBAoECERqlWdVeRFPMA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQUFAAOC
AQEAVdRU0VlIXLOThaq/Yy/kgM40ozRiPvbY7meIMQQDbwvUB/tOdQ/TLtPAF8fG
KOwGDREkDg6lXb+MshOWcdzUzg4NCmgybLlBMRmrsQd7TZjTXLDR8KdCoLXEjq/+
8T/0709GAHbrAvv5ndJAlseIOrifEXnzgGWovR/TeIGgUUw3tKZdJXDRZslo+S4R
FGjxVJgIrCaSD96JntT6s3kr0qN51OyLrIdTaEJMUVF0HhsnLuP1Hyl0Te2v9+GS
mYHovjrHF1D2t8b8m7CKa9aIA5GPBnc6hQLdmNVDeD/GMBWsm2vLV7eJUYs66MmE
DNuxUCAKGkq6ahq97BvIxYSazQ==
-----END CERTIFICATE-----
END
}

sub _ISSUER_CERT2 {
    return Crypt::Format::pem2der(<<END);
-----BEGIN CERTIFICATE-----
MIIPJjCCDg6gAwIBAgISA3W6nZsNQ7GmFEW/vpHLUwWiMA0GCSqGSIb3DQEBCwUA
MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xNjA1MjEwMDA3MDBaFw0x
NjA4MTkwMDA3MDBaMBsxGTAXBgNVBAMTEGFmcm9nLmtvc3Rvbi5vcmcwggEiMA0G
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0Lt3HM6A2JruHMBjSafpezZoSZwLB
A4vzPuUXtpRmkYx8NMaMI+I383rhRLlpjwp52Z29ThmnIwTIt/zPF1gVbF5Qo5Dt
Bg7zPPEXAKYMMNYx2OxZFLgaDX5rdFlGE64xnOwumTZ4zhNlgicVu4NDH3eYz7RS
VQq8L1hgiJqtpswR+9G9a9DQTqYCopMgCUVMfCqlugphl4kDi9b4N3O/v3DIq7Kb
umchmN+IDuEtU2dZwq+fZvFuaukFZElPmaN/Myq5Cs7P+M6sgovdV30Tb1M4NltB
RQfWoRdKKdT2uRE6vQFOfF0GTR6ss3tsdvczjznKljiu1pg57dtoPkt1AgMBAAGj
ggwzMIIMLzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
AQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFHVTc1nGyZET/hEgf97SLxcS
QHDHMB8GA1UdIwQYMBaAFKhKamMEfd265tE5t6ZFZe/zqOyhMHAGCCsGAQUFBwEB
BGQwYjAvBggrBgEFBQcwAYYjaHR0cDovL29jc3AuaW50LXgzLmxldHNlbmNyeXB0
Lm9yZy8wLwYIKwYBBQUHMAKGI2h0dHA6Ly9jZXJ0LmludC14My5sZXRzZW5jcnlw
dC5vcmcvMIIKOwYDVR0RBIIKMjCCCi6CEGFmcm9nLmtvc3Rvbi5vcmeCFWJsaW5n
Ymxpbmcua29zdG9uLm9yZ4IcZG9tYWlucy1wZXItY2VydDEua29zdG9uLm9yZ4Id
ZG9tYWlucy1wZXItY2VydDEwLmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQx
MS5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0MTIua29zdG9uLm9yZ4IdZG9t
YWlucy1wZXItY2VydDEzLmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQxNC5r
b3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0MTUua29zdG9uLm9yZ4IdZG9tYWlu
cy1wZXItY2VydDE2Lmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQxNy5rb3N0
b24ub3Jngh1kb21haW5zLXBlci1jZXJ0MTgua29zdG9uLm9yZ4IdZG9tYWlucy1w
ZXItY2VydDE5Lmtvc3Rvbi5vcmeCHGRvbWFpbnMtcGVyLWNlcnQyLmtvc3Rvbi5v
cmeCHWRvbWFpbnMtcGVyLWNlcnQyMC5rb3N0b24ub3Jngh1kb21haW5zLXBlci1j
ZXJ0MjEua29zdG9uLm9yZ4IdZG9tYWlucy1wZXItY2VydDIyLmtvc3Rvbi5vcmeC
HWRvbWFpbnMtcGVyLWNlcnQyMy5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0
MjQua29zdG9uLm9yZ4IdZG9tYWlucy1wZXItY2VydDI1Lmtvc3Rvbi5vcmeCHWRv
bWFpbnMtcGVyLWNlcnQyNi5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0Mjcu
a29zdG9uLm9yZ4IdZG9tYWlucy1wZXItY2VydDI4Lmtvc3Rvbi5vcmeCHWRvbWFp
bnMtcGVyLWNlcnQyOS5rb3N0b24ub3Jnghxkb21haW5zLXBlci1jZXJ0My5rb3N0
b24ub3Jngh1kb21haW5zLXBlci1jZXJ0MzAua29zdG9uLm9yZ4IdZG9tYWlucy1w
ZXItY2VydDMxLmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQzMi5rb3N0b24u
b3Jngh1kb21haW5zLXBlci1jZXJ0MzMua29zdG9uLm9yZ4IdZG9tYWlucy1wZXIt
Y2VydDM0Lmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQzNS5rb3N0b24ub3Jn
gh1kb21haW5zLXBlci1jZXJ0MzYua29zdG9uLm9yZ4IdZG9tYWlucy1wZXItY2Vy
dDM3Lmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVyLWNlcnQzOC5rb3N0b24ub3Jngh1k
b21haW5zLXBlci1jZXJ0Mzkua29zdG9uLm9yZ4IcZG9tYWlucy1wZXItY2VydDQu
a29zdG9uLm9yZ4IdZG9tYWlucy1wZXItY2VydDQwLmtvc3Rvbi5vcmeCHWRvbWFp
bnMtcGVyLWNlcnQ0MS5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0NDIua29z
dG9uLm9yZ4IdZG9tYWlucy1wZXItY2VydDQzLmtvc3Rvbi5vcmeCHWRvbWFpbnMt
cGVyLWNlcnQ0NC5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0NDUua29zdG9u
Lm9yZ4IdZG9tYWlucy1wZXItY2VydDQ2Lmtvc3Rvbi5vcmeCHWRvbWFpbnMtcGVy
LWNlcnQ0Ny5rb3N0b24ub3Jngh1kb21haW5zLXBlci1jZXJ0NDgua29zdG9uLm9y
Z4IdZG9tYWlucy1wZXItY2VydDQ5Lmtvc3Rvbi5vcmeCHGRvbWFpbnMtcGVyLWNl
cnQ1Lmtvc3Rvbi5vcmeCHGRvbWFpbnMtcGVyLWNlcnQ2Lmtvc3Rvbi5vcmeCHGRv
bWFpbnMtcGVyLWNlcnQ3Lmtvc3Rvbi5vcmeCHGRvbWFpbnMtcGVyLWNlcnQ4Lmtv
c3Rvbi5vcmeCHGRvbWFpbnMtcGVyLWNlcnQ5Lmtvc3Rvbi5vcmeCDmRzZC5rb3N0
b24ub3JnghRkc3Nkc2Rhc2Qua29zdG9uLm9yZ4INZmQua29zdG9uLm9yZ4IRaGl0
MTAwLmtvc3Rvbi5vcmeCEWhpdDEwMS5rb3N0b24ub3JnghFoaXQxMDIua29zdG9u
Lm9yZ4IRaGl0MTAzLmtvc3Rvbi5vcmeCEWhpdDEwNC5rb3N0b24ub3JnghFoaXQx
MDUua29zdG9uLm9yZ4IRaGl0MTA2Lmtvc3Rvbi5vcmeCEWhpdDEwNy5rb3N0b24u
b3JnghFoaXQxMDgua29zdG9uLm9yZ4IRaGl0MTA5Lmtvc3Rvbi5vcmeCEWhpdDEx
MC5rb3N0b24ub3JnghFoaXQxMjAua29zdG9uLm9yZ4IRa29zZmFyLmtvc3Rvbi5v
cmeCCmtvc2Zhci5vcmeCCmtvc3Rvbi5vcmeCFGxldGl0cmlkZS5rb3N0b24ub3Jn
ghtsZXRzZW5jcnlwdC10ZXN0Lmtvc3Rvbi5vcmeCF3JlZGlyZWN0dGVzdC5rb3N0
b24ub3JnghhyZWRpcmVjdHRlc3QyLmtvc3Rvbi5vcmeCGHJlZGlyZWN0dGVzdDMu
a29zdG9uLm9yZ4ITcmVtb3RlaXQua29zdG9uLm9yZ4IOd2htLmtvc3Rvbi5vcmeC
F3dpbGRjYXJkc2FmZS5rb3N0b24ub3JnghR3d3cuYWZyb2cua29zdG9uLm9yZ4IY
d3d3LmRzc2RzZGFzZC5rb3N0b24ub3JnghF3d3cuZmQua29zdG9uLm9yZ4IVd3d3
LmhpdDEwMC5rb3N0b24ub3JnghV3d3cuaGl0MTAxLmtvc3Rvbi5vcmeCFXd3dy5o
aXQxMDIua29zdG9uLm9yZ4IVd3d3LmhpdDEwMy5rb3N0b24ub3JnghV3d3cuaGl0
MTA0Lmtvc3Rvbi5vcmeCFXd3dy5oaXQxMDUua29zdG9uLm9yZ4IVd3d3LmhpdDEw
Ni5rb3N0b24ub3JnghV3d3cuaGl0MTA3Lmtvc3Rvbi5vcmeCFXd3dy5oaXQxMDgu
a29zdG9uLm9yZ4IVd3d3LmhpdDEwOS5rb3N0b24ub3JnghV3d3cuaGl0MTEwLmtv
c3Rvbi5vcmeCFXd3dy5oaXQxMjAua29zdG9uLm9yZ4IVd3d3Lmtvc2Zhci5rb3N0
b24ub3Jngg53d3cua29zZmFyLm9yZ4IOd3d3Lmtvc3Rvbi5vcmeCG3d3dy5yZWRp
cmVjdHRlc3Qua29zdG9uLm9yZ4Icd3d3LnJlZGlyZWN0dGVzdDIua29zdG9uLm9y
Z4Icd3d3LnJlZGlyZWN0dGVzdDMua29zdG9uLm9yZ4IXd3d3LnJlbW90ZWl0Lmtv
c3Rvbi5vcmeCG3d3dy53aWxkY2FyZHNhZmUua29zdG9uLm9yZzCB/gYDVR0gBIH2
MIHzMAgGBmeBDAECATCB5gYLKwYBBAGC3xMBAQEwgdYwJgYIKwYBBQUHAgEWGmh0
dHA6Ly9jcHMubGV0c2VuY3J5cHQub3JnMIGrBggrBgEFBQcCAjCBngyBm1RoaXMg
Q2VydGlmaWNhdGUgbWF5IG9ubHkgYmUgcmVsaWVkIHVwb24gYnkgUmVseWluZyBQ
YXJ0aWVzIGFuZCBvbmx5IGluIGFjY29yZGFuY2Ugd2l0aCB0aGUgQ2VydGlmaWNh
dGUgUG9saWN5IGZvdW5kIGF0IGh0dHBzOi8vbGV0c2VuY3J5cHQub3JnL3JlcG9z
aXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQBHBN9E+VTeG9alnmCFTMtQAli4L7iM
MJkzaYerNimdk+S5d2lKKt/kvS/ZOnEp8J15FdxVENu2NmCvvhAKQDw8UwBN58o2
W+Lb+lM4qc27gxhxE3vpRY2a/ZqDjPxTkD70VpWULf+bOnHu/3nBqfNVykSXLVrJ
EJQYFOO4DfkmyzKu/eQszmVgJiWqwXGcRcqoPYf28auQ3lHnMjpl50wnY0ZltASP
Fm+ZZyWVYwJIECuPgADH1Cm4zOYl4WNTWm9SCLspcx0Awwe9UY0BR/krUtx6esAo
/MU04KMJBbbm0cF0dmQAWDj3R9uCPaf3deo+y8czBPHFsRHoTKvUgeLK
-----END CERTIFICATE-----
END
}

sub test_ops : Tests(2) {
    my ($self) = @_;

    my $cert = Net::ACME::Certificate->new(
        content         => _LE_CERT(),
        type            => 'application/pkix-cert',
        issuer_cert_uri => 'http://some/where',
    );

    is(
        Crypt::Format::pem2der( $cert->pem() ),
        _LE_CERT(),
        'pem()',
    );

    no warnings 'redefine';
    local *Net::ACME::HTTP::get = sub {
        my ( $self, $uri ) = @_;

        my $content;
        my $headers_hr = {
            'content-type' => 'application/pkix-cert',
        };

        if ( $uri =~ m<else> ) {
            $content = _ISSUER_CERT2();
        }
        else {
            $headers_hr->{'link'} = '<http://some/where/else>;rel="up"';
            $content = _ISSUER_CERT();
        }

        return Net::ACME::HTTP::Response->new(
            {
                content => $content,
                headers => $headers_hr,
            },
        );
    };

    is_deeply(
        [ map { Crypt::Format::pem2der($_) } $cert->issuers_pem() ],
        [ _ISSUER_CERT(), _ISSUER_CERT2() ],
        'issuers_pem()',
    );

    return;
}

1;
