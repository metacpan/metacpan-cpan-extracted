#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use SM;

my $arrival_time = shift or help();
my $service_time = shift or help();
my $duration     = shift or help();

my $server = new SM::Server(sub { $service_time });
my $handle;
$handle = sub {
    $server->join_queue(new SM::Client);
    SM::Simulator->schedule(
        SM::Simulator->now + $arrival_time => $handle
    );
};
SM::Simulator->schedule( $arrival_time => $handle );
print "0..$duration\n";
SM::Simulator->run(duration => $duration);

sub help { die "usage: $0 <arrival_time> <service_time> <duration>\n"; }

