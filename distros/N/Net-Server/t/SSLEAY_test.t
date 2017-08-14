#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag skip);
my $env = prepare_test({n_tests => 4, start_port => 20200, n_ports => 2}); # runs three of its own tests

if (! eval { require File::Temp }
    || ! eval { require Net::SSLeay }
   ) {
  SKIP: { skip("Cannot load Net::SSleay libraries to test Socket SSL server: $@", 1); };
    exit;
}
if (! eval { require Net::Server::Proto::SSLEAY }) {
    diag "Cannot load SSLEAY library on this platform: $@";
  SKIP: { skip("Skipping tests on this platform", 1); };
    exit;
}

my $pem = << 'PEM'; # this certificate is invalid, please only use for testing
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
PEM

my ($pem_fh, $pem_filename) =
  File::Temp::tempfile(SUFFIX => '.pem', UNLINK => 1);
print $pem_fh $pem;
$pem_fh->close;

require Net::Server;
@Net::Server::Test::ISA = qw(Net::Server);

sub accept {
    my $self = shift;
    exit if $^O eq 'MSWin32' && $self->{'__one_accept_only'}++;
    $env->{'signal_ready_to_test'}->();
    return $self->SUPER::accept(@_);
}

sub process_request {
    my $self = shift;
    my $client = $self->{'server'}->{'client'};
    return $self->SUPER::process_request if $client->NS_port == $env->{'ports'}->[1];
    my $offset = 0;
    my $total = 0;
    my $buf;

    # Wait data
    my $vec = '';
    vec($vec, $client->fileno, 1) = 1;

    until ($buf) {
        select($vec, undef, undef, undef);
        $client->sysread(\$buf, 100, $total);
    }

    select(undef, $vec, undef, undef);

    $client->syswrite($buf);

    $self->server_close;
}

my $ok = eval {
    local $SIG{'ALRM'} = sub { die "Timeout\n" };
    alarm $env->{'timeout'};
    my $ppid = $$;
    my $pid = fork;
    die "Trouble forking: $!" if ! defined $pid;

    ### parent does the client
    if ($pid) {
        $env->{'block_until_ready_to_test'}->();

        my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[1]) || die "Couldn't open child to sock: $!";

        my $ctx = Net::SSLeay::CTX_new()
            or Net::SSLeay::die_now("Failed to create SSL_CTX $!");
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
            and Net::SSLeay::die_if_ssl_error("ssl ctx set options");
        my $ssl = Net::SSLeay::new($ctx)
            or Net::SSLeay::die_now("Failed to create SSL $!");
        Net::SSLeay::set_fd($ssl, $remote->fileno);
        Net::SSLeay::connect($ssl);
        my $line = Net::SSLeay::read($ssl);
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        diag $line;
        Net::SSLeay::write($ssl, "quit\n");
        my $line2 = Net::SSLeay::read($ssl);
        diag $line2;


        $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";

        $ctx = Net::SSLeay::CTX_new()
            or Net::SSLeay::die_now("Failed to create SSL_CTX $!");
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
            and Net::SSLeay::die_if_ssl_error("ssl ctx set options");
        $ssl = Net::SSLeay::new($ctx)
            or Net::SSLeay::die_now("Failed to create SSL $!");

        Net::SSLeay::set_fd($ssl, $remote->fileno);
        Net::SSLeay::connect($ssl);

        Net::SSLeay::write($ssl, "foo bar");
        my $res = Net::SSLeay::read($ssl);
        return $res eq "foo bar";

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            close STDERR;
            Net::Server::Test->run(
                host  => $env->{'hostname'},
                port  => $env->{'ports'},
                ipv   => $env->{'ipv'},
                proto => 'ssleay',
                background => 0,
                setsid => 0,
                SSL_cert_file => $pem_filename,
                SSL_key_file  => $pem_filename,
                );
        } || do {
            diag("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || diag("Error: $@");
