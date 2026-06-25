#!/usr/local/bin/perl -w

use IO::Socket::INET;
use Net::Whois::IP qw(whoisip_query);

sub port_43_unavailable {
    my $sock = IO::Socket::INET->new(
        PeerHost => 'whois.arin.net',
        PeerPort => 43,
        Proto    => 'tcp',
        Timeout  => 5,
    );

    return !defined $sock;
}

if ( $ENV{AUTOMATED_TESTING} && port_43_unavailable() ) {
    print "1..0 # SKIP Cannot reach whois.arin.net:43; live WHOIS tests require port 43 connectivity\n";
    exit 0;
}

print "1..5\n";

my $i=1;
my @ips = ("144.134.121.81","209.73.229.163","200.52.173.3","211.184.167.213","80.105.135.82");

foreach my $ip (@ips) {
    my $response = whoisip_query($ip);

    if (ref($response) eq "HASH") {
        printf "ok %d\n", $i++;
    } else {
        printf "not ok %d\n", $i++;
    }
}

