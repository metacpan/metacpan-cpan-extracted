#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 1006;
use RPC::Any::Server::JSONRPC;
use Support qw(test_jsonrpc extract_versioned_tests);

my %tests = (Support::SERVER_TESTS, Support::JSON_TESTS);

my $server = RPC::Any::Server::JSONRPC->new();

my $versioned = extract_versioned_tests(\%tests);
_do_tests($server, $versioned);

foreach my $version (qw(1.0 1.1 2.0)) {
    _do_tests($server, \%tests, $version);
}

sub _do_tests {
    my ($server, $my_tests, $version) = @_;

    foreach my $name (sort keys %$my_tests) {
        my $test = $my_tests->{$name};
        if ($version) {
            $test->{version} = $version;
            $name = "$name $version";
        }
        test_jsonrpc($server, $test, $name);
    }
}