#!/usr/bin/env perl

use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
    $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;

use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

# disable log output written with Mojo::Log methods
app->log->unsubscribe('message');

my ($b, $content_length, $inbound, $outbound);

plugin 'AccessLog', log => sub { $b = $_[0] }, format => '%s %b %B %I %O';

# reduce server inactivity timeout
app->hook(after_build_tx => sub {
    $_[0]->on(connection => sub { Mojo::IOLoop->stream($_[1])->timeout(0.5) })
});


post '/' => sub {
    my $c = shift;

    $inbound = $c->req->to_string;

    $c->render(text => $inbound);

    $content_length = $c->res->content->body_size;
    $outbound = $c->res->to_string;
};

my $t = Test::Mojo->new;

sub req_ok {
    # issue request
    $t->post_ok('/', @_)->status_is(200);

    my $qr = qr/^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)$/;

    if (like $b, $qr, 'correct log line format') {
        my ($status, $clclf_o, $cl_o, $log_i, $log_o) = $b =~ $qr;

        is $status, 200, "response status ok";
        is $log_i, length($inbound),  "count inbound bytes";
        is $cl_o, $content_length,  "outbound content length";
        is $clclf_o, $content_length,  "outbound content length";
        is $log_o, length($outbound), "count outbound bytes";
    }
}

sub req_intr {
    my ($length, $body) = @_;
    my $tx = $t->ua->build_tx(POST => '/');
    my $req = $tx->req;
    my $body_size = length $body;

    $req->headers->content_length($length);

    my $drain; $drain = sub {
        my $content = shift;
        my $chunk = substr $body, 0, 1, '';

        $drain = undef unless length $body;
        $content->write($chunk, $drain);
    };

    $req->content->$drain;
    $t->tx($t->ua->start($tx));

    my $err = $t->tx->error;

    $err = $err->{message} if ref($err) eq 'HASH';  # Mojolicious v5.0 m(

    if (ok $err, 'POST / failed') {
        is $err, 'Premature connection close', 'right error';

        my $qr = qr/^\-\s+\-\s+0\s+(\d+)\s+(\d+)$/;

        if (like $b, $qr, 'correct log line format') {
            my ($log_i, $log_o) = $b =~ $qr;
            is $log_i, $req->start_line_size + $req->header_size + $body_size,
                "count inbound bytes";
            is $log_o, 0, "no outbound bytes";
        }
    }
}

req_ok("abcdefghi\n" x 100);
req_ok("abcdefghi\n" x 1_000);
req_ok("abcdefghi\n" x 10_000);
req_ok("abcdefghi\n" x 100_000);
req_ok(form => {upload => {filename => 'F', content => "abcdefghi\n" x 100}});
req_ok(form => {upload => {filename => 'F', content => "abcdefghi\n" x 1_000}});
req_ok(form => {upload => {filename => 'F', content => "abcdefghi\n" x 10_000}});
req_ok(form => {upload => {filename => 'F', content => "abcdefghi\n" x 100_000}});
req_intr(1_000 => "abcdefghi\n" x 88);

done_testing;
