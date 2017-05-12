#!/usr/bin/perl

use strict;
use warnings;

use List::Util 'reduce';
use Getopt::Long;

BEGIN { push @INC, 'lib'; }
use SM;

GetOptions("servers=i"      => \my $server_count,
           "service-rate=f" => \my $service_rate,
           "arrival-rate=f" => \my $arrival_rate,
           "duration=f"     => \my $duration) or help();

defined $server_count && defined $service_rate && defined $arrival_rate && $duration or
    help();

my @servers;
for (1..$server_count) {
    push @servers, new SM::Server( sub { exponential( 1/$service_rate ) } );
}
my $handle;
$handle = sub {
    my $server = reduce { $a->queue_len <= $b->queue_len ? $a : $b } @servers;
    $server->join_queue(new SM::Client);
    my $time_of_next = SM::Simulator->now + exponential( 1/$arrival_rate );
    SM::Simulator->schedule( $time_of_next => $handle );
};
SM::Simulator->schedule( exponential( 1/$arrival_rate ) => $handle );
print "0..$duration\n";
SM::Simulator->run(duration => $duration);

sub exponential { - $_[0] * log(rand(1) + 1e-15) }

sub help {
    print <<_EOC_;
Usage: $0 --servers 5 --arrival_rate 2.0 --service_rate 1.0 --duration 1000.0
_EOC_
    exit(0);
}
