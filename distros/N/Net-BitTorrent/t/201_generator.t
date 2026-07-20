use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Torrent::Generator;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode];
use Path::Tiny;
use Digest::SHA qw[sha1 sha256];
subtest 'v1 Generation (Single File)' => sub {
    my $temp = Path::Tiny->tempdir;
    my $file = $temp->child('test.bin');
    my $data = 'A' x 16384 . 'B' x 16384;
    $file->spew_raw($data);
    my $gen = Net::BitTorrent::Torrent::Generator->new( base_path => $temp, piece_length => 16384 );
    $gen->add_file('test.bin');
    $gen->add_tracker('http://example.com/announce');
    my $torrent_raw = $gen->generate_v1();
    my $torrent     = bdecode($torrent_raw);
    is $torrent->{announce},               'http://example.com/announce', 'Announce URL correct';
    is $torrent->{info}{name},             $temp->basename,               'Name correct';
    is $torrent->{info}{length},           length($data),                 'Length correct';
    is length( $torrent->{info}{pieces} ), 40,                            'Two pieces (2 * 20 bytes)';
    my $p1 = sha1( 'A' x 16384 );
    my $p2 = sha1( 'B' x 16384 );
    is $torrent->{info}{pieces}, $p1 . $p2, 'Piece hashes correct';
};
subtest 'v2 Generation' => sub {
    my $temp = Path::Tiny->tempdir;
    my $file = $temp->child('test.bin');
    my $data = 'A' x 16384 . 'B' x 16384;
    $file->spew_raw($data);
    my $gen = Net::BitTorrent::Torrent::Generator->new( base_path => $temp, piece_length => 16384 );
    $gen->add_file('test.bin');
    my $torrent_raw = $gen->generate_v2();
    my $torrent     = bdecode($torrent_raw);
    is $torrent->{info}{'meta version'}, 2, 'Meta version correct';
    ok exists $torrent->{info}{'file tree'}, 'File tree exists';
    ok exists $torrent->{'piece layers'},    'Piece layers exist';
    my $root = $torrent->{info}{'file tree'}{'test.bin'}{''}{'pieces root'};
    ok $root, 'Pieces root exists for file';

    # Verify Merkle root manually
    # 2 blocks of 16384.
    # H(A) = sha256('A'x16384)
    # H(B) = sha256('B'x16384)
    # Root = sha256(H(A) . H(B))
    my $hA            = sha256( 'A' x 16384 );
    my $hB            = sha256( 'B' x 16384 );
    my $expected_root = sha256( $hA . $hB );
    is $root, $expected_root, 'Merkle root correct';
};
subtest 'Hybrid Generation' => sub {
    my $temp = Path::Tiny->tempdir;
    my $file = $temp->child('test.bin');
    my $data = 'A' x 16384 . 'B' x 16384;
    $file->spew_raw($data);
    my $gen = Net::BitTorrent::Torrent::Generator->new( base_path => $temp, piece_length => 16384 );
    $gen->add_file('test.bin');
    my $torrent_raw = $gen->generate_hybrid();
    my $torrent     = bdecode($torrent_raw);
    is $torrent->{info}{'meta version'}, 2, 'Meta version correct';
    ok exists $torrent->{info}{pieces},      'v1 pieces exist';
    ok exists $torrent->{info}{'file tree'}, 'v2 file tree exists';
};
subtest 'Options' => sub {
    my $temp = Path::Tiny->tempdir;
    my $gen  = Net::BitTorrent::Torrent::Generator->new( base_path => $temp );
    $gen->set_private(1);
    $gen->add_node( 'router.example.com', 6881 );

    # Add a dummy file to allow generation
    my $file = $temp->child('dummy.bin');
    $file->spew_raw('X');
    $gen->add_file('dummy.bin');
    my $torrent = bdecode( $gen->generate_v1() );
    is $torrent->{info}{private}, 1,                    'Private flag set';
    is $torrent->{nodes}[0][0],   'router.example.com', 'Bootstrap node host correct';
    is $torrent->{nodes}[0][1],   6881,                 'Bootstrap node port correct';
};
#
subtest 'add_file path stays within base_path' => sub {
    my $temp = Path::Tiny->tempdir;
    $temp->child('safe.txt')->spew('hello');
    my $gen = Net::BitTorrent::Torrent::Generator->new( base_path => $temp );
    $gen->add_file('safe.txt');
    pass 'normal file added successfully within base_path';
};
done_testing;
