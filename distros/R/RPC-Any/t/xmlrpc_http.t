#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 2453;
use RPC::Any::Server::XMLRPC::HTTP;
use RPC::Any::Server::XMLRPC::CGI;
use Support qw(test_xmlrpc);

use constant DEFAULT_HEADERS => {
    POST => "/ HTTP/1.1",
    Host => "localhost",
    "Content-Type" => "text/xml",
};

my %tests = (Support::SERVER_TESTS, Support::XML_TESTS, Support::HTTP_TESTS);
my $http_server = RPC::Any::Server::XMLRPC::HTTP->new();
my $cgi_server  = RPC::Any::Server::XMLRPC::CGI->new();

foreach my $server ($http_server, $cgi_server) {
    foreach my $http_request (0, 1) {
        foreach my $name (sort keys %tests) {
            my $test = $tests{$name};
            $test->{headers} ||= DEFAULT_HEADERS;
            $test->{http_request} = $http_request;
            my $send_name = $name . ($http_request ? " request" : '');
            $send_name .= " cgi" if $server->does('RPC::Any::Interface::CGI');
            test_xmlrpc($server, $test, $send_name);
        }
    }
}