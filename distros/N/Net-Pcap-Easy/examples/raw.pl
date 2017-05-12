#!/usr/bin/perl

use strict;
use warnings;
use Net::Pcap::Easy;

my $ppl    = 8192;
my $snap   = 1024;
my $local  = "192.168.0.0/16";
my $lbytes = "\xc0\xa8";
my $upload = 0; # true or false

my $npe = Net::Pcap::Easy->new(
   dev              => ($ARGV[0] || "eth0"),
   filter           => join(" or ", ($upload ? ("(src net $local and not dst net $local)") : ()),
                                                "(dst net $local and not src net $local)" ),
   packets_per_loop => $ppl,
   bytes_to_capture => $snap,

   timeout_in_ms    => 0, # 0ms means forever
   promiscuous      => 0, # true or false
);

sub _do_things {
    my ($cust, $dir, $prot, $port);

    local $" = ", ";
    print "_do_things(@_)\n";
}

1 while defined
# NOTE: defined, since loop returns 0 and undef on error

$npe->loop( sub {
    my ($user_data, $header, $raw_bytes) = @_;

    # $user_data is literally "user data"

    # $header is like this:
    # { caplen => 96, len => 98, tv_sec => 1245963414, tv_usec => 508250 },

    # print unpack("H*", $raw_bytes), "\n";

    my $packet = $_[-1]; # this is the same as $raw_bytes, but I prefer
                         # the word packet and rarely examin the other
                         # elements of @_

    # Calculating precisely what you need is quite a bit faster than
    # decoding the whole packet -- although it's not exactly "Easy."  Say
    # we're interested in IPv4 TCP and UDP packets only... The following
    # assumes *Ethernet* and we don't check it!

    my $l3protlen = ord substr $packet, 14, 1; # the protocol and length
    my $l3prot    = $l3protlen & 0xf0 >> 2; # the protocol part

    return unless $l3prot == 4; # return unless IPv4

    my $l4prot = ord substr $packet, 23, 1; # the L4protocol

    # return unless it's udp(17) or tcp(6)
    return unless $l4prot == 6 or $l4prot == 17;

    my $l3hlen= ($l3protlen & 0x0f) * 4; # number of 32bit words
    my $l4 = 14 + $l3hlen; # the layer 4 data starts here

    # my $src_ip = substr $packet, 26, 4; # these are netowrk order packed
    # my $dst_ip = substr $packet, 30, 4; # but they're pretty easy to convert

    # The ord of the individual bytes of an IP are what we usually
    # see... join(".", map { ord $_} split "", "\xc0\xa8\x01\x01")
    # gives 192.168.1.1

    # Here, I'm only interestd in local network downloads

    if( substr($packet, 30, 2) eq $lbytes ) { # 192.168.0.0/16x.x
        # download direction

        my $cust = ord(substr($packet, 32,1)) .'.'. ord(substr($packet, 33,1));
        my $port = unpack 'n', substr $packet, $l4+0, 2; # src port

        # On my network, in this sense, the last two bytes idenfity a "customer"
        # the source port (on a download) is the port the protocol operates on.
        # 80 for http, 110 for pop3, etc.  Unpack('n', blarg) gives the
        # network order 2-byte port number as a Perl number.

        _do_things($cust, dn => $l4prot == 6 ? "tcp" : "udp", $port);

    } elsif( $upload ) {
        # upload direction

        my $cust = ord(substr($packet, 28,1)) .'.'. ord(substr($packet, 29,1));
        my $port = unpack 'n', substr $packet, $l4+2, 2; # dst port

        # In the upload direction, the protocol port is the dst port.

        _do_things($cust, up => $l4prot == 6 ? "tcp" : "udp", $port);
    }

});
