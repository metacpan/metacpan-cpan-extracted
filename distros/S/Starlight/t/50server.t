#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} }

use LWP::UserAgent;
use Test::TCP;
use Test::More;

use Starlight::Server;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

test_tcp(
    client => sub {
        my $port = shift;
        sleep 1;

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $res = $ua->get("http://127.0.0.1:$port/");

        ok $res->is_success, 'is_success';
        is $res->code, '200', 'code';
        is $res->message, 'OK', 'message';
        like $res->header('server'), qr/Starlight/, 'server in headers';
        like $res->content, qr/Hello/, 'content';

        sleep 1;
    },
    server => sub {
        my $port = shift;
        Starlight::Server->new(
            quiet => 1,
            host  => '127.0.0.1',
            port  => $port,
            ipv6  => 0,
        )->run(
            sub { [200, [], ["Hello world\n"]] },
        );
    }
);

done_testing;
