use v5.40;
use feature 'try';
use Test2::V1 -ipP;
no warnings;
use lib 'lib', '../lib';
use Net::BitTorrent;
use Net::BitTorrent::Types;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Digest::SHA                               qw[sha1 sha256];
use Path::Tiny;
#
my $torrent_dir = path('t/900_data/test_torrents');
subtest 'Unordered Dictionary' => sub {
    my $unordered = $torrent_dir->child('unordered.torrent');
    my $error;
    try {
        my $nb = Net::BitTorrent->new();
        $nb->add( $unordered, 'temp_data' );
    }
    catch ($e) { $error = $e; }
    like $error, qr/malformed dictionary/, 'Strict bdecode catches unordered dictionary';
};
subtest 'Invalid Filename (Traversal Attempt)' => sub {
    my $traversal = $torrent_dir->child('absolute_filename.torrent');
    my $nb        = Net::BitTorrent->new();
    my $t         = $nb->add( $traversal, 'temp_data' );
    is $t->storage, U(), 'Absolute path torrent has no storage';
};
subtest 'Missing Info' => sub {
    my $missing = $torrent_dir->child('invalid_info.torrent');
    my $nb      = Net::BitTorrent->new();
    my $t       = $nb->add( $missing, 'temp_data' );
    is $t->storage, U(), 'Missing info torrent has no storage';
};
subtest 'Negative Piece Length' => sub {
    my $neg = $torrent_dir->child('negative_piece_len.torrent');
    my $nb  = Net::BitTorrent->new();
    my $t   = $nb->add( $neg, 'temp_data' );
    is $t->storage, U(), 'Negative piece length torrent has no storage';
};
#
subtest 'handle_metadata_request rejects negative piece index' => sub {
    my $nb   = Net::BitTorrent->new();
    my $data = 'N' x 16384;
    my $info = {
        name           => 'neg_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'neg_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } },
    };
    my $temp = Path::Tiny->tempdir;
    $temp->child('neg_test.torrent')->spew_raw( bencode( { info => $info } ) );
    my $torrent = $nb->add_torrent( $temp->child('neg_test.torrent'), $temp );
    $torrent->start();
    is $torrent->handle_metadata_request( undef, -1 ), U(), 'Negative piece index returns undef';
};
#
subtest 'handle_metadata_request rejects too-large piece index' => sub {
    my $nb   = Net::BitTorrent->new();
    my $data = 'L' x 16384;
    my $info = {
        name           => 'large_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'large_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } }
    };
    my $temp = Path::Tiny->tempdir;
    $temp->child('large_test.torrent')->spew_raw( bencode( { info => $info } ) );
    my $torrent = $nb->add_torrent( $temp->child('large_test.torrent'), $temp );
    $torrent->start();
    is $torrent->handle_metadata_request( undef, 100 ), U(), 'Too-large piece index returns undef';
};
done_testing;
