#!perl -Tw
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;


BEGIN {
    *note = sub { print "# @_\n" } unless defined &note;
}

# first check that POE is available
plan skip_all => "POE is not available" unless eval "use POE; 1";

# then check that POE::Component::Pcap is available
eval "use POE::Component::Pcap";
my $error = $@;
plan skip_all => "POE::Component::Pcap is not available"
    if $error =~ /^Can't locate/;

plan tests => 18;
is( $error, '', "use POE::Component::Pcap" );

my $dev = find_network_device();

SKIP: {
    skip "must be run as root", 17 unless is_allowed_to_use_pcap();
    skip "no network device available", 17 unless $dev;

    note "[POE] create";
    POE::Session->create(
        inline_states => {
            _start      => \&start,
            _stop       => \&stop, 
            got_packet  => \&got_packet,
        },
    );

    note "[POE] run";
    POE::Kernel->run;
}


sub start {
    note "[POE:start] spawning new Pcap session ", $_[&SESSION]->ID,
        " on device $dev";

    POE::Component::Pcap->spawn(
        Alias => 'pcap',  Device => $dev,
        Dispatch => 'got_packet',  Session => $_[&SESSION],
    );

    $_[&KERNEL]->post(pcap => open_live => $dev);
    $_[&KERNEL]->post(pcap => 'run');
}

sub stop {
    note "[POE:stop]";
    $_[&KERNEL]->post(pcap => 'shutdown');
}

sub got_packet {
    note "[POE:got_packet]";
    my $packets = $_[&ARG0];

    # process the first packet only
    process_packet(@{ $packets->[0] });

    # send a message to stop the capture
    $_[&KERNEL]->post(pcap => 'shutdown');
}

sub process_packet {
    note "[POE:process_packet]";
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
