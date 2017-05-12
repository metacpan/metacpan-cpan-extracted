#!perl -Tw
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;


BEGIN {
    *note = sub { print "# @_\n" } unless defined &note;
}

# check that Net::Pcap::Easy is available
eval "use Net::Pcap::Easy";
my $error = $@;
plan skip_all => "Net::Pcap::Easy is not available"
    if $error =~ /^Can't locate/;

plan tests => 18;
is $error, "", "use Net::Pcap::Easy";

my $dev = find_network_device();
my $done = 0;

SKIP: {
    skip "must be run as root", 17 unless is_allowed_to_use_pcap();
    skip "no network device available", 17 unless $dev;

    my $npe = Net::Pcap::Easy->new(
        dev                 => $dev,
        packets_per_loop    => 1,
        bytes_to_capture    => 1024,
        tcp_callback        => \&process_tcp_packet,
    );

    $npe->loop until $done;
}

sub process_tcp_packet {
    note "> process_tcp_packet";
    my ($npe, $ether, $ip, $tcp, $header ) = @_;

    my $xmit = localtime $header->{tv_sec};
    note "$xmit TCP: $ip->{src_ip}:$tcp->{src_port}"
       . " -> $ip->{dest_ip}:$tcp->{dest_port}";

    ok( defined $header,        " - header is defined" );
    isa_ok( $header, 'HASH',    " - header" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header->{$field}, "    - field '$field' is present" );
        ok( defined $header->{$field}, "    - field '$field' is defined" );
        like( $header->{$field}, '/^\d+$/', "    - field '$field' is a number" );
    }

    ok( $header->{caplen} <= $header->{len}, 
        "    - coherency check: packet length (caplen <= len)" );

    my $packet = $ether->{_frame};
    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );
    $done = 1;
}

