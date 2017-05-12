#!perl -I../../lib
# Miniature swarm of 1 seeds and 5 new peers
#
use strict;
use warnings;
use Module::Build;
use Test::More;
use Socket qw[SOCK_STREAM /F_INET/ unpack_sockaddr_in inet_ntoa];
use File::Temp qw[];
use Time::HiRes qw[sleep];

#use Math::BigInt 0.78 try => q[Pari,GMP,FastCalc,Calc];
use Net::BitTorrent::Util qw[:compact :bencode];
use Net::BitTorrent;
$|++;
my $test_builder = Test::More->builder;
my $miniswarm_dot_torrent
    = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../] if not -f $miniswarm_dot_torrent;
my $build           = Module::Build->current;
my $okay_tcp        = $build->notes(q[okay_tcp]);
my $release_testing = $build->notes(q[release_testing]);
my $verbose         = $build->notes(q[verbose]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
{    # Just to make sure...
    no warnings q[redefine];
    *Net::BitTorrent::Torrent::private = sub { return 1 };
}
my $BlockLength = 2**16;
my $Seeds       = 1;
my $Peers       = 5;
my $Timeout     = 60;
my $Encrypt     = 1;
plan tests => int(($Seeds * 2) + ($Peers * 2));
my $sprintf = q[%0] . length($Peers > $Seeds ? $Peers : $Seeds) . q[d];
my $_infohash = q[2b3aaf361bd40540bf7e3bfd140b954b90e4dfbc];
my (%client, %_tracker_data, $httpd);
SKIP: {
    skip(q[TCP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $okay_tcp;
    my $_tracker_port = setup_tracker();
    skip(sprintf(q[Unable to bind HTTP tracker: [%d] %s], $^E, $^E),
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) unless $_tracker_port && $httpd;
    my $test_builder = Test::More->builder;
    for my $chr (1 .. $Seeds) {
        $chr = sprintf $sprintf, $chr;
        $client{q[seed_] . $chr}
            = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[Failed to create seed_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{q[seed_] . $chr};
        $client{q[seed_] . $chr}->_set_use_dht(0);
        $client{q[seed_] . $chr}->_set_connections_per_host($Peers);
        $client{q[seed_] . $chr}->_set_encryption_mode($Encrypt);
        $client{q[seed_] . $chr}->on_event(
            q[peer_disconnect],
            sub {
                warn q[Disconnect: ] . $_[1]->{q[Reason]};
            }
        );
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
        my $tracker = qq[http://127.0.0.1:$_tracker_port/announce];
        $torrent->_add_tracker([$tracker]);
        $client{q[seed_] . $chr}->on_event(
            q[tracker_success],
            sub {
                my ($s, $a) = @_;
                my ($t, $p) = ($a->{q[Tracker]}, $a->{q[Payload]});
                ok(1, sprintf(q[seed_%s announce okay], $chr));
            }
        );
        $client{q[seed_] . $chr}->do_one_loop(0.25);
        check_tracker();
    }
    for my $chr (1 .. $Peers) {
        $chr = sprintf $sprintf, $chr;
        $client{$chr} = new Net::BitTorrent({LocalAddr => q[127.0.0.1]});
        skip(sprintf(q[Failed to create leech_%s], $chr),
             $test_builder->{q[Expected_Tests]}
                 - $test_builder->{q[Curr_Test]}
        ) if not $client{$chr};
        $client{$chr}->_set_use_dht(0);
        $client{$chr}->_set_connections_per_host($Peers);
        $client{$chr}->_set_encryption_mode($Encrypt);
        $client{$chr}->on_event(
            q[peer_disconnect],
            sub {
                warn q[Disconnect: ] . $_[1]->{q[Reason]};
            }
        );
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
            }
        );
        my $tracker = qq[http://127.0.0.1:$_tracker_port/announce];
        $torrent->_add_tracker([$tracker]);
        $client{$chr}->do_one_loop(0.25);
        check_tracker();
    }
    while ($test_builder->{q[Curr_Test]} < $test_builder->{q[Expected_Tests]})
    {    #check_tracker();
        for my $peer (values %client) {

            #for (1 .. 3) {
            $peer->do_one_loop(0.33);

            #}
        }
        skip(q[This is taking too long and I have a train to catch.],
             (      $test_builder->{q[Expected_Tests]}
                  - $test_builder->{q[Curr_Test]}
             )
        ) if (int(time - $^T) > $Timeout);
        sleep 0.25;
    }

    END {
        for my $client (values %client) {
            next if !$client->torrents->{$_infohash};
            for my $file (@{$client->torrents->{$_infohash}->files}) {
                $file->_close;
            }
        }
    }
    exit;
}

sub setup_tracker {
    my $_tracker_port = 0;
    my $_tracker_host = q[127.0.0.1];
    socket($httpd, PF_INET, SOCK_STREAM, getprotobyname(q[tcp]))
        || skip(q[Failed to open socket for tracker],
                (      $test_builder->{q[Expected_Tests]}
                     - $test_builder->{q[Curr_Test]}
                )
        );
    bind($httpd,
         pack(q[Sna4x8],
              &AF_INET, $_tracker_port,
              (join q[], map { chr $_ } ($_tracker_host =~ m[(\d+)]g)))
        )
        || skip(sprintf(q[Failed to bind tracker to port: [%d] %s], $^E, $^E),
                (      $test_builder->{q[Expected_Tests]}
                     - $test_builder->{q[Curr_Test]}
                )
        );
    listen($httpd, 1)
        || skip(sprintf(q[Failed to listen on port: [%d] %s], $^E, $^E),
                (      $test_builder->{q[Expected_Tests]}
                     - $test_builder->{q[Curr_Test]}
                )
        );
    (undef, $_tracker_port, undef) = unpack(q[SnC4x8], getsockname($httpd));
    warn(sprintf q[HTTP Mini-Tracker running on 127.0.0.1:%d],
         $_tracker_port);
    return $_tracker_port;
}

sub check_tracker {
    my $rin = q[];
    vec($rin, fileno($httpd), 1) = 1;
    my ($nfound, $timeleft) = select($rin, undef, undef, 0.5);
    return if $nfound == 0;
    return if vec($rin, fileno($httpd), 1) != 1;
    vec($rin, fileno($httpd), 1) = 0;
    if (my $paddr = accept(my ($client), $httpd)) {
        return if !$paddr;
        grep { $_->do_one_loop(0.25); } values %client;
        my $gotten = q[];
        while (sysread($client, my ($data), 1024)) { $gotten .= $data; }
        shutdown($client, 0);
        if ($gotten) {
            if ($gotten =~ m[^GET\s+(/(announce|scrape)\?([^\s]*))]) {
                my $type = $2;
                my %hash = split m[[=&]], $3;
                $hash{q[info_hash]}
                    =~ s|\%([a-f0-9]{2})|pack(q[C], hex($1))|ieg;
                my (undef, undef, @address)
                    = unpack(q[SnC4x8], getsockname($client));
                my %reply;
                if ($type eq q[announce]) {
                    $hash{q[peer_id]}
                        =~ s|\%([a-f0-9]{2})|pack(q[C], hex($1))|ieg;
                    %reply = (interval => 1500,
                              peers => $_tracker_data{$hash{info_hash}} || q[]
                    );
                    $_tracker_data{$hash{info_hash}}
                        = compact(
                               ((join q[.], @address) . q[:] . $hash{port}),
                               uncompact($_tracker_data{$hash{info_hash}}));
                    syswrite($client,
                             join(qq[\015\012],
                                  q[HTTP/1.0 200 Here ya go!],
                                  q[Date: ] . scalar(gmtime) . q[ GMT],
                                  q[Server: Net::BitTorrent test tracker/1.0],
                                  q[Content-type: text/plain],
                                  q[],
                                  bencode(\%reply))
                    );
                }
            }
            else {
                syswrite($client,
                         join(qq[\015\012],
                              q[HTTP/1.0 404 Go away!],
                              q[Date: ] . scalar(gmtime) . q[ GMT],
                              q[Server: Net::BitTorrent test tracker/1.0],
                              q[Content-type: text/plain],
                              q[],
                              q[Bye!])
                );
            }
        }
        shutdown($client, 2);
        close $client;
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

