#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} };

use HTTP::Request::Common;
use Plack::Test;
use Test::More;

if ($^O eq 'MSWin32' and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#40565 on MSWin32';
    exit 0;
}

if ($^O eq 'cygwin' and not eval { require Win32::Process; }) {
    plan skip_all => 'Win32::Process required';
    exit 0;
}

$Plack::Test::Impl = 'Server';
$ENV{PLACK_SERVER} = 'Starlight';
$ENV{PLACK_QUIET} = 1;

test_psgi
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [$$] ];
    },
    client => sub {
        my %seen_pid;
        my $cb = shift;
        sleep 1;
        for (1..23) {
            my $res = $cb->(GET "/");
            $seen_pid{$res->content}++;
        }
        cmp_ok(keys(%seen_pid), '<=', 10, 'In non-harakiri mode, pid is reused');
        sleep 1;
    };

test_psgi
    app => sub {
        my $env = shift;
        $env->{'psgix.harakiri.commit'} = $env->{'psgix.harakiri'};
        return [ 200, [ 'Content-Type' => 'text/plain' ], [$$] ];
    },
    client => sub {
        my %seen_pid;
        my $cb = shift;
        sleep 1;
        for (1..23) {
            my $res = $cb->(GET "/");
            $seen_pid{$res->content}++;
        }
        is keys(%seen_pid), 23, 'In Harakiri mode, each pid only used once';
        sleep 1;
    };

done_testing;
