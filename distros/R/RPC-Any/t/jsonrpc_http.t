#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 6915;
use RPC::Any::Server::JSONRPC::HTTP;
use RPC::Any::Server::JSONRPC::CGI;
use Support qw(test_jsonrpc extract_versioned_tests);

my %tests = (Support::SERVER_TESTS, Support::JSON_TESTS, Support::HTTP_TESTS);
my $http_server = RPC::Any::Server::JSONRPC::HTTP->new();
my $cgi_server  = RPC::Any::Server::JSONRPC::CGI->new();

use constant CONTENT_TYPE => {
    '1.0' => 'application/json',
    '1.1' => 'application/json',
    '2.0' => 'application/json-rpc',
};

use constant DEFAULT_HEADERS => {
    POST => "/ HTTP/1.1",
    Host => "localhost",
};

foreach my $server ($http_server, $cgi_server) {
    my $versioned = extract_versioned_tests(\%tests);
    _do_tests($server, $versioned);
    
    foreach my $version (qw(1.0 1.1 2.0)) {
        _do_tests($server, \%tests, $version);
    }
}

sub _do_tests {
    my ($server, $my_tests, $version) = @_;
    
    foreach my $http_request (0, 1) {
        foreach my $name (sort keys %$my_tests) {
            my %test = %{ $my_tests->{$name} };
            if ($version) {
                $test{version} = $version;
                $name = "$name $version" . ($http_request ? " request" : '');
                $name .= " cgi" if $server->does('RPC::Any::Interface::CGI');
            }
            my $content_type = CONTENT_TYPE->{$test{version}};
            $test{content_type} ||= $content_type;
            $test{headers} ||= DEFAULT_HEADERS;
            $test{headers}->{'Content-Type'} = "Content-Type: $content_type";
            $test{http_request} = $http_request;
            test_jsonrpc($server, \%test, $name);
        }
    }
}