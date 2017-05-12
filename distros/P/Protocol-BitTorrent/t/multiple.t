use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Protocol::BitTorrent;
use File::Slurp;
use File::Basename;

my $t = new_ok('Protocol::BitTorrent');

my $torrent = read_file(dirname(__FILE__) . '/multiple.torrent', { binmode => ':raw' });
my $info = $t->parse_metainfo($torrent);
is($info->announce, 'http://torrent.entitymodel.com', 'announce is correct');
is($info->comment, 'Sample containing multiple files and nested folders', 'comment is correct');
is($info->piece_length, 32 * 1024, 'piece length is correct');
my (@files) = $info->files;
is(@files, 30, 'have correct number of files');
my @pending = (
	{ name => 'bin/torrentcreate.pl', length => 668, },
	{ name => 'bin/torrentedit.pl', length => 599, },
	{ name => 'Changes', length => 659, },
	{ name => 'dist.ini', length => 1806, },
	{ name => 'examples/scrape.pl', length => 1210, },
	{ name => 'examples/url.pl', length => 522, },
	{ name => 'lib/Protocol/BitTorrent.pm', length => 4729, },
	{ name => 'lib/Protocol/BitTorrent/Bencode.pm', length => 1211, },
	{ name => 'lib/Protocol/BitTorrent/Message.pm', length => 3944, },
	{ name => 'lib/Protocol/BitTorrent/Message/Bitfield.pm', length => 989, },
	{ name => 'lib/Protocol/BitTorrent/Message/Cancel.pm', length => 541, },
	{ name => 'lib/Protocol/BitTorrent/Message/Choke.pm', length => 545, },
	{ name => 'lib/Protocol/BitTorrent/Message/Handshake.pm', length => 1925, },
	{ name => 'lib/Protocol/BitTorrent/Message/Have.pm', length => 542, },
	{ name => 'lib/Protocol/BitTorrent/Message/Interested.pm', length => 562, },
	{ name => 'lib/Protocol/BitTorrent/Message/Keepalive.pm', length => 534, },
	{ name => 'lib/Protocol/BitTorrent/Message/Piece.pm', length => 1376, },
	{ name => 'lib/Protocol/BitTorrent/Message/Port.pm', length => 551, },
	{ name => 'lib/Protocol/BitTorrent/Message/Request.pm', length => 1527, },
	{ name => 'lib/Protocol/BitTorrent/Message/Unchoke.pm', length => 545, },
	{ name => 'lib/Protocol/BitTorrent/Message/Uninterested.pm', length => 570, },
	{ name => 'lib/Protocol/BitTorrent/Metainfo.pm', length => 11158, },
	{ name => 't/00-pod.t', length => 130, },
	{ name => 't/00-use.t', length => 87, },
	{ name => 't/bencode.t', length => 510, },
	{ name => 't/message.t', length => 3180, },
	{ name => 't/multiple.t', length => 935, },
	{ name => 't/peer_id.t', length => 512, },
	{ name => 't/single.t', length => 933, },
	{ name => 't/single.torrent', length => 796, },
);
while(@pending && @files) {
	my $file = shift @files;
	my $expected = shift @pending;
	is(ref $file, 'HASH', 'returns a hashref for ' . $expected->{name});
	is(delete $file->{$_}, $expected->{$_}, $_ . ' is correct') for qw(name length);
	is(keys %$file, 0, 'no leftover items');
}

is(unpack('H*', $info->infohash), '780b39cdfd8e1897a97a3baba3bb22b47f2efba0', 'infohash matches');
is(length($info->peer_id), 20, 'peer_id is long enough');
done_testing;
