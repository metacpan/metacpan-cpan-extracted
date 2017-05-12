use strict;
use warnings;

use Test::Spec;
use IO::Socket::INET;
use LWP::UserAgent;
use File::Temp;

my @paths =
  ($ENV{NGINX_PATH} || '', '/usr/sbin/nginx', '/usr/local/bin/nginx');

my $nginx_bin;
foreach my $path (@paths) {
    if (-x $path) {
        $nginx_bin = $path;
        last;
    }
}

unless ($nginx_bin) {
    plan skip_all => 'Nginx not found, set $NGINX_PATH';
}
else {
    use_ok 'Nginx::Runner';
}

describe 'Nginx::Runner' => sub {
    it "should proxy http request" => sub {
        my $nginx = new_ok 'Nginx::Runner', [nginx_bin => $nginx_bin];

        my $port_dst = &fork_simple_http_client;
        my $port_src = &gen_port;

        $nginx->proxy("127.0.0.1:$port_src" => "127.0.0.1:$port_dst")->run;

        my $response = LWP::UserAgent->new->get("http://127.0.0.1:$port_src");

        ok $response->is_success, 'request is success';
        is $response->decoded_content, "ok", 'content is right';

        $nginx->stop;
    };

    it "should proxy https requests" => sub {
        my $nginx = new_ok 'Nginx::Runner', [nginx_bin => $nginx_bin];

        my $port_dst = &fork_simple_http_client;

        my $port_src = &gen_port;

        my ($pem_fh, $pem_fn) = &create_pem;

        $nginx->proxy(
            "https://127.0.0.1:$port_src" => "127.0.0.1:$port_dst",
            [ssl_certificate => $pem_fn], [ssl_certificate_key => $pem_fn]
        )->run;

        my $response =
          LWP::UserAgent->new(ssl_opts => {verify_hostname => 0})
          ->get("https://127.0.0.1:$port_src");

        ok $response->is_success, 'request is success';
        is $response->decoded_content, "ok", 'content is right';
    };
};

runtests if !caller && $nginx_bin;

sub gen_port {
    my $socket = IO::Socket::INET->new(LocalAddr => '127.0.0.1');
    $socket->sockport;
}

sub fork_simple_http_client {
    my $port_dst = &gen_port;

    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port_dst,
        Listen    => 1,
    );

    return $port_dst if (fork);

    alarm 1;

    simple_http_client($socket->accept);
    exit 0;
}

sub simple_http_client {
    my $client = shift;

    while ($client->recv(my $data, 1024)) { }

    $client->send(<<"HTTP");
HTTP/1.0 200 OK\r
Date: Fri, 20 Jan 2012 13:44:14 GMT\r
Content-Type: text/plain\r
Content-Length: 2\r
\r
HTTP
    $client->send("ok");

    $client->close;
}

sub create_pem {
    my $pem = do {
        local $/;
        <DATA>;
    };

    my ($pem_fh, $pem_filename) =
      File::Temp::tempfile(SUFFIX => '.pem', UNLINK => 1);

    print $pem_fh $pem;
    $pem_fh->close;

    ($pem_fh, $pem_filename);
}

__END__
-----BEGIN CERTIFICATE-----
MIICKTCCAZICCQDFxHnOjdmTTjANBgkqhkiG9w0BAQUFADBZMQswCQYDVQQGEwJB
VTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0
cyBQdHkgTHRkMRIwEAYDVQQDDAlsb2NhbGhvc3QwHhcNMTIwMTE0MTgzMjMwWhcN
NzUxMTE0MTIwNDE0WjBZMQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0
ZTEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMRIwEAYDVQQDDAls
b2NhbGhvc3QwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAKLGfQantHdi/0cd
eoOHRbWKChpI/g84hU8SnwmrSMZR0x76vDLKMDYohISoKxRPx6j2M2x3P4K+kEJm
C5H9iGdD9p9ljGnRdkGp5yYeuwWfePRb4AOwP5qgQtEb0OctFIMjcAIIAw/lsnUs
hGnom0+uA9W2H63PgO0o4qiVAn7NAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEATDGA
dYRl5wpsYcpLgNzu0M4SENV0DAE2wNTZ4LIR1wxHbcxdgzMhjp0wwfVQBTJFNqWu
DbeIFt4ghPMsUQKmMc4+og2Zyll8qev8oNgWQneKjDAEKKpzdvUoRZyGx1ZocGzi
S4LDiMd4qhD+GGePcHwmR8x/okoq58xZO/+Qygc=
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCixn0Gp7R3Yv9HHXqDh0W1igoaSP4POIVPEp8Jq0jGUdMe+rwy
yjA2KISEqCsUT8eo9jNsdz+CvpBCZguR/YhnQ/afZYxp0XZBqecmHrsFn3j0W+AD
sD+aoELRG9DnLRSDI3ACCAMP5bJ1LIRp6JtPrgPVth+tz4DtKOKolQJ+zQIDAQAB
AoGASXDmvhbyfJ8k8HAjc66XzBWxAzUFs9Zbh1aufM1UM259o8+bFAtXf0f+ql+5
uBtaySf0Aa8374SNT/f8pmzOmpiXMvYRz8Z5Gc6JYpYd/PrCoSCGtP+NdCvk7Y5c
eUmmpiEto4+fgCAKrtqc5jm8eBWn/yNhQNDBVJ9qX+kXQOECQQDVBLvBZaECSMTm
djKuPlZ93cmyI7g+TURTl2N08fz4xQVVbo5+AV0GsEZupBpTgrHpLTk8gKP/nfdR
9KWZldbZAkEAw55+SqrVTv4cI0fMvC0t8Wl46zTkY9tK65TGnbO1DbTQh9qs+NwH
+v3uu47ef5w/73xLtDjQouz//0z5rgF3FQJAfrmOKQOYwY8g9CmlBNu5ALAM6Zku
ZoH4//G0DUJYyHYNMkHPK08MVIpRnEisELpTtPBeeIvfBJapJ2xvh+sIIQJASeY4
I5EB4EOS8akQKQ6QSqDjs0dZ+HdBiFm95pmbDkB+frQXoDPPN/xyEZzZZS/r31b/
amgEOWh7FUFJGXkoOQJBALfOgsiss0lASlOXAg1rwO4m2OaDiaEde01PLcSjIaKl
Qfbzc7ZYF+fGDsHHlD5Kgj1CGaWCVVHqCv4UHSrA/gM=
-----END RSA PRIVATE KEY-----
