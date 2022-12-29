#!perl

use strict;
use warnings;

use Socket;

use Net::mbedTLS;

use Test::More;
use Test::FailWarnings;

use IO::Socket::UNIX;

my $mbedtls = Net::mbedTLS->new();

my ($cln, $srv);

eval { ($cln, $srv) = IO::Socket::UNIX->socketpair(AF_UNIX, SOCK_STREAM, 0) } or do {
    my $err = $@;
    plan skip_all => "socketpair failed: $err";
};

$_->blocking(0) for ($cln, $srv);

$_ = q<> for my ($cln_mask, $srv_mask);

vec( $cln_mask, fileno($cln), 1 ) = 1;
vec( $srv_mask, fileno($srv), 1 ) = 1;

my $tls_cln = $mbedtls->create_client(
    $cln,
    authmode => Net::mbedTLS::SSL_VERIFY_NONE,
);
my $tls_srv = $mbedtls->create_server($srv,
    key_and_certs => [_PEM()],
);

my $payload = join( q<>, map { rand } 1 .. 10000 );

my $client_send_idx = 0;

my $server_recv = "\0" x length $payload;
my $server_recv_idx = 0;

while ($server_recv_idx < length $payload) {

    if ($client_send_idx < length $payload) {
        my $wrote = $tls_cln->write(substr($payload, $client_send_idx));

        if ($wrote) {
            $client_send_idx += $wrote;
        }
    }

    my $got = $tls_srv->read( substr($server_recv, $server_recv_idx) );
    if ($got) {
        $server_recv_idx += $got;
    }
}

is($server_recv, $payload, 'sent payload');

done_testing;

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
