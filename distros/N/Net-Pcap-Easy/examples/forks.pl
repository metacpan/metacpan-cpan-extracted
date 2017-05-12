#!/usr/bin/perl

use strict;
use warnings;
use Net::Pcap::Easy;
use forks;
use forks::shared;
use Time::HiRes qw(sleep);
use List::Util;
use Getopt::Long qw(:config bundling);

my %o; my %ol = (
    "packets-per-loop|ppl|p=i" => "packets per waitloop (default: 1)",
    "interface|i=s@"           => "interfaces to listen on (default: lo,eth0)",
    "filter|f=s"               => "pcap filter (default: udp; note only udp works anyway)",
    "snap-length|snaplen|s=i"  => "number of bytes to capture per packet (up to the interface MTU, default: 1500)",
    "total-packets|packets|t"  => "the number of packets to try to collect (will sometimes go over this limit, default 30)",
    "help|h" => "this help"
);

if( not GetOptions(\%o, keys %ol) or $o{help} ) {
    my $ml = List::Util::max(map {length} keys %ol);
    print sprintf('%*s  %s', $ml, $_, $ol{$_}), "\n" for sort keys %ol;
    exit 0;
}

push @{$o{interface}}, qw(lo eth0) unless eval { @{$o{interface}} };
$o{filter} ||= "udp";
$o{'packets-per-loop'} ||= 1;
$o{'snap-length'}      ||= 1500;
$o{'total-packets'}    ||= 30;

my @results : shared;
my $still_going : shared = 1;

for my $dev (@{$o{interface}}) {
    threads->new(sub {

        $SIG{TERM} = $SIG{INT} = $SIG{USR1} = sub { $still_going = 0 };

        my $npe = Net::Pcap::Easy->new(
            dev => $dev,
            filter => $o{filter},
            udp_callback => sub {
                my ($npe, $ether, $ip, $udp) = @_;

                push @results, [ $dev => $ether, $ip, $udp ];
            },
            packets_per_loop => $o{'packets-per-loop'},
            bytes_to_capture => 1500,
        );

        $npe->loop while $still_going;
    });
}

my $total = $o{'total-packets'};
while($still_going) {
    sleep 0.1;
    while( my $item = shift @results ) {
        my ($dev, $ether, $ip, $udp) = @$item;

        printf "%-7s %-12s %-15s %5d => %-12s %-15s %5d",
            $dev,
            $ether->{src_mac}, $ip->{src_ip}, $udp->{src_port},
            $ether->{dest_mac}, $ip->{dest_ip}, $udp->{dest_port};

        print "\n";

        $total --;
        $still_going = 0 if $total < 1;
    }
}

for( threads->list ) { $_->kill('SIGUSR1');
    $_->join;
}
