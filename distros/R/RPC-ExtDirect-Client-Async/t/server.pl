#!/usr/bin/perl

# This script can be used for manual HTTP server testing in case
# something goes awry

use common::sense;

use lib 't/lib';
use test::class::cookies;

use RPC::ExtDirect::Server;

my $port = shift @ARGV || 30000 + int rand 100;

my $server = RPC::ExtDirect::Server->new(
    static_dir => 't/htdocs',
    port       => $port,
);

print "Listening on port $port\n";

$server->run();

