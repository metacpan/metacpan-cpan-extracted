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
MIIDYjCCAkqgAwIBAgIJAP1GPpBIeA7QMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwIBcNMjAwNTI0MDUyMzQwWhgPMjI5NDAzMDgwNTIzNDBa
MEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJ
bnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
ggEKAoIBAQDlVci9G9HPwKYhr0kSFT15FcQ1FDNxcn5aMP41ETieM6HASyPFfZ/H
TnxE1kX3V2fGpaQVpkfrMqAfiGQ0nntXoQDosP3QYO4X0SfYNsWGDa0KKg1xQB9N
8Xe348Gxm9/ncGzuBdYpasohrcBhBQqJvor0FVV9IlIDpBvXjl9FsleKj9vlxdUZ
sgHB01lTi+5cIUQiy2fkHhMt6R9PUXmeBOjEzNe0o3uftdruBSDsMoRAJZ27yDOq
TfpBWhHAF+6PGN0hyVvdePUSX6CeG8CsgzZorHPr5WBzZ1IlRoT3TdFqtZyEfGfV
rND9wdoAiz50CPWXWHlokhlIeBCc2vLPAgMBAAGjUzBRMB0GA1UdDgQWBBTme3pQ
NkZAqxlFzr+TcwCsJ9WJyjAfBgNVHSMEGDAWgBTme3pQNkZAqxlFzr+TcwCsJ9WJ
yjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQDTQ+KNgySd+Kd2
oET16XapSvGvA3OkdcNq481HSvpOIwDQp38z4/IhAPo2IvANeGLhw60fmE2uLW88
ewa+/qIGHu3xVuSv0g+UJ0QZLkdWBiF4cEsu49ZnwfBVUXpzNZNamF1Nk1yAWhQF
+DYxZYklllTdtwo7ImMozSPC0DzEQKF2VBj6Dtig2VDRGArl4iZ6MX8+WGK3C+05
9doZ+2pdqyCZf074Gs7oqjm1T3llvEJBlpxYGSsjcRCkKazBE3IcjSu+6/wkzZLR
ckaRuEQeE7e4IK/c1R8njOygzl07VFnFNprC9M0DVvuYI7ZIFXS+YEedvuxKvyva
GcEBq7Ms
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDlVci9G9HPwKYh
r0kSFT15FcQ1FDNxcn5aMP41ETieM6HASyPFfZ/HTnxE1kX3V2fGpaQVpkfrMqAf
iGQ0nntXoQDosP3QYO4X0SfYNsWGDa0KKg1xQB9N8Xe348Gxm9/ncGzuBdYpasoh
rcBhBQqJvor0FVV9IlIDpBvXjl9FsleKj9vlxdUZsgHB01lTi+5cIUQiy2fkHhMt
6R9PUXmeBOjEzNe0o3uftdruBSDsMoRAJZ27yDOqTfpBWhHAF+6PGN0hyVvdePUS
X6CeG8CsgzZorHPr5WBzZ1IlRoT3TdFqtZyEfGfVrND9wdoAiz50CPWXWHlokhlI
eBCc2vLPAgMBAAECggEBAIOMzqYzhAnQ7zsZSif2SRng83ijCtNDotjni5ozM7AD
2//q2i0Z34I7MitmYiH8YEnhkBrfFBgFJTaRTTGlywi8EUJo7F8QiuLclid/W5SG
2cCf2LAi4RIbtdmk6uGPkUM4CTQL4wpE+IeTHGxKsP3Mb/aNGkm6WyM9ir7+KwZV
rZtNl5wiHRbzwSoMmHT80DKrkrbNr5nkAgd+F2oofAIMwAbex4TQZ5Vi0NTAPGSX
yQ7jOYFnsaAfJymrjTXYGOlP+p/lEFAC27SGEECtI5uCWh731GY5DPNwUb3Qct05
LRORiMxrymKjwNy3uSNkNwUczawWGPaFzCRk9JB85LkCgYEA+yET0GmgIgUd3NaM
ntqwEmeKad1XRxP5652exfrydKunYApbMlcd9GE5UyiqN+C7QhfQEWwGQji008Dc
T+2sKA0EpJIcmNlLjLyP0+anlJlYqAoljvwXMCcifFMV2YpX/AKeF9wmdn94Lawf
rkfM8v/jIHKqid/Yewik40bhsA0CgYEA6ch+Q/QYubL0a4msYZ726cam7YpYbhfi
iTud59KOmtxBczZEd5z5wv6YKbebEHRCpELuZc/ENekXR3gheocW0XuR0GnQifhl
MfhbG9yT+oy8E6ljHPsZi2OVbz6UfxGnjZzkBubU9AYPdcBev4bw5vdk0xLoUMmA
ViqgGqIXG0sCgYEAvXtqwOFBwwmLS7rSpXWqTmizhkdM+EN5Wi82wnkjgaaXBp8p
ymTzJBZLs5RGQx0dDbR7+PlCC6tPvUqSsPhK4nlYHHhmfWnPWGRaPW+W2EeQHlJx
nl5VfK66lYX3QYnh8zNiZ+xjVRu+6O8rhEuGt38dt7jtNlSgucx+5UHxPe0CgYA4
9RcGOU9Y1ufD13v/ILqphDOhRgZ7dChGJRc4ps0Fn8n2Zu9RcRZM0riB2XDXFmwy
Fvh8J513QP3h9Lu7XXRKv19sNouPQcxt20NfS2NmNKmR5L/4DJlRo4aB3u5Q8x0u
XF4V7GFPvrY/iwnKgfbpXrba0g11uVIiLCprsrgMdwKBgHvebXxV8hmROAoUd1F3
wm9heCTdZNVD3ci/AYW3/n04weZqkAfdmaev64jFBPnXdTZDC12qXprOWYpeal3A
eHjpRZRphXwOCJ6me14qnRL6ir6J1o/DzJIATszpf7GTnlqDUlBQNTT9SOmbgIYq
YftRX/a/t18CpitrzViVgQ+l
-----END PRIVATE KEY-----
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
