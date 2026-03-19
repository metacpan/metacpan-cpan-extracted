#!/usr/bin/env perl
#
# Simple session counter using encrypted cookie store.
# No server-side storage needed — session lives in the cookie.
#
# Run:
#   pagi-server --app examples/counter.pl --port 5000
#
# Test:
#   curl -v -c cookies.txt -b cookies.txt http://localhost:5000/
#   curl -v -c cookies.txt -b cookies.txt http://localhost:5000/
#   curl -v -c cookies.txt -b cookies.txt http://localhost:5000/reset
#
use strict;
use warnings;
use Future::AsyncAwait;

use PAGI::Middleware::Builder;
use PAGI::Middleware::Session;
use PAGI::Middleware::Session::Store::Cookie;

my $app = async sub {
    my ($scope, $receive, $send) = @_;

    die "Unsupported scope type: $scope->{type}" unless $scope->{type} eq 'http';

    my $session = $scope->{'pagi.session'};
    my $path = $scope->{path} // '/';

    if ($path eq '/reset') {
        $session->{_destroyed} = 1;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['Content-Type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => "Session destroyed. Visit / to start fresh.\n",
            more => 0,
        });
        return;
    }

    $session->{count} //= 0;
    $session->{count}++;

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [['Content-Type', 'text/plain']],
    });
    await $send->({
        type => 'http.response.body',
        body => "Visit #$session->{count}\n",
        more => 0,
    });
};

builder {
    enable 'Session',
        secret => 'change-me-in-production',
        store  => PAGI::Middleware::Session::Store::Cookie->new(
            secret => 'change-me-in-production',
        );
    $app;
};
