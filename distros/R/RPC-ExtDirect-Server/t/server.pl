# This script can be used for manual HTTP server testing in case
# something goes awry

use strict;
use warnings;

use Getopt::Std;
use RPC::ExtDirect::Server;

my %options;

getopt('pd', \%options);

my $server = RPC::ExtDirect::Server->new(
    static_dir => $options{d} || '/tmp',
    port       => $options{p} || 30000 + int rand 10000,
);

my $port = $server->port;

print "Listening on port $port\n";

$server->run();

