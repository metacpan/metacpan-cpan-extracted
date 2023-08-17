#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy}; delete $ENV{https_proxy} }

use FindBin;
use LWP::UserAgent;
use Test::TCP;
use Test::More;

use Starlight::Server;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'MSWin32' and $] < 5.014 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Too old Perl on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

if (not eval { require IO::Socket::SSL; }) {
    plan skip_all => 'IO::Socket::SSL required';
    exit 0;
}

if (not eval { require LWP::Protocol::https; }) {
    plan skip_all => 'LWP::Protocol::https required';
    exit 0;
}

if (not eval { require Net::SSLeay; Net::SSLeay->VERSION(1.49); }) {
    plan skip_all => 'Net::SSLeay >= 1.49 required';
    exit 0;
}

if (eval { require Acme::Override::INET; }) {
    plan skip_all => 'Acme::Override::INET is not supported';
    exit 0;
}

my $ca_crt = "$FindBin::Bin/../examples/ca.crt";
my $server_crt = "$FindBin::Bin/../examples/localhost.crt";
my $server_key = "$FindBin::Bin/../examples/localhost.key";

test_tcp(
    client => sub {
        my $port = shift;
        sleep 1;

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->ssl_opts(
            verify_hostname => 1,
            SSL_ca_file     => $ca_crt,
        );
        my $res = $ua->get("https://127.0.0.1:$port/");

        ok $res->is_success, 'is_success';
        is $res->code, '200', 'code';
        is $res->message, 'OK', 'message';
        like $res->header('server'), qr/Starlight/, 'server in headers';
        is $res->content, 'https', 'content';

        sleep 1;
    },
    server => sub {
        my $port = shift;
        Starlight::Server->new(
            quiet         => 1,
            host          => '127.0.0.1',
            port          => $port,
            ipv6          => 0,
            ssl           => 1,
            ssl_key_file  => $server_key,
            ssl_cert_file => $server_crt,
        )->run(
            sub { [200, [], [$_[0]->{'psgi.url_scheme'}]] },
        );
    }
);

done_testing;
