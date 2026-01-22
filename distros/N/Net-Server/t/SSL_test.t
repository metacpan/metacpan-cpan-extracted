#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note skip);
my $env = prepare_test({n_tests => 5, start_port => 20200, n_ports => 1}); # runs three of its own tests

if (! eval { require IO::Socket::SSL }
   ) {
  SKIP: { skip("Cannot load IO::Socket::SSL libraries to test Socket SSL server: $@", 2); };
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
        note $line;
        print $remote "exit\n";
        my $line2 = <$remote>;
        note $line2;
        return 1;

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            open STDERR, ">", "/dev/null";
            my $s = Net::Server::Test->run(
                host  => $env->{'hostname'},
                port  => $env->{'ports'}->[0],
                proto => 'ssl',
                ipv   => '*', # $env->{'ipv'}, # IO::Socket::SSL always tries INET6 if it is available so we should listen on 6 if it is available
                SSL_cert_file => "$Bin/self_signed.crt",
                SSL_key_file  => "$Bin/self_signed.key",
                background => 0,
                setsid => 0,
                );
        } || do {
            note("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || note("Error: $@");
