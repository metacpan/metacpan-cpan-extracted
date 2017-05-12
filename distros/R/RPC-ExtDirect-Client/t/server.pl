#!/usr/bin/perl

# This script can be used for manual HTTP server testing in case
# something goes awry. Note that it does NOT fork so should be
# run in a separate terminal session.
#
# This script is naive in its assumption that a randomly generated port
# will be available for listening. If it's not, restart the script
# manually.

use strict;
use warnings;

use Getopt::Std;

use RPC::ExtDirect::Server;

my %opt = ( h => 'localhost', p => 30000 + int rand 10000 );
getopt('hp', \%opt) if @ARGV;

my $server = RPC::ExtDirect::Server->new(
    host       => $opt{h},
    port       => $opt{p},
    static_dir => 't/htdocs',
);

print "Listening on $opt{h}:$opt{p}\n";

$server->run();

