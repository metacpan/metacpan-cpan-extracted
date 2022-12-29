#!perl

use strict;
use warnings;

use blib;
use lib './lib';

use Net::mbedTLS;

use Socket;

use Benchmark;

use Net::SSLeay;
$Net::SSLeay::trace = 3;

Net::SSLeay::initialize();

use File::Temp;
my ($fh, $pem_path) = File::Temp::tempfile( CLEANUP => 1 );
print {$fh} _PEM();
close $fh;

my $mbedtls = Net::mbedTLS->new();

# pre-load trust store:
$mbedtls->create_client(\*STDOUT);

printf Net::SSLeay::SSLeay_version() . $/;
printf "mbedTLS %s$/", Net::mbedTLS::mbedtls_version_get_string();

my $cln_ctx = Net::SSLeay::CTX_new() or die "ERROR: CTX_new failed";
Net::SSLeay::CTX_load_verify_locations($cln_ctx, Mozilla::CA::SSL_ca_file(), q<>);

Benchmark::cmpthese(
    -1,
    {
        openssl => sub {
            my ($cln, $srv);

            my $srv_ctx = Net::SSLeay::CTX_new() or die "ERROR: CTX_new failed";
            Net::SSLeay::set_cert_and_key($srv_ctx, $pem_path, $pem_path);


            socketpair $cln, $srv, AF_UNIX, SOCK_STREAM, 0;

            $_->blocking(0) for ($cln, $srv);

            my $cln_ssl = Net::SSLeay::new($cln_ctx) or die "ERROR: new failed";
            Net::SSLeay::set_fd($cln_ssl, fileno $cln);

            my $srv_ssl = Net::SSLeay::new($srv_ctx) or die "ERROR: new failed";
            Net::SSLeay::set_fd($srv_ssl, fileno $srv);

            my ($c_ok, $s_ok, $err);

            for (1 .. 10) {
                return if Net::SSLeay::connect($cln_ssl);
                return if Net::SSLeay::accept($srv_ssl);
#                Net::SSLeay::connect($cln_ssl) and do {
#                    my $ses = Net::SSLeay::get_session($cln_ssl);
#                    Net::SSLeay::SESSION_print_fp(\*STDOUT,$ses);
#                };
#                Net::SSLeay::accept($srv_ssl) and do {
#                    my $ses = Net::SSLeay::get_session($srv_ssl);
#                    Net::SSLeay::SESSION_print_fp(\*STDOUT,$ses);
#                };
            }

            warn "OpenSSL failed handshake";
        },

        mbedtls => sub {
            my ($cln_skt, $srv_skt);

            socketpair $cln_skt, $srv_skt, AF_UNIX, SOCK_STREAM, 0;

            $_->blocking(0) for ($cln_skt, $srv_skt);

            my $cln = $mbedtls->create_client(
                $cln_skt,
                authmode => Net::mbedTLS::SSL_VERIFY_NONE,
            );
            my $srv = $mbedtls->create_server(
                $srv_skt,
                key_and_certs => [_PEM()],
            );

            for (1 .. 10) {
                return if $cln->shake_hands();
                return if $srv->shake_hands();
#                $cln->shake_hands() and do {
#                    print $cln->ciphersuite() . $/;
#                    return;
#                };
#                $srv->shake_hands() and do {
#                    print $srv->ciphersuite() . $/;
#                    return;
#                };
            }

            warn "mbedTLS failed handshake";
        },
    },
);

#----------------------------------------------------------------------

sub _PEM {
return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyICViCXD7URjeFzt5ts7/ik8tr9WYzGFXWQ7Xc8o3huYHFpC
KUPbfdeW4nxLuocTOiPAVeauS5rqkzGJFY+ijfZQj7c/iOJkCFZbpVX9Mk9aB5He
xIVk5FdnY1QyMO3n5ENl6pcz8swolEv7gXcHHcGd98h4sblJsLocdq06dzlY8Ls2
mB5OHYz2RUeZ4zL4kytQUw9xlQvwxJDp/Q+x1zrrZ7fmY8YfehO+oDYAtL6/mdOB
hFxpegiczlxP1QuO71wLxDXPrV4wJcopKgOVaKWRnNSZTiBbqlGNUzzQ5mYOj235
5eHS5/mF/On0+m1PuJlW9sA7fVKXdr0EKBql1wIDAQABAoIBACoZncxNqbsrTfua
/7UmuY0fmYkB2iDP6CH5BuImun0QrDrf1N6XSgI9f4gk8z3CWQ4vLZab7mMfrzui
/hbR5x8J5laW8rdKWhjKEUpBKP4kXVITlgQLwmiT1bismDFf8v4iDMdaYmUL60Vg
QvonRQ5Bdmrt5DHlJwz9tzZQH2Oi/tfantEfWSU+zeIK0Kx2B7MOBJuHT4XHTQ2R
AQDXbCFluA9yBxv7hCW3WboIaOgKS6Y5BJOc3mUVg2ZInhBxT2wRF/6slLheccOi
6YCsU5y18eb9imG3Jqot2pHzZ2b1uQ1KlvH4/bcWFj7x7dpRSK3FW4n1FjIVZ2DX
9IjxgqECgYEA58JMP1ZfUCV/CEOiTbLGj6IXeS12uH02vXXlzpV6ynmtLABx0cPw
X+ZO1tin2F73uElislgq1NT2uibl9LRGT5P3fCaGb+i/B8WIckAfaqE24tKuKas/
2sRGJRGsRgKYz0VJsH1LLMsCGM0NIe711UcdwIc0PPbTysnFPtAFrMcCgYEA3XlX
H17NJOnJX8l86kZcvjL1AJ8+vOe1mLdiovhAaHnHF9cnALM1PJZKOhxPNIMJGDvM
FK5yGMQtIVUa7tGINmuft+V7qw55R2ehLx4FWZ8XDMGQ1wwWWl1zEcqnHtEHWFkW
PKLfsPUac0nK1rlBlaitlmlI1V8oIwJLhBEljnECgYAqvzPBGvVJmyDrLU5qdmcZ
ZxRdTX1wWegW2gAhMoELh5XhX9OelT1o8tnn1t5ekmWuoBqMOqbryrwXacVQdU/i
rbAgPhrd2Vgi3tRj/l/NEx9EhweIuAV3HGyzuabE4wW8dVM6MmIDSQ6B9JBPifvd
8tgSAt4nwH8gEEdJZqUlUQKBgCJ1n8WkxXyJ16hMvF/jRMjfOtm27VcNImc5mWJM
CBF5aS3fbxUfzRe5NqFmCDjeborTuwQ4xE3wMClwiXlBJtV412gQj7Zk0R/4Es82
95QjOb3lXDjpi4zR33aUNn6H/YGUku4qVW2+JThs8d+JAZhcn224wflZDfCsib1p
wZMxAoGBANAzIpRqXav3HgEFZe9Ale2gG9KL+7QHkRigE1SllzD/oXS/r3qHuVEm
33d/PWkT7lDbszN+/Bn+W7lWT9njUjgNaht6FuchZR2XG5QuDPoC8ptPp9vWQvCV
tN8zUXQogsM1gMOrtgSZE23HyDczPiPD7l05DwO8TVs1ljDqwbem
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDQDCCAiigAwIBAgIUDnbJbiaTMiGRr/V7V/GIRUqx0QIwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLZXhhbXBsZS5jb20wHhcNMjExMjA4MTkyODAwWhcNMjIw
MTA3MTkyODAwWjAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMiAlYglw+1EY3hc7ebbO/4pPLa/VmMxhV1kO13P
KN4bmBxaQilD233XluJ8S7qHEzojwFXmrkua6pMxiRWPoo32UI+3P4jiZAhWW6VV
/TJPWgeR3sSFZORXZ2NUMjDt5+RDZeqXM/LMKJRL+4F3Bx3BnffIeLG5SbC6HHat
Onc5WPC7NpgeTh2M9kVHmeMy+JMrUFMPcZUL8MSQ6f0Psdc662e35mPGH3oTvqA2
ALS+v5nTgYRcaXoInM5cT9ULju9cC8Q1z61eMCXKKSoDlWilkZzUmU4gW6pRjVM8
0OZmDo9t+eXh0uf5hfzp9PptT7iZVvbAO31Sl3a9BCgapdcCAwEAAaOBhTCBgjAd
BgNVHQ4EFgQUMa0XpJoPhz4uPemW+Z5rC7AW23gwHwYDVR0jBBgwFoAUMa0XpJoP
hz4uPemW+Z5rC7AW23gwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAkG
A1UdEwQCMAAwFgYDVR0RBA8wDYILZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQAD
ggEBAAtVrWa958naBMW7ye7DsMIQPgZPkzOir0VWqBiPY7LbhTAtM1sz7vjvN3cH
RRnfMoq6J+l6iS0wDE18xzx6/4dEbaIHFMoVwnImdu1J743AxCLzFIo+LiBlK5Ma
LmYOFjSXmG5r4EvpXIBuun8dR5vjzgayw2DYbGMqdpScHeSkfKEvkANxDFP7zLtF
oPRYr2Kh0miQuDjzU4IapqNHhtadljZSIde/+s5qRIwHghWFKcQ0ZTFj9YABF/VD
L/lPB0eRYggFx+myXM1i453a81MfxscrcWV5pZhg2p9pP+9QDrLTLed6N4YDxPdt
V0VbGJShoyq+IgahwBMP393UIUE=
-----END CERTIFICATE-----
END
}

1;
