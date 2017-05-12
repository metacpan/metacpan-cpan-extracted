#!/usr/bin/perl 
#
# Script to be used by Nagios to check Redis memory usage
#
# typical usage:
#    nagios-redis-memory-usage.pl -H 127.0.0.1 -w 70 -c 90
#
use strict;

use Redis;
use Getopt::Std;

use constant {
    OK       => 0,
    WARNING  => 1,
    CRITICAL => 2,
    UNKNOWN  => 3
};

my %opts;
getopts('H:p:w:c:?hv', \%opts);

usage() if ( exists $opts{h} || exists $opts{'?'} || !exists $opts{H});

my $VERBOSE = exists $opts{v};

# Defaults
$opts{p} ||= '6379';
$opts{w} ||= 75;
$opts{c} ||= 95;
for (qw(p w c)) {
    if ($opts{$_} =~ m/[^0-9]/) {
        warn "Invalid value for option $_\n";
        exit UNKNOWN;
    }
}

if ($opts{w} > $opts{c}) {
    warn "warn level should be lower than critical level\n";
    usage();
}

my $service = "$opts{H}:$opts{p}";

my $conn = Redis->new( server => $service, reconnect => 3);
    
if (!$conn) {
    warn "can't connect to $service\n";
    exit CRITICAL;
}

my $info = $conn->info('memory');
my $mem_used = $info->{used_memory};
my (undef, $mem_avail) = $conn->config('get', 'maxmemory');

$_ = int($_) for ($mem_avail, $mem_used);

if (!$mem_used) {
    warn "unexpected value for memory used on $service\n";
    exit UNKNOWN;
}
if (!$mem_avail) {
    warn "unexpected value for memory available on $service\n";
    exit UNKNOWN;
}

my $perc = 100 * $mem_used / $mem_avail;

print "avail: $mem_avail, used: $mem_used, perc: $perc\n"
    if $VERBOSE;

if ($perc < $opts{w}) {
    print "$perc % is OK\n" if $VERBOSE;
    exit OK;
}
elsif ($perc < $opts{c}) {
    printf "%s: memory usage is %.1f%% (threshold: %.1f)\n",
        'Warning', $perc, $opts{w};
    exit WARNING;
}
else {
    printf "%s: memory usage is %.1f%% (threshold: %.1f)\n",
        'Critical', $perc, $opts{c};
    exit CRITICAL;
}

sub usage {
    print "usage $0 -H host [-p port] [-w perc] [-c perc] [-v]\n";
    exit;
}
