# Test custom URI handlers

use strict;
use warnings;

use Test::More tests => 8;

use JSON;

use lib 't/lib';
use RPC::ExtDirect::Test::Util qw/ cmp_json /;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Server::Test::Util;

my $static_dir = 't/htdocs';

my $foo_html = <<'END_OF_FOO';
<html><body><p>foo</p></body></html>
END_OF_FOO

my $bar_json = JSON::to_json({ foo => 42 });

sub handle_foo {
    my ($self, $cgi) = @_;

    print $cgi->header(
        -type   => 'text/html',
        -status => '200 OK',
    );

    print $foo_html;

    return 1;
}

sub handle_json {
    my ($self, $cgi) = @_;

    print $cgi->header(
        -status => '200 OK',
        -type   => 'application/json',
        -Content_Length => do { use bytes; length $bar_json; },
    );

    print $bar_json;

    return 1;
}

sub handle_api {
    my ($self, $cgi) = @_;

    print $cgi->header(
        -status => '401 Not Authorized',
    );

    return 1;
}

my ($host, $port) = maybe_start_server(
    static_dir => $static_dir,
    dispatch   => [
        qr{^/foo$}       => \&handle_foo,
        '^/bar/json$'    => \&handle_json,
        '/extdirectapi$' => \&handle_api,
    ],
);

ok $port, "Got host: $host and port: $port";

my $resp = get "http://$host:$port/foo";

is_status   $resp, 200,                            'foo status';
like_header $resp, 'Content-Type', qr{^text/html}, 'foo content type';
is_content  $resp, $foo_html,                      'foo content';

$resp = get "http://$host:$port/bar/json";

is_status   $resp, 200, 'bar status';
like_header $resp, 'Content-Type', qr{^application/json}, 'bar content type';

my $have = $resp->{content};

cmp_json $have, $bar_json, 'bar content';

$resp = get "http://$host:$port/extdirectapi";

is_status $resp, 401, 'api override status';

