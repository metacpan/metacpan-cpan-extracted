#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Request;
use Plack::Request;
use Plack::App::Proxy::Test;

use Plack::App::Proxy::Anonymous;

my $app = sub {
    my ($env) = @_;
    my $req = Plack::Request->new($env);
    my $h = $req->headers->clone;
    $h->remove_header(qw(Connection Host Referer TE));
    my $body = $h->as_string;
    return [200, ['Content-Type' => 'text/plain', 'Content-Length' => length($body)], [$body]];
};

test_proxy(
    app   => $app,
    proxy => sub {
        Plack::App::Proxy::Anonymous->new(remote => "http://$_[0]:$_[1]");
    },
    client => sub {
        my ($cb) = @_;
        my $req = HTTP::Request->new(GET => 'http://localhost/index.html');
        my $res = $cb->($req);
        ok $res->is_success, 'response is success';
        is $res->content, $req->headers->as_string, 'headers are the same';
    },
);

done_testing;
