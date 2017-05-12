use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Protocol::BitTorrent;
use File::Slurp;
use File::Basename;

my $t = new_ok('Protocol::BitTorrent');

my $torrent = read_file(dirname(__FILE__) . '/single.torrent', { binmode => ':raw' });
my $info = $t->parse_metainfo($torrent);
#note explain $info->{orig}->{info};
is($info->announce, 'http://192.168.1.177:6969/announce', 'announce is correct');
is($info->comment, 'Random test comment', 'comment is correct');
is($info->piece_length, 256 * 1024, 'piece length is correct');
my ($file, @extra) = $info->files;
is(@extra, 0, 'just one file');
is(ref $file, 'HASH', 'returns a hashref');
is($file->{name}, 'test.dat', 'name is correct');
is($file->{length}, 8 * 1024 * 1024, 'length is correct');

is(unpack('H*', $info->infohash), '128ecfc5a7f539b4564a76e33247ade32c4721ab', 'infohash matches');
is(length($info->peer_id), 20, 'peer_id is long enough');
done_testing;
