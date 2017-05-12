use strict;
use warnings;
use AnyEvent;
use lib '../lib';
use Net::BitTorrent::DHT;
use Bit::Vector;
$|++;
our $VERSION = 'v1.0.0';
eval $VERSION;

# Standalone node with user-defined port and boot_nodes
my $dht = Net::BitTorrent::DHT->new(
          port => [1337 .. 1340, 0],
          boot_nodes =>
              [
                ['router.bittorrent.com', 6881],
                ['router.utorrent.com', 6881],
                ['router.bittorrent.com', 8991],
                ['dht.transmissionbt.com', 6881]
                ]
);

# Two 'quests' for peers (these are two popular Ubuntu swarms)
# See http://torrent.ubuntu.com:6969/ for updated list
my $quest_A
    = $dht->get_peers(Bit::Vector->new_Hex(160, 'ab97a7bca78f2628380e6609a8241a7fb02aa981'), \&dht_cb);
my $quest_B
    = $dht->get_peers(Bit::Vector->new_Hex(160, '79053908d904e26b45e5b63a6d9b121b59ed7375'), \&dht_cb);

# Let's stay up to date with what's going on in the routing table
my $timer = AE::timer 60 * 2, 60 * 5,
    sub { $dht->dump_ipv4_buckets; $dht->dump_ipv6_buckets };
END { $dht->dump_ipv4_buckets && $dht->dump_ipv6_buckets if $dht }

# tick, tick, tick, ...
AnyEvent->condvar->recv;

sub dht_cb {
    my ($infohash, $node, $peers) = @_;
    printf "We found %d peers for %s from %s:%d via DHT\n\t%s\n",
        scalar(@$peers),
        $infohash->to_Hex, $node->host, $node->port,
        join ', ', map { sprintf '%s:%d', @$_ } @$peers;
}

=pod

=head1 NAME

standalone_dht - Quick/dirty demo of a standalone DHT node

=head1 Description

This is just perfect for research. I'll breakdown what's going on in a later
version

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2014 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
