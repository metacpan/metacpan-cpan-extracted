package Plack::Client::Test;
use strict;
use warnings;

use HTTP::Headers;
use Plack::Runner;
use Plack::Util;
use Test::More;
use Test::TCP;

use Plack::Client;

use Exporter 'import';
our @EXPORT_OK = qw(full_body check_headers response_is test_tcp_plackup);
our @EXPORT = @EXPORT_OK;

sub full_body {
    my ($body) = @_;

    return $body unless ref($body);

    my $ret = '';
    Plack::Util::foreach($body, sub { $ret .= $_[0] });
    return $ret;
}

sub check_headers {
    my ($got, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    isa_ok($got, 'HTTP::Headers') || return;

    if (ref($expected) eq 'ARRAY') {
        $expected = HTTP::Headers->new(@$expected);
    }
    elsif (ref($expected) eq 'HASH') {
        $expected = HTTP::Headers->new(%$expected);
    }
    isa_ok($expected, 'HTTP::Headers') || return;

    my @expected_keys = $expected->header_field_names;
    my @got_keys = $got->header_field_names;

    my %default_headers = map { $_ => 1 } qw(
        Date Server Content-Length Client-Date Client-Peer Client-Response-Num
    );
    my %got_exists      = map { $_ => 1 } @got_keys;
    my %expected_exists = map { $_ => 1 } @expected_keys;

    my $success = 1;
    for my $header (@expected_keys) {
        ok($got_exists{$header}, "$header exists")
            || do { $success = 0; next };
        is($got->header($header), $expected->header($header),
           "$header header is the same")
            || do { $success = 0; next };
    }

    for my $header (@got_keys) {
        next if $default_headers{$header};
        next if $expected_exists{$header};
        fail("got extra header $header");
        $success = 0;
    }

    if (!$success) {
        diag("####################");
        diag("Got:\n" . $got->as_string);
        diag("####################");
        diag("Expected:\n" . $expected->as_string);
        diag("####################");
    }

    $success;
}

sub response_is {
    my ($res, $code, $headers, $body) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isa_ok($res, 'Plack::Response');
    is($res->status, $code, "right status");
    check_headers($res->headers, $headers);
    is(full_body($res->body), $body, "right body");
}

sub test_tcp_plackup {
    my ($server, $client) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test_tcp(
        client => sub {
            my $port = shift;
            $client->('http://localhost:' . $port);
        },
        server => sub {
            my $port = shift;
            my $runner = Plack::Runner->new(env => 'foo');
            $runner->parse_options('--port', $port);
            $runner->run($server);
        },
    )
}

1;
