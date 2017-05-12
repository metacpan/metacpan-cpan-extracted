#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Module::Build;
use Time::HiRes qw[];
use lib q[../../../../lib];
use Net::BitTorrent::Version;
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../../] if not -f $simple_dot_torrent;
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
$|++;
plan tests => 5;
SKIP: {
    like(Net::BitTorrent::Version->gen_peerid(),
         qr[^NB\d{3}[SU]-.{13}$],
         q[Peer ID conforms to spec. (initial test)]
    );
    if ($Net::BitTorrent::Version::VERSION =~ m[_]) {
        like(Net::BitTorrent::Version->gen_peerid(),
             qr[^NB\d{3}U-.{13}$],
             q[Peer ID conforms to spec. (unstable build)]
        );
        my $old_value = $Net::BitTorrent::Version::UNSTABLE_RELEASE;
        $Net::BitTorrent::Version::UNSTABLE_RELEASE = 0;
        like(Net::BitTorrent::Version->gen_peerid(),
             qr[^NB\d{3}S-.{13}$],
             q[Peer ID conforms to spec. (fake stable build)]
        );
        $Net::BitTorrent::Version::UNSTABLE_RELEASE = $old_value;
    }
    else {
        like(Net::BitTorrent::Version->gen_peerid(),
             qr[^NB\d{3}S-.{13}$],
             q[Peer ID conforms to spec. (stable build)]
        );
        my $old_value = $Net::BitTorrent::Version::UNSTABLE_RELEASE;
        $Net::BitTorrent::Version::UNSTABLE_RELEASE = 1;
        like(Net::BitTorrent::Version->gen_peerid(),
             qr[^NB\d{3}U-.{13}$],
             q[Peer ID conforms to spec. (fake unstable build)]
        );
        $Net::BitTorrent::Version::UNSTABLE_RELEASE = $old_value;
    }
    like(Net::BitTorrent::Version->gen_peerid(),
         qr[^NB\d{3}[SU]-.{13}$], q[Peer ID conforms to spec.]);
    ok(length(Net::BitTorrent::Version->gen_node_id()) == 20,
        q[DHT node id conforms to spec.]);
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

$Id: Version.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
