use v5.40;
use feature 'class', 'try';
use Test2::V1 -ipP;
no warnings;
#
# CVE-2026-57079
#
use lib 'lib', '../lib';
use Digest::SHA qw[sha1 sha256];
use Path::Tiny;
use Net::BitTorrent;
use Net::BitTorrent::Torrent;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
#
sub _make_torrent_file ( $name, $base ) {
    my $pieces       = "\0" x 20;
    my $info         = { name => $name, 'piece length' => 262144, pieces => $pieces, length => 262144, };
    my $torrent_data = bencode { 'announce' => 'http://tracker.example.com/announce', info => $info };
    my $file         = $base->child('test.torrent');
    $file->spew_raw($torrent_data);
    return $file;
}
#
my $client = Net::BitTorrent->new();
subtest File => sub {
    subtest 'Valid names are accepted' => sub {
        my $base = Path::Tiny->tempdir;
        for my $name ( 'My Torrent', 'debian-12.iso', 'Linux.Kernel.v6.0', 'file_with_underscores' ) {
            my $file = _make_torrent_file( $name, $base );
            my $t    = $client->add_torrent( $file, $base );
            ok defined $t->storage, "name '$name' accepted";
        }
    };
    #
    subtest 'Name with forward slash rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( '../../etc/passwd', $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|path traversal/, 'fatal die for name with /' }
        ok !defined( $t && $t->storage ), 'name with / rejected';
    };
    #
    subtest 'Name with backslash rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( '..\\..\\Windows\\System32', $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|path traversal/, 'fatal die for name with \\' }
        ok !defined( $t && $t->storage ), 'name with \\ rejected';
    };
    #
    subtest 'Name that is exactly ".." rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( '..', $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|path traversal/, 'fatal die for name ".."' }
        ok !defined( $t && $t->storage ), 'name ".." rejected';
    };
    #
    subtest 'Name with null byte rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( "safe\x00evil", $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|path traversal/, 'fatal die for null byte' }
        ok !defined( $t && $t->storage ), 'name with null byte rejected';
    };
    #
    subtest 'Name with absolute Unix path rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( '/tmp/evil', $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|absolute path/, 'fatal die for absolute path' }
        ok !defined( $t && $t->storage ), 'absolute path /tmp/evil rejected';
    };
    #
    subtest 'Name with leading dot-slash rejected' => sub {
        my $base = Path::Tiny->tempdir;
        my $file = _make_torrent_file( './escape', $base );
        my $t;
        try { $t = $client->add_torrent( $file, $base ) }
        catch ($e) { like $e, qr/Invalid name|path traversal/, 'fatal die for leading ./' }
        ok !defined( $t && $t->storage ), 'name with leading ./ rejected';
    }
};
#
subtest BEP09 => sub {
    subtest 'Oversized metadata rejected' => sub {
        my $ih   = 'C' x 20;
        my $t    = Net::BitTorrent::Torrent->new( infohash => $ih, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
        my $died = 0;
        try { $t->handle_metadata_data( undef, 0, 100 * 1024 * 1024, 'x' x 16384 ) }
        catch ($e) { $died = 1 };
        ok $died, 'oversized metadata (100 MB) triggers fatal die';
        is $t->metadata_size, 0, 'metadata_size stays 0 after rejection';
    };
    #
    subtest 'Valid small metadata accepted' => sub {
        my $client       = Net::BitTorrent->new();
        my $info         = { name => 'Valid Name', 'piece length' => 262144, pieces => "\0" x 20, length => 1024 };
        my $info_encoded = bencode($info);
        my $ih           = sha1($info_encoded);
        my $t            = Net::BitTorrent::Torrent->new( infohash => $ih, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
        $t->handle_metadata_data( undef, 0, length($info_encoded), $info_encoded );
        ok defined $t->storage, 'valid metadata accepted';
        is $t->state, 2, 'torrent transitions to STATE_RUNNING';
    };
    #
    subtest 'Traversal name rejected' => sub {
        my $client       = Net::BitTorrent->new();
        my $info         = { name => '../../etc/evil', 'piece length' => 262144, pieces => "\0" x 20, length => 1024 };
        my $info_encoded = bencode($info);
        my $ih           = sha1($info_encoded);
        my $t            = Net::BitTorrent::Torrent->new( infohash => $ih, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
        my $died         = 0;
        try { $t->handle_metadata_data( undef, 0, length($info_encoded), $info_encoded ) }
        catch ($e) { $died = 1 };
        ok !$died,               'traversal name in metadata does not crash (error, not fatal)';
        ok !defined $t->storage, 'no storage created';
        is $t->state, 0, 'torrent remains in STATE_STOPPED';
    }
};
#
subtest 'v2 file tree null byte rejected' => sub {
    my $client = Net::BitTorrent->new();
    my $temp   = Path::Tiny->tempdir;
    my $info   = {
        name           => 'test',
        'piece length' => 16384,
        'file tree'    => { "evil\x00file.txt" => { '' => { length => 100, 'pieces root' => "\0" x 32 } } },
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $t = $client->add_torrent( $torrent_file, $temp );
    ok $t, 'torrent object created even with null-byte path (error not fatal)';
};
#
subtest 'v1 multi-file path null byte rejected' => sub {
    my $client = Net::BitTorrent->new();
    my $temp   = Path::Tiny->tempdir;
    my $info
        = { name => 'test', 'piece length' => 16384, pieces => sha1( 'x' x 16384 ), files => [ { length => 100, path => ["evil\x00file.txt"], }, ], };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $t = $client->add_torrent( $torrent_file, $temp );
    ok $t, 'torrent with v1 null-byte path created (error not fatal)';
};
#
subtest 'v2 file tree without null bytes accepted' => sub {
    my $client = Net::BitTorrent->new();
    my $temp   = Path::Tiny->tempdir;
    my $data   = 'X' x 16384;
    my $info   = {
        name           => 'test',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'normal_file.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } },
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $t = $client->add_torrent( $torrent_file, $temp );
    ok $t, 'torrent with normal v2 path accepted';
};
#
done_testing;
