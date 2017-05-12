#!perl -Tw
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;


BEGIN {
    *note = sub { print "# @_\n" } unless defined &note;
}

# first check that AnyEvent is available
plan skip_all => "AnyEvent is not available" unless eval "use AnyEvent; 1";

# then check that AnyEvent::Pcap is available
eval "use AnyEvent::Pcap";
my $error = $@;
plan skip_all => "AnyEvent::Pcap is not available"
    if $error =~ /^Can't locate/;

plan tests => 18;
is $error, "", "use AnyEvent::Pcap";

my $dev = find_network_device();

SKIP: {
    skip "must be run as root", 17 unless is_allowed_to_use_pcap();
    skip "no network device available", 17 unless $dev;

    my $ae_pcap;
    my $cv = AnyEvent->condvar;

    note "\$ae_pcap = AnyEvent::Pcap->new(device => $dev, ...)";
    $ae_pcap = AnyEvent::Pcap->new(
        device  => $dev,
        packet_handler => sub {
            process_packet(@_);
            $cv->send;
        },
    );

    note '$ae_pcap->run';
    $ae_pcap->run;

    note '$cv->recv';
    $cv->recv;
}

sub process_packet {
    note "> process_packet";
    my ($header, $packet) = @_;

    ok( defined $header,        " - header is defined" );
    isa_ok( $header, 'HASH',    " - header" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header->{$field}, "    - field '$field' is present" );
        ok( defined $header->{$field}, "    - field '$field' is defined" );
        like( $header->{$field}, '/^\d+$/', "    - field '$field' is a number" );
    }

    ok( $header->{caplen} <= $header->{len}, 
        "    - coherency check: packet length (caplen <= len)" );

    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );
}

