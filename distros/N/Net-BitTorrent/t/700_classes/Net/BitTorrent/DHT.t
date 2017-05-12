#!/usr/bin/perl -Iinc
use strict;
use warnings;
use Test::More;
use Module::Build;
use File::Temp qw[tempdir];
use Scalar::Util qw[/weak/];
use Time::HiRes qw[];
use lib q[../../../../lib];
use Net::BitTorrent::DHT;
use Net::BitTorrent;
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../../] if not -f $simple_dot_torrent;
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
my ($flux_capacitor, %peers) = (0, ());
plan tests => 4;
SKIP: {
    skip(q[Socket-based tests have been disabled.],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) if not $okay_udp;
    my ($tempdir)
        = tempdir(q[~NBSF_test_XXXXXXXX], CLEANUP => 1, TMPDIR => 1);
    warn(sprintf(q[File::Temp created '%s' for us to play with], $tempdir));
    my $client = Net::BitTorrent->new({LocalHost => q[127.0.0.1]});
    skip(q[Failed to create client/DHT node],
         ($test_builder->{q[Expected_Tests]} - $test_builder->{q[Curr_Test]})
    ) if !$client || !$client->_dht;
    isa_ok($client->_dht, q[Net::BitTorrent::DHT], q[N::B->_dht]);
    ok($client->_dht->node_id, q[node_id()]);
}

# Bugfixes
{
    my $nb = Net::BitTorrent->new();
    is_deeply($nb->_dht->nodes(), [],
              'List of DHT nodes is empty by default');
    $nb->add_torrent({Path => './t/900_data/950_torrents/956_dht.torrent'});
    is_deeply($nb->_dht->nodes(),
              [{qw[ip 127.0.0.1 port 1024]}],
              'List of DHT nodes includes boot nodes from .torrent');
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

$Id: DHT.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
