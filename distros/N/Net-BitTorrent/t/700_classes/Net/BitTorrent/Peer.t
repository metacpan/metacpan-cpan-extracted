#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Module::Build;
use Socket qw[AF_INET SOCK_STREAM INADDR_LOOPBACK SOL_SOCKET
    sockaddr_in unpack_sockaddr_in inet_ntoa];
use File::Temp qw[tempdir];
use Scalar::Util qw[/weak/];
use Time::HiRes qw[];
use lib q[../../../../lib];
use Net::BitTorrent;
use Net::BitTorrent::Torrent;
use Net::BitTorrent::Peer;
use Net::BitTorrent::Protocol qw[:all];
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../../] if not -f $simple_dot_torrent;
my $build           = Module::Build->current;
my $okay_tcp        = $build->notes(q[okay_tcp]);
my $release_testing = $build->notes(q[release_testing]);
my $verbose         = $build->notes(q[verbose]);
my $threads         = $build->notes(q[threads]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
my ($flux_capacitor, %peers) = (0, ());
plan tests => 91;

BEGIN {
    *CORE::GLOBAL::time
        = sub () { return CORE::time + ($flux_capacitor * 60); };
}
SKIP: {
    skip(
        q[Due to system configuration, tcp-related tests have been disabled.  ...which makes N::B pretty useless.],
        ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) if !$okay_tcp;

#skip(
#    q[Fine grained regression tests skipped; turn on $ENV{RELESE_TESTING} to enable],
#         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
#) if !$release_testing;
    my %client;

    END {
        for my $client (values %client) {
            for my $torrent (values %{$client->torrents}) {
                for my $file (@{$torrent->files}) {
                    if ($file->mode) {
                        warn sprintf q[Closing '%s'...], $file->path;
                        $file->_close();
                    }
                }
            }
        }
    }
    {    # Client A
        $client{q[A]} = Net::BitTorrent->new({LocalHost => q[127.0.0.1]});
        isa_ok($client{q[A]},
               q[Net::BitTorrent],
               sprintf(q[Client  A%s],
                       $client{q[A]}
                       ? q[ (pid:]
                           . $client{q[A]}->peerid
                           . q[, tcp:]
                           . $client{q[A]}->_tcp_port . q[)]
                       : q[])
        );

       #isa_ok($client{q[A]}->add_torrent({Path => $simple_dot_torrent,
       #                                   BaseDir =>
       #                                       tempdir(q[~NBSF_test_XXXXXXXX],
       #                                               CLEANUP => 1,
       #                                               TMPDIR  => 1
       #                                       )
       #                                  }
       #       ),
       #       q[Net::BitTorrent::Torrent],
       #       q[Torrent A]
       #);
        my ($_address,    # defined in peer_connect
            $_peer,       # defined in ip_filter
            $_read        # defined (and updated if needed) by peer_read
        );
        ok( $client{q[A]}->on_event(
                q[ip_filter],
                sub {
                    my ($self, $params) = @_;
                    is($self, $client{q[A]},
                        q[Object handed to callback matches what we expected [ip_filter]]
                    );
                    like($_address = delete($params->{q[Address]}),
                         qr[^(.+:\d+)$],
                         q[Params contain a properly formated 'Address' value [ip_filter]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [ip_filter]]
                    );
                }
            ),
            q[Set customized 'ip_filter' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[peer_write],
                sub {
                    my ($self, $params) = @_;
                    my ($explain) = explain $params;
                    die(q[We've sent a packet to a peer for reasons beyond me: ]
                            . $explain);
                }
            ),
            q[Set customized 'peer_write' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[peer_read],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[A]},
                        q[Object handed to callback matches what we expected [peer_read]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_read]]
                    );
                    like($_read += delete($params->{q[Length]}),
                         qr[^\d+$],
                         q[Params contains the 'Length' of data we read from this peer [peer_read]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_read]]
                    );
                    is($_peer->host . q[:] . $_peer->port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, undef,
                        q[Internal status: We have not parsed their peerid)]);
                    is($_peer->reserved_bytes, undef,
                        q[Internal status: We have not parsed their reserved bytes)]
                    );
                    is($_peer->torrent, undef,
                        q[Internal status: We have not parsed their infohash)]
                    );
                    is($_peer->bitfield, undef,
                        q[Internal status: We have not parsed their bitfield)]
                    );
                    isa_ok($_peer->_socket, q[GLOB],
                           q[Internal status: Peer has a socket (duh))]);
                }
            ),
            q[Set customized 'peer_read' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[peer_connect],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[A]},
                        q[Object handed to callback matches what we expected [peer_connect]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_connect]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_connect]]
                    );
                    is($_peer->host . q[:] . $_peer->port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, undef,
                        q[Internal status: We have not recieved their peerid)]
                    );
                    is($_peer->reserved_bytes, undef,
                        q[Internal status: We have not recieved their reserved bytes)]
                    );
                    is($_peer->torrent, undef,
                        q[Internal status: We have not recieved their infohash)]
                    );
                    is($_peer->bitfield, undef,
                        q[Internal status: We have not recieved their bitfield)]
                    );
                    isa_ok($_peer->_socket, q[GLOB],
                           q[Internal status: Peer has a socket (duh))]);
                }
            ),
            q[Set customized 'peer_connect' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[peer_disconnect],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[A]},
                        q[Object handed to callback matches what we expected [peer_disconnect]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_disconnect]]
                    );
                    is(delete($params->{q[Reason]}), -11,
                        q[Params contain a 'Reason' (-11: We aren't serving this torrent) [peer_disconnect]]
                    );
                    is_deeply(delete $params->{q[Advanced]},
                              {Infohash => unpack q[H40], (q[A] x 20)},
                              q[This particular disconnection comes with some 'Advanced' parameters [peer_disconnect]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_disconnect]]
                    );
                TODO: {
                        local $TODO = q[I may cache these in the future];
                        is( ($_peer->_host || q[]) . q[:]
                                . ($_peer->_port || q[]),
                            $_address,
                            q[Resolved host is as expected]
                        );
                    }
                    is($_peer->_am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->_peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->_am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->_peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->_incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->_source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, q[B] x 20,
                        q[Internal status: We have recieved their peerid)]);
                    is( $_peer->_reserved_bytes,
                        qq[\0] x 8,
                        q[Internal status: We have recieved their reserved bytes)]
                    );
                    is($_peer->_torrent, undef,
                        q[Internal status: We have not recieved their infohash)]
                    );
                    is($_peer->_bitfield, undef,
                        q[Internal status: We have not recieved their bitfield)]
                    );
                    is($_peer->_socket, undef,
                        q[Internal status: Peer no longer has a socket]);
                }
            ),
            q[Set customized 'peer_disconnect' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[outgoing_packet],
                sub {
                    my ($self, $params) = @_;
                    my ($explain) = explain $params;
                    die(q[We've sent a packet to a peer for reasons beyond me: ]
                            . $explain);
                }
            ),
            q[Set customized 'outgoing_packet' callback for Client A]
        );
        ok( $client{q[A]}->on_event(
                q[incoming_packet],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[A]},
                        q[Object handed to callback matches what we expected [incoming_packet]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [incoming_packet]]
                    );
                    is_deeply(delete $params->{q[Type]},
                              Net::BitTorrent::Peer::HANDSHAKE(),
                              q[We are (only) expecting a handshake from this peer [incoming_packet]]
                    );
                    is_deeply(delete $params->{q[Payload]},
                              {Infohash => q[A] x 20,
                               PeerID   => q[B] x 20,
                               Reserved => qq[\0] x 8,
                              },
                              q[Payload for this handshake is what we expected it to be [incoming_packet]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [incoming_packet]]
                    );
                    is($_peer->_host . q[:] . $_peer->_port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->_am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->_peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->_am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->_peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->_incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->_source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, q[B] x 20,
                        q[Internal status: We have recieved their peerid)]);
                    is( $_peer->_reserved_bytes,
                        qq[\0] x 8,
                        q[Internal status: We have recieved their reserved bytes)]
                    );
                    is($_peer->_torrent, undef,
                        q[Internal status: We have recieved their infohash but we aren't serving this torrent)]
                    );
                    is($_peer->_bitfield, undef,
                        q[Internal status: We have not recieved their bitfield (and never will))]
                    );
                    isa_ok($_peer->_socket,
                           q[GLOB],
                           q[Internal status: Peer (still) has a socket (for now))]
                    );
                }
            ),
            q[Set customized 'peer_connect' callback for Client A]
        );
        my $newsock_A = newsock($client{q[A]});
        $client{q[A]}->do_one_loop(1);
        is( syswrite($newsock_A,
                     build_handshake(chr(0) x 8, q[A] x 20, q[B] x 20)
            ),
            68,
            q[Send handshake to Client A]
        );
        for my $iteration (1 .. 10) {
            $client{q[A]}->do_one_loop(1);
            last if $_read == 68;
        }
        is($_read, 68, q[We read the entire handshake and nothing more]);
    }
    is($test_builder->{q[Curr_Test]},
        44, q[*** The test suite is on track after Client A]);
##############################################################################
    {    # Client B
        $client{q[B]} = Net::BitTorrent->new({LocalHost => q[127.0.0.1]});
        isa_ok($client{q[B]},
               q[Net::BitTorrent],
               sprintf(q[Client  A%s],
                       $client{q[B]}
                       ? q[ (pid:]
                           . $client{q[B]}->peerid
                           . q[, tcp:]
                           . $client{q[B]}->_tcp_port . q[)]
                       : q[])
        );
        isa_ok($client{q[B]}->add_torrent({Path => $simple_dot_torrent,
                                           BaseDir =>
                                               tempdir(q[~NBSF_test_XXXXXXXX],
                                                       CLEANUP => 1,
                                                       TMPDIR  => 1
                                               )
                                          }
               ),
               q[Net::BitTorrent::Torrent],
               q[Torrent B]
        );
        my ($_address,    # defined in peer_connect
            $_peer,       # defined in ip_filter
            $_read        # defined (and updated if needed) by peer_read
        );
        ok( $client{q[B]}->on_event(
                q[ip_filter],
                sub {
                    my ($self, $params) = @_;
                    is($self, $client{q[B]},
                        q[Object handed to callback matches what we expected [ip_filter]]
                    );
                    like($_address = delete($params->{q[Address]}),
                         qr[^(.+:\d+)$],
                         q[Params contain a properly formated 'Address' value [ip_filter]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [ip_filter]]
                    );
                }
            ),
            q[Set customized 'ip_filter' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[peer_write],
                sub {
                    my ($self, $params) = @_;
                    my ($explain) = explain $params;
                    die(q[We've sent a packet to a peer for reasons beyond me: ]
                            . $explain);
                }
            ),
            q[Set customized 'peer_write' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[peer_read],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[B]},
                        q[Object handed to callback matches what we expected [peer_read]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_read]]
                    );
                    like($_read += delete($params->{q[Length]}),
                         qr[^\d+$],
                         q[Params contains the 'Length' of data we read from this peer [peer_read]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_read]]
                    );
                    is($_peer->host . q[:] . $_peer->port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, undef,
                        q[Internal status: We have not parsed their peerid)]);
                    is($_peer->reserved_bytes, undef,
                        q[Internal status: We have not parsed their reserved bytes)]
                    );
                    is($_peer->torrent, undef,
                        q[Internal status: We have not parsed their infohash)]
                    );
                    is($_peer->bitfield, undef,
                        q[Internal status: We have not parsed their bitfield)]
                    );
                    isa_ok($_peer->_socket, q[GLOB],
                           q[Internal status: Peer has a socket (duh))]);
                }
            ),
            q[Set customized 'peer_read' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[peer_connect],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[B]},
                        q[Object handed to callback matches what we expected [peer_connect]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_connect]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_connect]]
                    );
                    is($_peer->host . q[:] . $_peer->port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, undef,
                        q[Internal status: We have not recieved their peerid)]
                    );
                    is($_peer->reserved_bytes, undef,
                        q[Internal status: We have not recieved their reserved bytes)]
                    );
                    is($_peer->torrent, undef,
                        q[Internal status: We have not recieved their infohash)]
                    );
                    is($_peer->bitfield, undef,
                        q[Internal status: We have not recieved their bitfield)]
                    );
                    isa_ok($_peer->_socket, q[GLOB],
                           q[Internal status: Peer has a socket (duh))]);
                }
            ),
            q[Set customized 'peer_connect' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[peer_disconnect],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[B]},
                        q[Object handed to callback matches what we expected [peer_disconnect]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [peer_disconnect]]
                    );
                    is(delete($params->{q[Reason]}), -13,
                        q[Params contain a 'Reason' (-13: We aren't serving this torrent) [peer_disconnect]]
                    );
                    is_deeply(delete $params->{q[Advanced]},
                              {Infohash => unpack q[H40], (q[A] x 20)},
                              q[This particular disconnection comes with some 'Advanced' parameters [peer_disconnect]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [peer_disconnect]]
                    );
                TODO: {
                        local $TODO = q[I may cache these in the future];
                        is( ($_peer->_host || q[]) . q[:]
                                . ($_peer->_port || q[]),
                            $_address,
                            q[Resolved host is as expected]
                        );
                    }
                    is($_peer->_am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->_peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->_am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->_peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->_incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->_source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, q[B] x 20,
                        q[Internal status: We have recieved their peerid)]);
                    is( $_peer->_reserved_bytes,
                        qq[\0] x 8,
                        q[Internal status: We have recieved their reserved bytes)]
                    );
                    is($_peer->_torrent, undef,
                        q[Internal status: We have not recieved their infohash)]
                    );
                    is($_peer->_bitfield, undef,
                        q[Internal status: We have not recieved their bitfield)]
                    );
                    is($_peer->_socket, undef,
                        q[Internal status: Peer no longer has a socket]);
                }
            ),
            q[Set customized 'peer_disconnect' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[outgoing_packet],
                sub {
                    my ($self, $params) = @_;
                    my ($explain) = explain $params;

                 #die(q[We've sent a packet to a peer for reasons beyond me: ]
                 #        . $explain);
                }
            ),
            q[Set customized 'outgoing_packet' callback for Client B]
        );
        ok( $client{q[B]}->on_event(
                q[incoming_packet],
                sub {
                    my ($self, $params) = @_;
                    is( $self,
                        $client{q[B]},
                        q[Object handed to callback matches what we expected [incoming_packet]],
                    );
                    isa_ok($_peer = delete($params->{q[Peer]}),
                           q[Net::BitTorrent::Peer],
                           q[Params contain a blessed N::B::Peer object in 'Peer' [incoming_packet]]
                    );
                    is_deeply(delete $params->{q[Type]},
                              Net::BitTorrent::Peer::HANDSHAKE(),
                              q[We are (only) expecting a handshake from this peer [incoming_packet]]
                    );
                    is_deeply(delete $params->{q[Payload]},
                              {Infohash =>
                                   pack(q[H40], (keys %{$self->torrents})[0]),
                               PeerID   => q[B] x 20,
                               Reserved => qq[\0] x 8,
                              },
                              q[Payload for this handshake is what we expected it to be [incoming_packet]]
                    );
                    is_deeply(
                        $params,
                        {},
                        q[Params contain no other data as exptexed [incoming_packet]]
                    );
                    is($_peer->_host . q[:] . $_peer->_port,
                        $_address, q[Resolved host is as expected]);
                    is($_peer->_am_choking, 1,
                        q[Initial status: Peer is choked]);
                    is($_peer->_peer_choking, 1,
                        q[Initial status: Peer is choking us]);
                    is($_peer->_am_interested, 0,
                        q[Initial status: Peer is not interesting]);
                    is($_peer->_peer_interested, 0,
                        q[Initial status: Peer is not interested]);
                    is($_peer->_incoming, 1,
                        q[Internal status: Peer initiated this connection (_incoming())]
                    );
                    is($_peer->_source, q[Incoming],
                        q[Internal status: Peer initiated this connection (_source())]
                    );
                    is($_peer->peerid, q[B] x 20,
                        q[Internal status: We have recieved their peerid)]);
                    is( $_peer->_reserved_bytes,
                        qq[\0] x 8,
                        q[Internal status: We have recieved their reserved bytes)]
                    );
                    is($_peer->_torrent, undef,
                        q[Internal status: We have recieved their infohash but we aren't serving this torrent)]
                    );
                    is($_peer->_bitfield, undef,
                        q[Internal status: We have not recieved their bitfield (and never will))]
                    );
                    isa_ok($_peer->_socket,
                           q[GLOB],
                           q[Internal status: Peer (still) has a socket (for now))]
                    );
                }
            ),
            q[Set customized 'peer_connect' callback for Client B]
        );
        my $newsock_A = newsock($client{q[B]});
        $client{q[B]}->do_one_loop(1);
        is( syswrite($newsock_A,
                     build_handshake(
                                   chr(0) x 8,
                                   pack(q[H40],
                                        (keys %{$client{q[B]}->torrents})[0]),
                                   q[B] x 20
                     )
            ),
            68,
            q[Send handshake to Client B]
        );
        for my $iteration (1 .. 10) {
            $client{q[B]}->do_one_loop(1);
            last if $_read == 68;
        }
        is($_read, 68, q[We read the entire handshake and nothing more]);
    }
    is($test_builder->{q[Curr_Test]},
        90, q[*** The test suite is on track after Client B]);

=old


    ok( $client->on_event(
            q[peer_read],
            sub {
                my ($self, $args) = @_;
                is($self, $client,
                    q[Correct args passed to 'peer_read' [$_[0]]]);
                isa_ok($args->{q[Peer]}, q[Net::BitTorrent::Peer],
                       q[  ... [$_[1]->{'Peer'}]]);
                like($args->{q[Length]}, qr[^\d+$],
                     q[  ... [$_[1]->{'Length'}]]);
                my $peer = $args->{q[Peer]};
                delete $args->{q[Peer]};
                my $_len = $args->{q[Length]};
                delete $args->{q[Length]};
                is_deeply($args, {}, q[  ... No other keys in $_[1]]);
                warn(sprintf(q[Read %d bytes from '%s'],
                             $_len, $peer->as_string
                     )
                );
            }
        ),
        q[Installed 'peer_read' event handler]
    );
    ok( $client->on_event(
            q[peer_write],
            sub {
                my ($self, $args) = @_;
                is($self, $client,
                    q[Correct args passed to 'peer_read' [$_[0]]]);
                isa_ok($args->{q[Peer]}, q[Net::BitTorrent::Peer],
                       q[  ... [$_[1]->{'Peer'}]]);
                like($args->{q[Length]}, qr[^\d+$],
                     q[  ... [$_[1]->{'Length'}]]);
                my $peer = $args->{q[Peer]};
                delete $args->{q[Peer]};
                my $_len = $args->{q[Length]};
                delete $args->{q[Length]};
                is_deeply($args, {}, q[  ... No other keys in $_[1]]);
                warn(sprintf(q[Wrote %d bytes from '%s'],
                             $_len, $peer->as_string
                     )
                );
            }
        ),
        q[Installed 'peer_write' event handler]
    );
    ok( $client->on_event(
            q[peer_disconnect],
            sub {
                my ($self, $args) = @_;
                is($self, $client,
                    q[Correct args passed to 'peer_disconnect' [$_[0]]]);
                isa_ok($args->{q[Peer]}, q[Net::BitTorrent::Peer],
                       q[  ... [$_[1]->{'Peer'}]]);
                ok(defined($args->{q[Reason]}), q[  ... [$_[1]->{'Reason'}]]);
                my $peer = $args->{q[Peer]};
                delete $args->{q[Peer]};
                my $_why = $args->{q[Reason]};
                delete $args->{q[Reason]};
                is_deeply($args, {}, q[  ... No other keys in $_[1]]);
                warn(sprintf(q[Disconnected from '%s'%s],
                             $peer->as_string,
                             ($_why
                              ? (q[ (] . $_why . q[)])
                              : q[]
                             )
                     )
                );
            }
        ),
        q[Installed 'peer_disconnect' event handler]
    );
    ok( $client->on_event(
            q[peer_connect],
            sub {
                my ($self, $args) = @_;
                is($self, $client,
                    q[Correct args passed to 'peer_connect' [$_[0]]]);
                isa_ok($args->{q[Peer]}, q[Net::BitTorrent::Peer],
                       q[  ... [$_[1]->{'Peer'}]]);
                my $peer = $args->{q[Peer]};
                delete $args->{q[Peer]};
                is_deeply($args, {}, q[  ... No other keys in $_[1]]);
                like($peer->_host . q[:] . $peer->_port,
                     qr[127.0.0.1:\d+],
                     sprintf q[%s connection %s '%s'],
                     ($peer->_incoming ? q[Incoming] : q[Outgoing]),
                     ($peer->_incoming ? q[from]     : q[to]),
                     $peer->as_string
                );
                return 1;
            }
        ),
        q[Installed 'peer_connect' event handler]
    );
    my @request_offsets = qw[0     16384 0     16384 16344 16354];
    my @request_lengths = qw[16384 16384 16384 16384 16384 46384];
    my @cancel_offsets  = reverse @request_offsets;
    my @indexes         = (0 .. 10);                                 # have
    ok( $client->on_event(
            q[incoming_packet],
            sub {
                my ($self, $args) = @_;
                my $type    = $args->{q[Type]};
                my $peer    = $args->{q[Peer]};
                my $payload = $args->{q[Payload]};
                if ($type eq KEEPALIVE) {
                    warn q[TODO: keepalive];
                }
                elsif ($type == HANDSHAKE) {
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_handshake' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    is(scalar(keys %{$args->{'Payload'}}),
                        3, q[  ... scalar(keys %{$payload})]);
                    is(length($args->{'Payload'}{q[Reserved]}),
                        8, q[  ... reserved conforms to spec]);
                    is(length($args->{'Payload'}{q[Infohash]}),
                        20, q[  ... infohash conforms to spec]);
                    is(length($args->{'Payload'}{q[PeerID]}),
                        20, q[  ... peerid conforms to spec]);
                    delete $args->{q[Peer]};
                    my $_len = $args->{q[Payload]};
                    delete $args->{q[Payload]};
                    is_deeply($args,
                              {Type => HANDSHAKE},
                              q[  ... No other keys in $_[1]]);

                    if (   ($peer->peerid eq q[B] x 20)
                        or ($peer->peerid eq q[C] x 20)
                        or ($peer->peerid eq q[UNKNOWN-------------]))
                    {   pass(sprintf q[PeerID is okay (%s)], $peer->peerid);
                    }
                    elsif ($peer->peerid eq $self->peerid) {
                        pass(sprintf q[Peerid match: %s eq %s],
                             $self->peerid, $peer->peerid);
                    }
                    else {
                        die(sprintf q[Unknown peerid: %s], $peer->peerid);
                    }
                }
                elsif ($type == CHOKE) {
                    my ($self, $args) = @_;
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_choke' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Payload => {}, Type => CHOKE},
                              q[  ... No other keys in $_[1]]);
                    is($peer->peerid, q[C] x 20, q[Choked by 'CC..CC']);
                }
                elsif ($type == UNCHOKE) {
                    my ($self, $args) = @_;
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_unchoke' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Payload => {}, Type => UNCHOKE},
                              q[  ... No other keys in $_[1]]);
                    is($peer->peerid, q[C] x 20, q[Unchoked by 'CC..CC']);
                }
                elsif ($type == INTERESTED) {
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_unchoke' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Payload => {}, Type => INTERESTED},
                              q[  ... No other keys in $_[1]]);
                    warn(
                        sprintf(q[%s is interested in me], $peer->as_string));
                }
                elsif ($type == NOT_INTERESTED) {
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_unchoke' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Payload => {}, Type => NOT_INTERESTED},
                              q[  ... No other keys in $_[1]]);
                    warn(
                        sprintf(q[%s is interested in me], $peer->as_string));
                }
                elsif ($type == HAVE) {
                    delete $_[1]->{q[Peer]};
                    is_deeply(\@_,
                              [$client,
                               {Payload => {Index => shift(@indexes)},
                                Type    => HAVE
                               }
                              ],
                              q[Correct arguments passed to 'packet_incoming_have' event handler]
                    );
                    if ($peer->peerid eq q[C] x 20) {
                        if ($payload->{q[Index]} == 0) {
                            pass(q[Good peer has i:0]);
                        }
                        elsif ($payload->{q[Index]} == 1) {
                            pass(q[Good peer has i:1]);
                        }
                        else {
                            die(sprintf q[Peer claims to have %d],
                                 $payload->{q[Index]});
                        }
                    }
                    else {
                        die(sprintf q[Unknown peer '%s' has %d],
                             $peer->peerid, $args->{q[Index]});
                    }
                }
                elsif ($type == BITFIELD) {
                    is($self, $client,
                        q[Correct args passed to 'packet_incoming_bitfield' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Type    => BITFIELD,
                               Payload => {}
                              },
                              q[  ... No other keys in $_[1]]
                    );
                    if (   ($peer->peerid eq q[B] x 20)
                        or ($peer->peerid eq q[C] x 20))
                    {   pass(sprintf q[PeerID is okay (%s)], $peer->peerid);
                    }
                    elsif ($peer->peerid eq $self->peerid) {
                        pass(sprintf q[Peerid match: %s eq %s],
                             $self->peerid, $peer->peerid);
                    }
                    else {
                        die(sprintf q[Unknown peerid: %s], $peer->peerid);
                    }
                    warn(sprintf(q[Bitfield from %s], $peer->as_string));
                }
                elsif ($type == REQUEST) {
                    warn sprintf q[%s is requesting [I:%4d O:%6d L:%6d]],
                        $peer->as_string,
                        $payload->{q[Index]},
                        $payload->{q[Offset]},
                        $payload->{q[Length]};
                }
                elsif ($type == PIECE) {
                    delete $_[1]->{q[Peer]};
                    is_deeply(\@_,
                              [$client,
                               {Payload => {Index  => 0,
                                            Length => 16384,
                                            Offset => 0
                                },
                                Type => PIECE
                               }
                              ],
                              q[Correct args passed to 'packet_incoming_block' event handler]
                    );
                    is($peer->_torrent->downloaded,
                        16384, q[Torrent downloaded amount updated]);
                    warn(
                        sprintf
                            q[%s sent us [I:%4d O:%6d L:%6d] I have now downloaded %d bytes],
                        $peer->as_string,      $payload->{q[Index]},
                        $payload->{q[Offset]}, $payload->{q[Length]},
                        $peer->_torrent->downloaded
                    );
                }
                elsif ($type == CANCEL) {
                    ok( 1,
                        sprintf q[%s has canceled [I:%4d O:%6d L:%6d]],
                        $peer->as_string,
                        $args->{q[Index]},
                        $args->{q[Offset]},
                        $args->{q[Length]}
                    );
                }
                elsif ($type == HAVE_ALL) {
                    ok(1, sprintf q[%s says they have everything],
                        $peer->as_string);
                }
                elsif ($type == HAVE_NONE) {
                    ok(1, sprintf q[%s says they have nothing],
                        $peer->as_string);
                }
                else { die q[Unhandled packet: ] . $type }
            }
        ),
        q[Installed 'incoming_packet' event handler (TODO)]
    );
    ok( $client->on_event(
            q[outgoing_packet],
            sub {
                my ($self, $args) = @_;
                my $type    = $args->{q[Type]};
                my $peer    = $args->{q[Peer]};
                my $payload = $args->{q[Payload]};
                if ($type == HANDSHAKE) {
                    is($self, $client,
                        q[Correct args passed for outgoing handshake [$_[0]]]
                    );
                    isa_ok($peer, q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]);
                    is(scalar(keys %{$payload}),
                        3, q[  ... scalar(@{$payload})]);
                    is(length($payload->{q[Reserved]}), 8,
                        q[  ... [length($payload->{q[Reserved]}) ==  8] (reserved)]
                    );
                    is(length($payload->{q[Infohash]}), 20,
                        q[  ... [length($payload->{q[Infohash]}) == 20] (infohash)]
                    );
                    is(length($payload->{q[PeerID]}), 20,
                        q[  ... [length($payload->{q[PeerID]}) == 20] (peerid)]
                    );
                    delete $args->{q[Peer]};
                    my $_len = $args->{q[Payload]};
                    delete $args->{q[Payload]};
                    is_deeply($args,
                              {Type => HANDSHAKE},
                              q[  ... No other keys in $_[1]]);

                    if ($peer->_incoming) {
                        if (   ($peer->peerid eq q[B] x 20)
                            or ($peer->peerid eq q[C] x 20)
                            or ($peer->peerid eq q[UNKNOWN-------------]))
                        {   pass(sprintf q[PeerID is okay (%s)],
                                 $peer->peerid);
                        }
                        elsif ($peer->peerid eq $self->peerid) {
                            pass(sprintf q[Peerid match: %s eq %s],
                                 $self->peerid, $peer->peerid);
                        }
                        else {
                            die(sprintf q[Unknown peerid: %s],
                                 $peer->peerid);
                        }
                    }
                }
                elsif ($type == UNCHOKE) {
                    my ($self, $args) = @_;
                    is($self, $client,
                        q[Correct args passed to 'outgoing unchoke' [$_[0]]]);
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Payload => {}, Type => UNCHOKE},
                              q[  ... No other keys in $_[1]]);
                    warn(sprintf(q[Unchoking %s], $peer->as_string));
                }
                elsif ($type == REQUEST) {
                    warn(sprintf q[Requesting [I:%4d O:%6d L:%6d] from %s],
                         $payload->{q[Index]},  $payload->{q[Offset]},
                         $payload->{q[Length]}, $peer->as_string
                    );
                    is($self, $client,
                        q[Correct args passed to 'outgoing request' [$_[0]]]);
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    like($args->{q[Payload]}{q[Index]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Index'}]]);
                    delete $args->{q[Payload]}{q[Index]};
                    like($args->{q[Payload]}{q[Offset]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Offset'}]]);
                    delete $args->{q[Payload]}{q[Offset]};
                    like($args->{q[Payload]}{q[Length]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Length'}]]);
                    delete $args->{q[Payload]}{q[Length]};
                    is_deeply($args,
                              {Payload => {}, Type => REQUEST},
                              q[Correct args passed to 'outgoing request' event handler]
                    );
                }
                elsif ($type == CANCEL) {
                    is($self, $client,
                        q[Correct args passed to 'outgoing cancel' [$_[0]]]);
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    like($args->{q[Payload]}{q[Index]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Index'}]]);
                    delete $args->{q[Payload]}{q[Index]};
                    like($args->{q[Payload]}{q[Offset]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Offset'}]]);
                    delete $args->{q[Payload]}{q[Offset]};
                    like($args->{q[Payload]}{q[Length]},
                         qr[^\d+$], q[  ... [$_[1]->{'Payload'}{'Length'}]]);
                    delete $args->{q[Payload]}{q[Length]};
                    is_deeply($args,
                              {Payload => {}, Type => CANCEL},
                              q[Correct args passed to 'outgoing cancel' event handler]
                    );
                    warn(sprintf q[Canceling [I:%4d O:%6d L:%6d] from %s],
                         $payload->{q[Index]},  $payload->{q[Offset]},
                         $payload->{q[Length]}, $peer->as_string
                    );
                }
                elsif ($type == PIECE) {
                    warn sprintf
                        q[Sending [I:%4d O:%6d L:%6d] to %s. I have now uploaded %d bytes],
                        $payload->{q[Index]},
                        $payload->{q[Offset]},
                        $payload->{q[Length]},
                        $peer->as_string,
                        $peer->_torrent->uploaded;
                }
                elsif ($type == INTERESTED) {
                    my ($self, $args) = @_;
                    is($self, $client,
                        q[Correct args passed to 'outgoing interested' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Type => INTERESTED, Payload => {}},
                              q[  ... No other keys in $_[1]]);
                    warn(sprintf(q[I am interested in %s], $peer->as_string));
                }
                elsif ($type == CHOKE) {
                    warn sprintf q[ ===> Choking %s], $peer->as_string;
                }
                elsif ($type == BITFIELD) {
                    is($self, $client,
                        q[Correct args passed to 'outgoing bitfield' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Type => BITFIELD},
                              q[  ... No other keys in $_[1]]);
                    warn(sprintf(q[Sent bitfield to %s], $peer->as_string));
                }
                elsif ($type == HAVE_NONE) {
                    is($self, $client,
                        q[Correct args passed to 'outgoing have none' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    is_deeply($args,
                              {Type => HAVE_NONE, Payload => {}},
                              q[  ... No other keys in $_[1]]);
                }
                elsif ($type == EXTPROTOCOL) {
                    is($self, $client,
                        q[Correct args passed to 'outgoing extended protocol' [$_[0]]]
                    );
                    isa_ok($args->{q[Peer]},
                           q[Net::BitTorrent::Peer],
                           q[  ... [$_[1]->{'Peer'}]]
                    );
                    delete $args->{q[Peer]};
                    delete $args->{q[Payload]};
                    delete $args->{q[ID]};
                    is_deeply($args,
                              {Type => EXTPROTOCOL},
                              q[  ... No other keys in $_[1]]);
                }
                else { warn q[****************** Unhandled packet: ] . $type }
            }
        ),
        q[Installed 'outgoing_packet' event handler]
    );
    ok( $client->on_event(
            q[ip_filter],
            sub {
                my ($self, $args) = @_;
                is($self, $client,
                    q[Correct params passed to 'ip_filter' ($_[0])]);
            TODO: {
                    local $TODO = q[Temporary DHT boot node breaks this test];
                    like(
                        $args->{q[Address]},   # XXX - removed for DHT testing
                        qr[^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$],
                        q[  ... ($_[1]->{'Address'})]
                    );
                }
                my $address = $args->{'Address'};
                delete $args->{'Address'};
                is_deeply(
                    $args,
                    {},
                    q[Correct params passed to 'ip_filter' (  ... No other keys in $_[1])]
                );
                warn(sprintf(q[Check IP filter for %s], $address));
                return 1;
            }
        ),
        q[Installed 'ip_filter' event handler]
    );
    warn sprintf q[%d|%d], 7, $test_builder->{q[Curr_Test]};
    warn(q[Net::BitTorrent::Peer->new() requires params...]);
    is(Net::BitTorrent::Peer->new(),   undef, q[No params]);
    is(Net::BitTorrent::Peer->new({}), undef, q[Empty hashref]);
    is(Net::BitTorrent::Peer->new({Socket => undef}),
        undef, q[Socket => undef]);
    is(Net::BitTorrent::Peer->new({Socket => 0}), undef, q[Socket => 0]);
    is(Net::BitTorrent::Peer->new({Socket => bless {}, q[GLOB]}),
        undef, q[Missing Client]);
    is( Net::BitTorrent::Peer->new({Socket => bless({}, q[GLOB]), Client => 0}
        ),
        undef,
        q[Client => 0]
    );
    is( Net::BitTorrent::Peer->new({Socket => bless(\{}, q[GLOB]),
                                    Client => bless(\{}, q[junk])
                                   }
        ),
        undef,
        q[Client => bless \{}, 'junk']
    );
    warn sprintf q[%d|%d], 14, $test_builder->{q[Curr_Test]};
    warn(q[For this next bit, we're testing outgoing peers...]);
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => $torrent,
                                    Address => q[junk]
                                   }
        ),
        undef,
        q[Address => 'junk']
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => $torrent,
                                    Address => undef
                                   }
        ),
        undef,
        q[Address => undef]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[Missing Torrent]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => undef,
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[Torrent => undef]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => 0,
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[Torrent => 0]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => 'junk',
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[Torrent => 'junk']
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => bless(\{}, 'junk'),
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[Torrent => bless(\{}, 'junk')]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => $torrent,
                                    Address => q[127.0.0.1:0]
                                   }
        ),
        undef,
        q[No Source]
    );
    is( Net::BitTorrent::Peer->new({Client  => $client,
                                    Torrent => $torrent,
                                    Address => q[127.0.0.1:0],
                                    Source  => undef
                                   }
        ),
        undef,
        q[Source => undef]
    );
    warn sprintf q[%d|%d], 21, $test_builder->{q[Curr_Test]};
    warn(q[Test incoming peers]);
    {
        $peers{q[A]} =
            Net::BitTorrent::Peer->new({Client  => $client,
                                        Torrent => $torrent,
                                        Address => q[127.0.0.1:0],
                                        Source  => q[User]
                                       }
            );
        isa_ok($peers{q[A]}, q[Net::BitTorrent::Peer], q[new()]);
        weaken $peers{q[A]};
        ok(isweak($peers{q[A]}),    q[  ...make $peers{q[A]} a weak ref]);
        ok($peers{q[A]}->as_string, q[as_string]);
        is($peers{q[A]}->as_string,
            $peers{q[A]}->as_string(0),
            q[as_string() vs as_string(0)]);
        isn't($peers{q[A]}->as_string,
              $peers{q[A]}->as_string(1),
              q[as_string() vs as_string(1)]);
        sub TIEHANDLE { pass(q[Tied STDERR]); bless \{}, shift; }

        sub PRINT {
            is((caller(0))[0],
                q[Net::BitTorrent::Peer], q[String written to STDERR]);
        }
        sub UNTIE { pass(q[Untied STDERR]); }
        tie(*STDERR, __PACKAGE__);
        $peers{q[A]}->as_string;
        $peers{q[A]}->as_string(1);
        untie *STDERR;
        isa_ok($peers{q[A]}->_socket, q[GLOB], q[_socket]);
        isa_ok($peers{q[A]}->_torrent,
               q[Net::BitTorrent::Torrent], q[_torrent]);
        is($peers{q[A]}->_bitfield,     "\0", q[_bitfield]);
        is($peers{q[A]}->_peer_choking, 1,    q[Default peer_choking status]);
        is($peers{q[A]}->_am_choking,   1,    q[Default am_choking status]);
        is($peers{q[A]}->_peer_interested,
            0, q[Default peer_interested status]);
        is($peers{q[A]}->_am_interested, 0, q[Default am_interested status]);
        is($peers{q[A]}->_incoming,      0, q[Direction status is correct.]);
        warn sprintf q[%d|%d], 39, $test_builder->{q[Curr_Test]};
    }
    {
        my $newsock_A = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 44, $test_builder->{q[Curr_Test]};
        is( syswrite($newsock_A,
                     build_handshake(chr(0) x 8, q[A] x 20, q[B] x 20)
            ),
            68,
            q[Sent handshake to client]
        );
        my $with_peer = scalar keys %{$client->_connections};
        is(syswrite($newsock_A, build_bitfield(chr(1))),
            6, q[Sent bitfield to client]);
        is(syswrite($newsock_A, build_bitfield(chr(0))),
            6, q[Sent bitfield to client]);
        is(syswrite($newsock_A, build_bitfield(chr(0))),
            6, q[Sent bitfield to client]);
        is(syswrite($newsock_A, build_bitfield(chr(0))),
            6, q[Sent bitfield to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ok(($with_peer > scalar keys %{$client->_connections}),
            q[Peer removed from list of connections]);
        warn sprintf q[%d|%d], 71, $test_builder->{q[Curr_Test]};
    }
    {
        my $newsock_B = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is( syswrite($newsock_B,
                     build_handshake(chr(0) x 8,
                                     pack(q[H40], $torrent->infohash),
                                     $client->peerid
                     )
            ),
            68,
            q[Sent handshake to client]
        );
        my $with_peer = scalar keys %{$client->_connections};
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ok(($with_peer > scalar keys %{$client->_connections}),
            q[Peer removed from list of connections]);
        warn sprintf q[%d|%d], 99, $test_builder->{q[Curr_Test]};
    }
    {
        my $newsock_C = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is( syswrite($newsock_C,
                     build_handshake(chr(0) x 8,
                                     pack(q[H40], $torrent->infohash),
                                     q[C] x 20
                     )
            ),
            68,
            q[Sent handshake to client]
        );
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ($peers{q[C]}) = map {
            (    $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
             and defined $_->{q[Object]}->peerid
             and ($_->{q[Object]}->peerid eq q[C] x 20))
                ? $_->{q[Object]}
                : ()
        } values %{$client->_connections};
        weaken $peers{q[C]};
        ok(isweak($peers{q[C]}), q[  ...make $peers{q[C]} a weak ref]);
        warn sprintf q[%d|%d], 131, $test_builder->{q[Curr_Test]};
        like(${$peers{q[C]}}, qr[127.0.0.1:\d+],
             q[Address properly resolved]);
        is($peers{q[C]}->_host, q[127.0.0.1], q[_host]);
        like($peers{q[C]}->_port, qr[^\d+$], q[_port]);
        is($peers{q[C]}->peerid, q[C] x 20, q[PeerID check]);
        isa_ok($peers{q[C]}->_socket, q[GLOB], q[Socket stored properly]);
        warn sprintf q[%d|%d], 136, $test_builder->{q[Curr_Test]};
        is($peers{q[C]}->_am_choking,      1, q[Initial outgoing choke]);
        is($peers{q[C]}->_peer_choking,    1, q[Initial incoming choke]);
        is($peers{q[C]}->_am_interested,   0, q[Initial outgoing interest]);
        is($peers{q[C]}->_peer_interested, 0, q[Initial incoming interest]);

        ok(syswrite($newsock_C, build_interested), q[Incoming interested]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is($peers{q[C]}->_peer_interested, 1, q[Peer is interested]);

        ok(syswrite($newsock_C, build_unchoke), q[Incoming unchoke]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is($peers{q[C]}->_peer_choking, 0, q[Peer has unchoked us]);
        warn sprintf q[%d|%d], 172, $test_builder->{q[Curr_Test]};

        ok(syswrite($newsock_C, build_choke), q[Incoming choke]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is($peers{q[C]}->_peer_choking,
            1, q[Post-choke incoming choke status]);
        is($peers{q[C]}->_am_interested,
            0, q[Post-choke outgoing interest status]);
        warn sprintf q[%d|%d], 184, $test_builder->{q[Curr_Test]};
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is($peers{q[C]}->_am_choking,
            0, q[Post-interested outgoing choke status]);
        warn sprintf q[%d|%d], 186, $test_builder->{q[Curr_Test]};
        is($peers{q[C]}->_peer_choking,
            1, q[Post-interested incoming choke status]);
        is($peers{q[C]}->_am_interested,
            0, q[Post-interested outgoing interest status]);
        $client->do_one_loop(0);
        is($peers{q[C]}->_peer_interested,
            1, q[Post-interested incoming interest status]);
        warn sprintf q[%d|%d], 189, $test_builder->{q[Curr_Test]};
        ok(shutdown($newsock_C, 2),
            q[Peer closes socket. Leaving us hanging.]);
        my $with_peer = scalar keys %{$client->_connections};
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ok(($with_peer > scalar keys %{$client->_connections}),
            q[Peer removed from list of connections]);
        warn sprintf q[%d|%d], 196, $test_builder->{q[Curr_Test]};
    }
    {
        my $newsock_D = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is( syswrite($newsock_D,
                     build_handshake(qq[\0\0\0\0\0\20\0\4],
                                     pack(q[H40], $torrent->infohash),
                                     q[C] x 20
                     )
            ),
            68,
            q[Sent handshake to client]
        );
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        my $data = q[];

        #ok(sysread($newsock_D, $data, 68), q[Read handshake reply]);
        warn sprintf q[%d|%d], 233, $test_builder->{q[Curr_Test]};
        is(syswrite($newsock_D, build_keepalive()),
            4, q[Sent keepalive to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_D, build_unchoke()),
            5, q[Sent unchoke to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 253, $test_builder->{q[Curr_Test]};
        is(syswrite($newsock_D, build_choke()), 5, q[Sent choke to client]);
        is(syswrite($newsock_D, build_not_interested()),
            5, q[Sent not interested to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_D, build_have(0)), 9, q[Sent have to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ok(sysread($newsock_D, $data, 1024, length $data), q[Read]);
        warn sprintf q[%d|%d], 279, $test_builder->{q[Curr_Test]};
        is(syswrite($newsock_D, build_unchoke()),
            5, q[Sent unchoke to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        ok(sysread($newsock_D, $data, 1024, length $data), q[Read]);
        my $fake_piece = q[A] x 16384;
        is(syswrite($newsock_D, build_piece(0, 0, \$fake_piece)),
            16397, q[Sent piece i:0 o:0 l:16384 to client]);
        warn sprintf q[%d|%d], 307, $test_builder->{q[Curr_Test]};
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_D, build_choke()), 5, q[Sent choke to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_D, build_unchoke()),
            5, q[Sent choke to client to read second unchoke]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 344, $test_builder->{q[Curr_Test]};
        $flux_capacitor = 0.5;
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 349, $test_builder->{q[Curr_Test]};
        $flux_capacitor = 1;
        ok($client->do_one_loop(3), q[    do_one_loop(3)]);
        ok(sysread($newsock_D, $data, 1024, length $data), q[Read]);
        warn sprintf q[%d|%d], 351, $test_builder->{q[Curr_Test]};
        ok(syswrite($newsock_D, build_keepalive()), q[Write keepalive]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_D, build_interested()),
            5, q[Sent interested to client]);
        $flux_capacitor = 2.5;
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);

        #is(sysread($newsock_D, my ($in), 1024),
        #    undef, q[Fail to read data because socket was closed.]);
        #ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn q[TODO: Test multithreaded stuff...];
    }
    {
        my $newsock_E = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is( syswrite($newsock_E,
                     build_handshake(qq[\0\0\0\0\0\0\0\4],
                                     pack(q[H40], $torrent->infohash),
                                     q[UNKNOWN-------------]
                     )
            ),
            68,
            q[Sent handshake to client]
        );
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_E, build_have_all()),
            5, q[Sent HAVEALL to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 425, $test_builder->{q[Curr_Test]};
    }
    {
        my $newsock_F = newsock($client);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is( syswrite($newsock_F,
                     build_handshake(qq[\0\0\0\0\0\0\0\4],
                                     pack(q[H40], $torrent->infohash),
                                     q[UNKNOWN-------------]
                     )
            ),
            68,
            q[Sent handshake to client]
        );
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        is(syswrite($newsock_F, build_have_none()),
            5, q[Sent HAVEALL to client]);
        ok($client->do_one_loop(1), q[    do_one_loop(1)]);
        warn sprintf q[%d|%d], 474, $test_builder->{q[Curr_Test]};
    }
=cut
}

sub newsock {
    my ($server) = @_;
    my ($port, $packed_ip) = unpack_sockaddr_in(getsockname($server->_tcp));
    my $outgoing;
    socket($outgoing, AF_INET, SOCK_STREAM, getprotobyname(q[tcp]))
        ? do {
        warn(sprintf q[Creating new sockpair to connect to %s:%d (%s)],
             inet_ntoa($packed_ip), $port, $server->peerid);
        connect($outgoing, getsockname($server->_tcp));
        }
        : die(
            sprintf q[Failed to create new sockpair to connect to %s:%d (%s)],
            inet_ntoa($packed_ip), $port, $server->peerid);
    return $outgoing;
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

$Id: Peer.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
