#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Module::Build;
use Time::HiRes qw[];
use File::Temp qw[tempdir];
use Scalar::Util qw[/weak/];
use Socket
    qw[/pack_sockaddr_in/ /inet_/ PF_INET SOCK_STREAM SOL_SOCKET SOMAXCONN];
use lib q[../../../lib];
use Net::BitTorrent;
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../] if not -f $simple_dot_torrent;
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
plan tests => 89;
my ($tempdir) = tempdir(q[~NBSF_test_XXXXXXXX], CLEANUP => 1, TMPDIR => 1);
warn(sprintf(q[File::Temp created '%s' for us to play with], $tempdir));
my $torrent;

END {
    return if not defined $torrent;
    for my $file (@{$torrent->files}) { $file->_close() }
}
my $client = Net::BitTorrent->new({LocalHost => q[127.0.0.1]});
skip(q[Failed to create client],
     ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]}))
    if !$client;
warn(q[TODO: Install event handlers]);
is(length($client->_build_reserved()), 8, q[_build_reserved()]);
is($client->_max_ul_rate, 0, q[_max_ul_rate is unlimited by default]);
is($client->_max_dl_rate, 0, q[_max_dl_rate is unlimited by default]);
ok($client->_set_max_ul_rate(16), q[_set_max_ul_rate(16)]);
ok($client->_set_max_dl_rate(16), q[_set_max_dl_rate(16)]);
is($client->_max_ul_rate,  16,    q[_max_ul_rate is now 16Bps]);
is($client->_max_dl_rate,  16,    q[_max_dl_rate is now 16Bps]);
is($client->_schedule(),   undef, q[_schedule() is undef]);
is($client->_schedule({}), undef, q[_schedule({}) is undef]);
my $tmp = q[Random::Package];
ok( $client->_schedule(
        {Object => bless(\$tmp, $tmp),
         Time   => time,
         Code   => sub {
             ok(1, q[Random::Package's scheduled ping]);
             }
        }
    ),
    q[_schedule({Object => [...], Time => time, Code => sub{ [...] }})]
);
my $event = $client->_schedule(
    {Object => bless(\{}, $tmp),
     Time   => time,
     Code   => sub {
         fail(q[This event should have been canceled]);
         }
    }
);
ok($client->_cancel($event), q[_cancel([...])]);
ok($client->do_one_loop(1),  q[do_one_loop]);
SKIP: {
    skip(q[TCP-based tests have been disabled.], 14) if not $okay_tcp;
    ok($client->_socket_open_tcp(),  q[_socket_open_tcp()]);
    ok($client->_socket_open_tcp(0), q[_socket_open_tcp(0)]);
    ok($client->_socket_open_tcp(undef, 0), q[_socket_open_tcp(undef, 0)]);
    ok($client->_socket_open_tcp(undef, undef),
        q[_socket_open_tcp(undef, undef)]);
    is($client->_socket_open_tcp(inet_aton(q[127.0.0.1]), q[test]),
        undef,
        q[_socket_open_tcp(inet_aton(q[127.0.0.1]), q[test]) returns undef]);
SKIP: {
        skip 'This does not work as expected on irix', 1 if $^O =~ m[irix]i;
        is($client->_socket_open_tcp({}),
            undef, q[_socket_open_tcp({}) returns undef]);
    }
    is($client->_socket_open_tcp(q[127.0.0.1:25012]),
        undef, q[_socket_open_tcp(q[127.0.0.1:25012]) returns undef]);
    ok($client->_socket_open_tcp(q[127.0.0.1], 0),
        q[_socket_open_tcp('127.0.0.1', 0)]);
    isa_ok($client->_tcp, q[GLOB], q[TCP is good]);
    ok($client->_tcp_host, q[_tcp_host]);
    ok($client->_tcp_port, q[_tcp_port]);
    warn(q[ [Alpha] _socket_open_tcp() and new() accept textual]);
    warn(q[         hostnames ('localhost', 'ganchan.somewhere.net', etc.)]);
    warn(q[         which are automatically resolved.]);
    ok($client->_socket_open_tcp(q[localhost], 0),
        q[_socket_open_tcp('localhost', 0) [Undocumented]]);
    my ($port_one, $packed_ip_one)
        = unpack_sockaddr_in(getsockname($client->_tcp));
    like($port_one,
         qr[\d+],
         sprintf(q[   ...which would accept connections on port %d...],
                 $port_one)
    );
    is($packed_ip_one, inet_aton(q[127.0.0.1]),
        q[   ...if it were open to the outside world.]);
}
SKIP: {
    skip(q[UDP-based tests have been disabled.], 14) if not $okay_udp;
    ok($client->_socket_open_udp(),  q[_socket_open_udp()]);
    ok($client->_socket_open_udp(0), q[_socket_open_udp(0)]);
    ok($client->_socket_open_udp(undef, 0), q[_socket_open_udp(undef, 0)]);
    ok($client->_socket_open_udp(undef, undef),
        q[_socket_open_udp(undef, undef)]);
    is($client->_socket_open_udp(inet_aton(q[127.0.0.1]), q[test]),
        undef,
        q[_socket_open_udp(inet_aton(q[127.0.0.1]), q[test]) returns undef]);
SKIP: {
        skip 'This does not work as expected on irix', 1 if $^O =~ m[irix]i;
        is($client->_socket_open_udp({}),
            undef, q[_socket_open_udp({}) returns undef]);
    }
    is($client->_socket_open_udp(q[127.0.0.1:25012]),
        undef, q[_socket_open_udp(q[127.0.0.1:25012]) returns undef]);
    ok($client->_socket_open_udp(q[127.0.0.1], 0),
        q[_socket_open_udp('127.0.0.1', 0)]);
    isa_ok($client->_udp, q[GLOB], q[UDP is good]);
    ok($client->_udp_host, q[_udp_host]);
    ok($client->_udp_port, q[_udp_port]);
    warn(q[ [Alpha] _socket_open_udp() and new() accept textual]);
    warn(q[         hostnames ('localhost', 'ganchan.somewhere.net', etc.)]);
    warn(q[         which are automatically resolved.]);
    ok($client->_socket_open_udp(q[localhost], 0),
        q[_socket_open_udp('localhost', 0) [Undocumented]]);
    my ($port_one, $packed_ip_one)
        = unpack_sockaddr_in(getsockname($client->_udp));
    like($port_one,
         qr[\d+],
         sprintf(q[   ...which would accept connections on port %d...],
                 $port_one)
    );
    is($packed_ip_one, inet_aton(q[127.0.0.1]),
        q[   ...if it were open to the outside world.]);
}
ok($client->do_one_loop(1),       q[do_one_loop(1)]);
ok($client->do_one_loop(1.25),    q[do_one_loop(1.25)]);
ok($client->do_one_loop(0.25),    q[do_one_loop(0.25)]);
ok($client->do_one_loop(q[test]), q[do_one_loop('test')]);
ok($client->do_one_loop(-3),      q[do_one_loop(-3)]);
SKIP: {
    skip(q[UDP- and/or TCP-based tests have been disabled.], 19)
        if not $okay_udp
            or not $okay_tcp;
    my $bt_top = Net::BitTorrent->new();
    is($bt_top->_add_connection(),
        undef, q[_add_connection requires parameters]);
    is($bt_top->_add_connection(undef, undef), undef, q[   Two, actually]);
    is($bt_top->_add_connection(1, 2), undef, q[   Two, actually (take two)]);
    is($bt_top->_add_connection(undef, 2),
        undef, q[   ...first a socket containing object]);
    is(scalar(keys %{$client->_connections}),
        2, q[Check list of _connections() == 2]);
    is_deeply($client->_connections,
              {($okay_tcp
                ? (fileno($client->_tcp) => {Mode => q[ro], Object => $client}
                    )
                : ()
               ),
               ($okay_udp
                ? (fileno($client->_udp) => {Mode => q[ro], Object => $client}
                    )
                : ()
               )
              },
              q[_sockets() returns the dht object and the client itself]
    );
    warn(  q[This next bit (tries) to create a server, client, and ]
         . q[the accepted loopback...]);
    warn(q[Think happy thoughts.]);
    warn(q[Testing Net::BitTorrent->new()]);
    my $client_no_params = Net::BitTorrent->new();
    isa_ok($client_no_params, q[Net::BitTorrent], q[new( )]);
    is(Net::BitTorrent->new(LocalPort => [20502 .. 20505]),
        undef, q[new(LocalPort => [20502..20505]) returns undef]);
    is(Net::BitTorrent->new([20502 .. 20505]),
        undef, q[new([20502..20505]) returns undef]);
    is(Net::BitTorrent->new(q[0.0.0.0:20502]),
        undef, q[new(q[0.0.0.0:20502]) returns undef]);
    isa_ok(Net::BitTorrent->new({}), q[Net::BitTorrent], q[new({ })]);
    isa_ok(Net::BitTorrent->new({LocalPort => 20502}),
           q[Net::BitTorrent],
           q[new({LocalPort => 20502})]
    );
    my $_reuse_1 = Net::BitTorrent->new({LocalPort => $client->_tcp_port});
    isa_ok($_reuse_1, q[Net::BitTorrent],
           sprintf q[new({LocalPort => %d}) (Attempt to reuse port)],
           $client->_tcp_port);
SKIP: {
        my ($_tmp_fail, $_tmp_okay);
        eval {
            $_tmp_fail
                = Net::BitTorrent->new(
                {LocalPort => $client->_tcp_port, LocalAddr => q[127.0.0.1]});
            $_tmp_okay =
                Net::BitTorrent->new({LocalPort => $client->_tcp_port,
                                      LocalAddr => q[127.0.0.1]
                                     }
                );
        };
        is($_tmp_fail->_tcp_port, undef,
            sprintf q[Attempt to reuse port (%d) fails],
            $client->_tcp_port);
    }
    my $client_range_port
        = Net::BitTorrent->new({LocalPort => [20502 .. 20505]});
    isa_ok($client_range_port, q[Net::BitTorrent],
           q[new({LocalPort => [20502 .. 20505]})]);
    my $client_list_port
        = Net::BitTorrent->new({LocalPort => [20502, 20505]});
    isa_ok($client_list_port, q[Net::BitTorrent],
           q[new({LocalPort => [20502, 20505]})]);
    my $socket = $client_list_port->_tcp;
SKIP: {
        skip 'Failed to reopen socket', 2
            if !defined $socket;
        isa_ok($socket, q[GLOB], q[Socket is valid.]);
        my ($port, $packed_ip) = unpack_sockaddr_in(getsockname($socket));
        is($port, 20505, q[Correct port was opened (20505).]);
    }
}
warn(q[Testing Net::BitTorrent->add_torrent()]);
is($client->add_torrent(q[./t/900_data/950_torrents/952_multi.torrent]),
    undef, q[Needs hash ref params]);
$torrent = $client->add_torrent(
                      {Path => q[./t/900_data/950_torrents/952_multi.torrent],
                       BaseDir => $tempdir
                      }
);
isa_ok($torrent, q[Net::BitTorrent::Torrent], q[Added torrent]);
is_deeply($client->torrents,
          {$$torrent => $torrent},
          q[Net::BitTorrent correctly stores torrents]);
is( $client->add_torrent(
                      {Path => q[./t/900_data/950_torrents/952_multi.torrent]}
    ),
    undef,
    q[   ...but only once.]
);
is_deeply($client->torrents,
          {$$torrent => $torrent},
          q[   (Double check that to be sure)]);
ok($client->remove_torrent($torrent), q[Attempt to remove torrent]);
is($client->remove_torrent(q[Junk!]),
    undef, q[Attempt to remove not-a-torrent]);
is_deeply($client->torrents, {}, q[   Check if torrent was removed]);
like($client->_peers_per_torrent, qr[^\d+$],
     q[_peers_per_torrent() is a number]);
ok($client->as_string(),  q[as_string() | simple]);
ok($client->as_string(0), q[as_string(0) | simple]);
is($client->as_string(), $client->as_string(0),
    q[as_string() == as_string(0)]);
isn't($client->as_string(), $client->as_string(1),
      q[as_string() != as_string(1)]);
sub TIEHANDLE { pass(q[Tied STDERR]); bless \{}, shift; }

sub PRINT {
    is((caller(0))[0], q[Net::BitTorrent], q[String written to STDERR]);
}
sub UNTIE { pass(q[Untied STDERR]); }
tie(*STDERR, __PACKAGE__);
$client->as_string();
$client->as_string(1);
untie *STDERR;
SKIP: {
    skip(q[UDP-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) if not $okay_udp;
    isa_ok($client->_dht, q[Net::BitTorrent::DHT], q[DHT is active]);
    ok($client->_use_dht, q[DHT is enabled by default]);
    is($client->_set_use_dht(0), 0, q[DHT has been disabled]);
    ok(!$client->_use_dht, q[DHT is disabled]);
    is($client->_set_use_dht(0), 0, q[DHT has been disabled (round two)]);
    ok(!$client->_use_dht,       q[DHT is disabled (round two)]);
    ok($client->_set_use_dht(1), q[DHT has been enabled (round three?)]);
    ok($client->_use_dht,        q[DHT is active (round house?)]);
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

$Id: BitTorrent.t 98bfd28 2010-04-02 18:04:37Z sanko@cpan.org $
