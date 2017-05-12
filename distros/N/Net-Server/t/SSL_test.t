#!/usr/bin/perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag skip);
my $env = prepare_test({n_tests => 5, start_port => 20200, n_ports => 1}); # runs three of its own tests

if (! eval { require File::Temp }
    || ! eval { require IO::Socket::SSL }
   ) {
  SKIP: { skip("Cannot load IO::Socket::SSL libraries to test Socket SSL server: $@", 2); };
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

use_ok qw(Net::Server::Proto::SSL) or exit;
require Net::Server;
@Net::Server::Test::ISA = qw(Net::Server);

sub accept {
    my $self = shift;
    exit if $^O eq 'MSWin32' && $self->{'__one_accept_only'}++;
    $env->{'signal_ready_to_test'}->();
    return $self->SUPER::accept(@_);
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

        my $mode = eval { IO::Socket::SSL_VERIFY_NONE() };
        $mode = 0 if ! defined $mode;

        my $remote = IO::Socket::SSL->new(
            PeerAddr => $env->{'hostname'},
            PeerPort => $env->{'ports'}->[0],
            SSL_verify_mode => $mode,
        ) || die "Couldn't open child to sock: $!";

        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        diag $line;
        print $remote "exit\n";
        my $line2 = <$remote>;
        diag $line2;
        return 1;

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            close STDERR;
            my $s = Net::Server::Test->run(
                host  => $env->{'hostname'},
                port  => $env->{'ports'}->[0],
                proto => 'ssl',
                ipv   => '*', # $env->{'ipv'}, # IO::Socket::SSL always tries INET6 if it is available so we should listen on 6 if it is available
                SSL_cert_file => $pem_filename,
                SSL_key_file  => $pem_filename,
                background => 0,
                setsid => 0,
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
