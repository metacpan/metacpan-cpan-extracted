# -*- perl -*-
# Miniature swarm of 1 seed and 5 new peers
#
use strict;
use warnings;
use Module::Build;
use Test::More;
use Socket qw[SOCK_DGRAM /F_INET/ unpack_sockaddr_in inet_ntoa];
use File::Temp qw[];
use Time::HiRes qw[sleep];
use lib q[../../lib];
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
plan tests => int(($Seeds * 2) + ($Peers * 2));
my $sprintf = q[%0] . length($Peers > $Seeds ? $Peers : $Seeds) . q[d];
my $_infohash = q[2b3aaf361bd40540bf7e3bfd140b954b90e4dfbc];
my (%client, %_tracker_data, $udpd);
SKIP: {
    skip(q[TCP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $okay_tcp;
    skip(q[UDP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $okay_udp;
    my $_tracker_port = setup_tracker();
    skip(sprintf(q[Unable to start UDP tracker: [%d] %s], $^E, $^E),
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $_tracker_port && $udpd;
    for my $chr (1 .. $Seeds) {
        $chr = sprintf $sprintf, $chr;
        $client{q[seed_] . $chr}
            = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[Failed to create seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[seed_] . $chr};
        $client{q[seed_] . $chr}->_set_use_dht($okay_udp);
        my $torrent = $client{q[seed_] . $chr}->add_torrent(
                                     {Path    => $miniswarm_dot_torrent,
                                      BaseDir => q[./t/900_data/930_miniswarm]
                                     }
        );
        skip(sprintf(q[Failed to load torrent for seed_%s], $chr),
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
        ok(scalar($torrent->is_complete),
            sprintf(q[seed_%s is seeding], $chr));
        skip(sprintf(q[Failed to load torrent for seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $torrent->is_complete;
        my $tracker = qq[udp://127.0.0.1:$_tracker_port/announce];
        $torrent->_add_tracker([$tracker]);
        $client{q[seed_] . $chr}->on_event(
            q[tracker_success],
            sub {
                my ($s, $a) = @_;
                my ($t, $p) = ($a->{q[Tracker]}, $a->{q[Payload]});
                ok(1, sprintf(q[seed_%s announce okay], $chr));
                return $t->_tier->_torrent->_new_peer();
            }
        );
        $client{q[seed_] . $chr}->do_one_loop(0.1);
    }
    for my $chr (1 .. $Peers) {
        $chr = sprintf $sprintf, $chr;
        $client{$chr} = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[Failed to create leech_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{$chr};
        $client{$chr}->_set_use_dht($okay_udp);
        my $torrent =
            $client{$chr}->add_torrent(
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
        skip(sprintf(q[Failed to load torrent for leech_%s], $chr),
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
        $torrent->on_event(
            q[tracker_success],
            sub {
                my ($s, $a) = @_;
                my ($t, $p) = ($a->{q[Tracker]}, $a->{q[Payload]});
                ok(1, sprintf(q[peer_%s announce okay], $chr));
                return $t->_tier->_torrent->_new_peer();
            }
        );
        my $tracker = qq[udp://127.0.0.1:$_tracker_port/announce];
        $torrent->_add_tracker([$tracker]);
    }
    while ($test_builder->{q[Curr_Test]} < $test_builder->{q[Expected_Tests]})
    {   grep { $_->do_one_loop(0.50); check_tracker(); } values %client;
        sleep 0.50;
        skip(q[This is taking too long and I have a train to catch.],
             (      $test_builder->{q[Expected_Tests]}
                  - $test_builder->{q[Curr_Test]}
             )
        ) if (int(time - $^T) > $Timeout);
    }

    END {
        for my $client (values %client) {
            for my $file (@{$client->torrents->{$_infohash}->files}) {
                $file->_close;
            }
        }
    }
}

sub setup_tracker {
    my $_tracker_port = 0;
    my $_tracker_host = q[127.0.0.1];
    socket($udpd, PF_INET, SOCK_DGRAM, getprotobyname(q[udp]))
        || skip(q[Failed to open socket for tracker],
                (      $test_builder->{q[Expected_Tests]}
                     - $test_builder->{q[Curr_Test]}
                )
        );
    bind($udpd,
         pack(q[Sna4x8],
              &AF_INET, $_tracker_port,
              (join q[], map { chr $_ } ($_tracker_host =~ m[(\d+)]g)))
        )
        || skip(sprintf(q[Failed to bind tracker to port: [%d] %s], $^E, $^E),
                (      $test_builder->{q[Expected_Tests]}
                     - $test_builder->{q[Curr_Test]}
                )
        );
    ($_tracker_port, $_tracker_host) = unpack_sockaddr_in(getsockname($udpd));
    warn(sprintf q[UDP Mini-Tracker running on udp://%s:%d/],
         inet_ntoa($_tracker_host),
         $_tracker_port);
    return $_tracker_port;
}

sub check_tracker {
    my $rin = q[];
    vec($rin, fileno($udpd), 1) = 1;
    my ($nfound, $timeleft) = select($rin, undef, undef, 0.1);
    return if $nfound == 0;
    return if vec($rin, fileno($udpd), 1) != 1;
    my $paddr = recv($udpd, my ($data), 1024 * 16, 0);
    if (length($data) == 16) {
        my ($cid, $action, $tid) = unpack q[a8NN], $data;
        if (    $cid eq qq[\0\0\4\27'\20\31\x80]
            and $action == 0)
        {   $cid = chr(rand(128)) . chr(rand(256)) . qq[\4\27'\20\31\x80];
            $_tracker_data{q[peers]}{$paddr} = {ConnectionID => $cid,
                                                Infohashes   => {},
            };
            send($udpd, pack(q[NNa8], 0, $tid, $cid), 0, $paddr);
        }
    }
    elsif (length($data) == 98) {
        my ($cid,        $action,   $tid,      $info_hash, $peer_id,
            $downloaded, $left,     $uploaded, $event,     $ipaddress,
            $key,        $num_want, $port
            )
            = unpack q[a8NN] . q[a20 a20 a8 a8 a8 N N N N n],
            $data;
        if (    $cid eq $_tracker_data{q[peers]}{$paddr}{q[ConnectionID]}
            and $action == 1)
        {   my $_torrent = {Infohash   => unpack(q[H*], $info_hash),
                            PeerID     => $peer_id,
                            Downloaded => unpack64($downloaded),
                            Left       => unpack64($left),
                            Uploaded   => unpack64($uploaded),
                            Event      => $event,
                            IPAddress  => (
                                  $ipaddress
                                ? $ipaddress
                                : inet_ntoa([unpack_sockaddr_in($paddr)]->[1])
                            ),
                            Key  => $key,
                            Port => $port
            };
            $_tracker_data{q[peers]}{$paddr}{q[Infohashes]}{$info_hash}
                = $_torrent;
            my @_peers = grep {
                       $_->{q[Infohashes]}{$info_hash}
                    && $cid ne $_->{q[ConnectionID]}
            } values %{$_tracker_data{q[peers]}};
            my $seeds
                = grep { $_->{q[Infohashes]}{$info_hash}{q[Event]} == 1 }
                @_peers;
            my $leech = scalar @_peers - $seeds;
            send(
                $udpd,
                pack(
                    q[N N] . q[N N N a*],
                    1, $tid, 1800, $leech, $seeds,
                    compact(
                        map {
                            $_->{q[Infohashes]}{$info_hash}{q[IPAddress]}
                                . q[:]
                                . $_->{q[Infohashes]}{$info_hash}{q[Port]}
                            } @_peers
                    )
                ),
                0,
                $paddr
            );
        }
    }
    else {
        die q[Next!];
    }
}
my $little;
BEGIN { $little = unpack q[C], pack q[S], 1; }

sub unpack64 {    # [id://36314]
    my ($str) = @_;
    $str = reverse $str if $little;
    my $big;
    if (!eval { $big = unpack(q[Q], $str); 1; }) {
        my ($lo, $hi) = unpack q[LL], $str;
        ($hi, $lo) = ($lo, $hi) if !$little;
        $big = $lo + $hi * (1 + ~0);
        if ($big + 1 == $big) {
            warn q[Forced to approximate!\n];
        }
    }
    return $big;
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

