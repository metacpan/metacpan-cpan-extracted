#!perl
#
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Error qw(:try);
use IO::Socket;
use RT::Client::REST;
plan tests => 5;

my $server = IO::Socket::INET->new(
    Type => SOCK_STREAM,
    Reuse => 1,
    Listen => 10,
) or die "Could not set up TCP server: $@";

my $port = $server->sockport;

my $pid = fork;
die "cannot fork: $!" unless defined $pid;

if (0 == $pid) {                                    # Child
    {
        my $response =
          "HTTP/1.1 302 Redirect\r\n"                               .
          "Location: http://127.0.0.1:$port\r\n"                                   .
          "Content-Type: text/plain; charset=utf-8\r\n\r\n"   .
          "RT/42foo 200 this is a fake successful response header
header line 1
header line 2

response text";
        my $client = $server->accept;
        $client->write($response);
    }
    {
        my $response =
          "HTTP/1.1 302 Redirect\r\n"                               .
          "Location: http://127.0.0.1:$port\r\n"                                   .
          "Content-Type: text/plain; charset=utf-8\r\n\r\n"   .
          "random string";
        my $client = $server->accept;
        $client->write($response);
    }
    exit;
}


my $rt = RT::Client::REST->new(
                               server => "http://127.0.0.1:$port",
                               timeout => 2,
                               verbose_errors => 1,
                               user_agent_args => {
                                                   agent => 'Secret agent',
                                                   max_redirect => 0,
                                                  },
                              );

is $rt->user_agent->agent, 'Secret agent', "Ua correctly initialized";
is $rt->user_agent->max_redirect, 0, "Ua correctly initialized with max redirect";
ok $rt->verbose_errors, "Verbose errors set";

eval {
    my $res = $rt->_submit("ticket/1", undef, {
                                               user => 'a',
                                               pass => 'b',
                                              });
};
like $@, qr{fetching .*/REST/1.0/ticket/1}, "Double redirect dies meaningfully";

$pid = fork;
die "cannot fork: $!" unless defined $pid;

if (0 == $pid) {                                    # Child
    {
        my $response =
          "HTTP/1.1 200 OK\r\n"                               .
          "Location: http://127.0.0.1:$port\r\n"                                   .
          "Content-Type: text/plain; charset=utf-8\r\n\r\n"   .
          "response text";
        my $client = $server->accept;
        $client->write($response);
    }
    exit;
}
eval {
    my $res = $rt->_submit("ticket/1", undef, {
                                               user => 'a',
                                               pass => 'b',
                                              });
};
like $@, qr{Malformed.*/REST/1.0/ticket/1}, "Random data is reported correctly";
