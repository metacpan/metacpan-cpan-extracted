use strict;
use warnings;

use Test::More tests => 3;
use Protocol::BitTorrent::Metainfo;

my $info = Protocol::BitTorrent::Metainfo->new;
is($info->generate_peer_id('XX', '0100', '012314817179'), '-XX0100-012314817179', 'peer_id matches when all 3 values given');
is($info->generate_peer_id(undef, '0100', '012314817179'), '-PB0100-012314817179', 'peer_id matches when type is undef');
is($info->generate_peer_id(undef, undef, '012314817179'), '-PB0004-012314817179', 'peer_id matches when version is undef');

