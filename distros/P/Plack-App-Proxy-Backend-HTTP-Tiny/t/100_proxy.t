#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use HTTP::Request;
use Plack::Request;
use Plack::App::Proxy::Test;

use Plack::App::Proxy;

my $pid = $$;

my $app = sub {
    my ($env) = @_;
    my $req = Plack::Request->new($env);
    my $body = "$pid";
    return [200, ['Content-Type' => 'text/plain', 'Content-Length' => length($body), 'X-My-Header' => $pid], [$body]];
};

test_proxy(
    app   => $app,
    proxy => sub {
        Plack::App::Proxy->new(backend => 'HTTP::Tiny', remote => "http://$_[0]:$_[1]");
    },
    client => sub {
        my ($cb) = @_;
        my $req = HTTP::Request->new(GET => 'http://localhost/index.html');
        my $res = $cb->($req);
        ok $res->is_success, 'response is success';
        is $res->status_line, '200 OK', 'response is 200 OK';
        my $h = $res->headers->clone;
        $h->remove_header(qw(Client-Date Client-Peer Client-Response-Num Client-Warning Content-Length Date Server));
        is $h->as_string('|'), "Content-Type: text/plain|X-My-Header: $pid|", 'headers are the same';
        is $res->content, $pid, 'content is the same';
    },
);

done_testing;
