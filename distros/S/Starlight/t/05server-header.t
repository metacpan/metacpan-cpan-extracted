#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} }

use HTTP::Request;
use LWP::UserAgent;
use Plack::Loader;
use Test::More;
use Test::TCP;

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
        unlike scalar $res->header('server'), qr/Hello/, 'content in headers';

        $res = $ua->get("http://127.0.0.1:$port/?server=1");

        ok $res->is_success, 'is_success';
        is $res->code, '200', 'code';
        is $res->message, 'OK', 'message';
        unlike $res->header('server'), qr/Starlight/, 'server in headers';
        like scalar $res->header('server'), qr/Hello/, 'content in headers';

        sleep 1;
    },
    server => sub {
        my $port = shift;
        my $loader = Plack::Loader->load(
            'Starlight',
            quiet       => 1,
            port        => $port,
            max_workers => 5,
            ipv6        => 0,
            host        => '127.0.0.1',
        );
        $loader->run(
            sub {
                my $env = shift;
                my @headers = ('Content-Type', 'text/html');
                push @headers, 'Server', 'Hello' if $env->{QUERY_STRING};
                [200, \@headers, ['HELLO']];
            }
        );
        exit;
    },
);

done_testing;
