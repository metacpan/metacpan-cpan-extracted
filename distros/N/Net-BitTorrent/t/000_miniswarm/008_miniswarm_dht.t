#!perl -Iinc
# Miniature swarm of 1 seed, 3 DHT trackers, and 5 new peers
#
use strict;
use warnings;
use Module::Build;
use Test::More;
use File::Temp qw[];
use lib q[../../lib ../../../];
use Time::HiRes qw[];
use Net::BitTorrent::Protocol qw[:types];
use Net::BitTorrent::Util qw[:compact :bencode];
use Net::BitTorrent;
$|++;
my $test_builder = Test::More->builder;
my $miniswarm_dot_torrent
    = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../] if not -f $miniswarm_dot_torrent;
my $build           = Module::Build->current;
my $okay_tcp        = $build->notes(q[okay_tcp]);
my $okay_udp        = $build->notes(q[okay_udp]);
my $release_testing = $build->notes(q[release_testing]);
my $verbose         = $build->notes(q[verbose]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
my $BlockLength = 2**14;
my $Seeds       = 1;
my $Peers       = 5;
my $Timeout     = 60;
plan tests => int($Seeds + $Peers + 3) * 2;
my $sprintf = q[%0] . length($Peers > $Seeds ? $Peers : $Seeds) . q[d];
my $_infohash = q[2b3aaf361bd40540bf7e3bfd140b954b90e4dfbc];
my %client;
SKIP: {
    skip(q[TCP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $okay_tcp;
    skip(q[UDP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $okay_udp;
    $client{q[DHT_gateway]}
        = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
    skip(sprintf(q[Failed to open UDP port]),
         $test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
        if not $client{q[DHT_gateway]}->_udp_port;
    ok($client{q[DHT_gateway]}->isa(q[Net::BitTorrent]),
        q[DHT (bystander gateway)]);
    ok($client{q[DHT_gateway]}->_use_dht,
        q[DHT (bystander gateway) has enabled dht]);
    $client{q[DHT_seeds]} = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
    skip(sprintf(q[Failed to open UDP port]),
         $test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
        if not $client{q[DHT_seeds]}->_udp_port;
    ok($client{q[DHT_seeds]}->isa(q[Net::BitTorrent]),
        q[DHT (bystander seeds)]);
    ok($client{q[DHT_seeds]}->_use_dht,
        q[DHT (bystander seeds) has enabled dht]);
    $client{q[DHT_seeds]}->_dht->add_node(
            {ip => q[127.0.0.1], port => $client{q[DHT_gateway]}->_udp_port});
    $client{q[DHT_peers]} = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
    skip(sprintf(q[Failed to open UDP port]),
         $test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
        if not $client{q[DHT_peers]}->_udp_port;
    ok($client{q[DHT_peers]}->isa(q[Net::BitTorrent]),
        q[DHT (bystander peers)]);
    ok($client{q[DHT_peers]}->_use_dht,
        q[DHT (bystander peers) has enabled dht]);
    $client{q[DHT_peers]}->_dht->add_node(
            {ip => q[127.0.0.1], port => $client{q[DHT_gateway]}->_udp_port});

    for my $chr (1 .. $Seeds) {
        $chr = sprintf $sprintf, $chr;
        $client{q[seed_] . $chr}
            = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[Failed to create seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[seed_] . $chr};
        ok($client{q[seed_] . $chr}->_use_dht,
            sprintf q[seed_%s has enabled dht], $chr);
        my $torrent = $client{q[seed_] . $chr}->add_torrent(
                                     {Path    => $miniswarm_dot_torrent,
                                      BaseDir => q[./t/900_data/930_miniswarm]
                                     }
        );
        skip(sprintf(q[seed_%s Failed to load torrent for seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $torrent;
        $torrent->hashcheck;
        skip(
            sprintf(
                q[Failed to load torrent for seed_%s: Seed data is missing/corrupt],
                $chr),
            $test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]}
        ) if not $torrent->is_complete;
        skip(sprintf(q[Failed to open UDP port], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[seed_] . $chr}->_udp_port;
        ok(scalar($torrent->is_complete),
            sprintf(q[seed_%s is seeding], $chr));
        skip(sprintf(q[Failed to load torrent for seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $torrent->is_complete;
        $client{q[seed_] . $chr}->_dht->add_node(
              {ip => q[127.0.0.1], port => $client{q[DHT_seeds]}->_udp_port});
        $client{q[seed_] . $chr}->do_one_loop(0.1);
    }
    for my $chr (1 .. $Peers) {
        $chr = sprintf $sprintf, $chr;
        $client{q[peer_] . $chr}
            = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[peer_%s Failed to open UDP port], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[peer_] . $chr}->_udp_port;
        skip(sprintf(q[Failed to create dht_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[peer_] . $chr};
        ok($client{q[peer_] . $chr}->_use_dht,
            sprintf q[peer_%s has enabled dht], $chr);
        my $torrent = $client{q[peer_] . $chr}->add_torrent(
                                     {Path => $miniswarm_dot_torrent,
                                      BaseDir =>
                                          File::Temp::tempdir(
                                          sprintf(q[miniswarm_%s_XXXX], $chr),
                                          CLEANUP => 1,
                                          TMPDIR  => 1
                                          ),
                                      BlockLength => $BlockLength
                                     }
        );
        skip(sprintf(q[Failed to load torrent for dht_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $torrent;
        $torrent->hashcheck;
        $torrent->on_event(
            q[piece_hash_pass],
            sub {
                my ($self, $args) = @_;
                my $piece
                    = $args->{q[Torrent]}->_piece_by_index($args->{q[Index]});
                ok($args->{q[Torrent]}->is_complete,
                    sprintf(q[peer_%s is seeding], $chr))
                    if $args->{q[Torrent]}->is_complete;
                return;
            }
        );
        $client{q[peer_] . $chr}->_dht->add_node(
              {ip => q[127.0.0.1], port => $client{q[DHT_peers]}->_udp_port});
    }
    while ($test_builder->{q[Curr_Test]} < $test_builder->{q[Expected_Tests]})
    {   grep { $_->do_one_loop(0.1); } values %client;
        skip(q[This is taking too long and I have a train to catch.],
             (      $test_builder->{q[Expected_Tests]}
                  - $test_builder->{q[Curr_Test]}
             )
        ) if (int(time - $^T) > $Timeout);
    }

    END {
        for my $client (values %client) {
            next if not defined $client->torrents->{$_infohash};
            for my $file (@{$client->torrents->{$_infohash}->files}) {
                $file->_close;
            }
        }
    }
}
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

