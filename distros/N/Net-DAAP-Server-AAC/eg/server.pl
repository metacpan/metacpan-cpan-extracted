#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use POE;
use Net::DAAP::Server::AAC;

my $name = "Net::DAAP::Server::AAC ($$)";
my $port = 9999;

GetOptions("--name=s", \$name, "--port=i", \$port);

my $server = Net::DAAP::Server::AAC->new(
    path => $ARGV[0] || $ENV{HOME},
    port => $port,
    name => $name,
);
$poe_kernel->run;
