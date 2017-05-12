#!/usr/bin/perl

use strict;
use warnings;

use Net::Hadoop::YARN;
use Data::Dumper;

$| = 1;

$Data::Dumper::Indent   = 1;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

my @servers = (
    # specify your ResourceMaster host:port
    # and perhaps the other HA-node if you have one
    # like
    # localhost:8088
    #
) or die "No server specified";

my $rm = Net::Hadoop::YARN::ResourceManager->new(
            servers => \@servers,
            debug => 1,
        );

print "Statistics:\n\n";
print "info:          ", Dumper $rm->info;
print "metrics:       ", Dumper $rm->metrics;
print "scheduler:     ", Dumper $rm->scheduler;
print "apps:          ", Dumper $rm->apps;
print "apps:          ", Dumper $rm->apps(            states => 'RUNNING'   );
print "appstatistics: ", Dumper $rm->appstatistics;
print "appstatistics: ", Dumper $rm->appstatistics(   states => 'RUNNING'   );
print "appstatistics: ", Dumper $rm->appstatistics( { states => 'RUNNING' } );
print "nodes:         ", Dumper $rm->nodes;

print "\n\nException testing\n\n";

eval { $rm->apps("application_1324057493980_0001") } or print "Captured error: $@\n"; # dies
eval { $rm->apps({statqsdfqes => "RUNNING"}      ) } or print "Captured error: $@\n"; # silently ignored
eval { $rm->apps({states      => "RUNNIdfqsdfNG"}) } or print "Captured error: $@\n"; # dies

print "\n\nNode testing:\n\n";

for my $node (values @{$rm->nodes}) {
    if ( $node->{state} eq 'LOST' ) {
        warn "The node: $node->{nodeHostName} is lost. Skipping ...\n";
        next;
    }

    # TODO: there seems to be either a JSON parsing bug or an autovivification issue:
    #
    # nodeHTTPAddress is converted into a hash when it's an empty string (state=LOST)
    #
    # Although the skip check above prevent reaching to this point, the API shouldn't
    # convert it into a HASH.
    #
    my ($host, $port) = split /:/, $node->{nodeHTTPAddress};
    $host =~ s/cloudera/local/;

    my $nm = Net::Hadoop::YARN::NodeManager->new(
                servers => [ "$host:$port" ],
            );

    print "nm info:       ", Dumper $nm->info;
    print "nm apps:       ", Dumper $nm->apps;
    print "nm containers: ", Dumper $nm->containers;

    for my $container ( values %{ $nm->containers } ) {
        print "nm container:        ", Dumper $container;
        print "nm container detail: ", Dumper $nm->container($container->{id});
    }
    print "\n", '-' x 80, "\n";
}

print "\nFinished!\n";
