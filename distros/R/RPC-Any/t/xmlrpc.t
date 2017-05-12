#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 305;
use RPC::Any::Server::XMLRPC;
use Support qw(test_xmlrpc);

my %tests = (Support::SERVER_TESTS, Support::XML_TESTS);

my $server = RPC::Any::Server::XMLRPC->new();

foreach my $name (sort keys %tests) {
    my $test = $tests{$name};
    test_xmlrpc($server, $test, $name);
}