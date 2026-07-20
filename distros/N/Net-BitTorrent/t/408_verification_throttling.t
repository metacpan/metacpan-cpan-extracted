use v5.42;
use Test2::V1 -ipP;
use lib 'lib';
use Net::BitTorrent;
use Path::Tiny;
use Digest::SHA                               qw[sha1 sha256];
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
#
my $temp         = Path::Tiny->tempdir;
my $data         = 'V' x 16384;
my $torrent_file = $temp->child('test.torrent');
$torrent_file->spew_raw( bencode( { info => { name => 'test', 'piece length' => 16384, pieces => sha1($data) . sha1($data) } } ) );
my $client = Net::BitTorrent->new();
my $t      = $client->add_torrent( $torrent_file, $temp );
$t->start();

# Complete piece 0 and 1
$t->receive_block( undef, 0, 0, $data );
$t->receive_block( undef, 1, 0, $data );
ok !$t->bitfield->get(0), 'Piece 0 not yet verified (throttled)';
ok !$t->bitfield->get(1), 'Piece 1 not yet verified (throttled)';

# Force hashing rate limit to be very low for testing
# 16KB per second. Our piece is 16KB.
$client->set_hashing_rate_limit(16384);

# Tick 0.5s -> should process 8KB -> nothing finished
$client->tick(0.1) for 1 .. 5;
ok !$t->bitfield->get(0), 'Piece 0 still not finished after 0.5s';

# Tick another 0.6s -> total 1.1s -> should have finished piece 0
$client->tick(0.1) for 1 .. 6;
ok $t->bitfield->get(0),  'Piece 0 verified after 1.1s';
ok !$t->bitfield->get(1), 'Piece 1 still pending';

# Tick another 1.0s -> should finish piece 1
$client->tick(0.1) for 1 .. 10;
ok $t->bitfield->get(1), 'Piece 1 verified after 2.1s';
#
subtest 'Hashing queue drains before accepting when full' => sub {
    my $temp2   = Path::Tiny->tempdir;
    my $client2 = Net::BitTorrent->new();
    my $data2   = 'Q' x 16384;
    my $info2   = {
        name           => 'queue_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data2),
        'file tree'    => { 'queue_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data2) } } }
    };
    my $torrent_file2 = $temp2->child('test.torrent');
    $torrent_file2->spew_raw( bencode( { info => $info2 } ) );
    my $t2 = $client2->add_torrent( $torrent_file2, $temp2 );
    $client2->queue_verification( $t2, $_, $data2 ) for 0 .. 31;
    is $client2->hashing_queue_size(), 32, 'hashing queue at max capacity (32)';

    # With no hashing allowance, drain cannot process anything, so 33rd is dropped
    $client2->queue_verification( $t2, 32, $data2 );
    is $client2->hashing_queue_size(), 32, '33rd piece dropped when queue cannot drain';

    # With enough allowance, drain makes room for the next piece
    my $client3 = Net::BitTorrent->new();
    my $t3      = $client3->add_torrent( $temp2->child('test.torrent'), $temp2 );
    $client3->queue_verification( $t3, $_, $data2 ) for 0 .. 31;
    is $client3->hashing_queue_size(), 32, 'second client queue at max capacity';

    # Give enough allowance to drain one piece (16384 bytes)
    $client3->set_hashing_rate_limit( 16384 * 1000 );
    $client3->_process_hashing_queue(1.0);
    ok $client3->hashing_queue_size() < 32, 'queue drained after processing with allowance';

    # Now the 33rd should be accepted
    $client3->queue_verification( $t3, 32, $data2 );
    ok $client3->hashing_queue_size() <= 32, '33rd piece accepted after drain';
};
#
subtest 'Hashing queue allows processing to reduce size' => sub {
    my $temp3   = Path::Tiny->tempdir;
    my $client3 = Net::BitTorrent->new();
    my $data3   = 'R' x 16384;
    my $info3   = {
        name           => 'queue_test2.txt',
        'piece length' => 16384,
        pieces         => sha1($data3),
        'file tree'    => { 'queue_test2.txt' => { '' => { length => 16384, 'pieces root' => sha256($data3) } } }
    };
    my $torrent_file3 = $temp3->child('test2.torrent');
    $torrent_file3->spew_raw( bencode( { info => $info3 } ) );
    my $t3 = $client3->add_torrent( $torrent_file3, $temp3 );
    $client3->queue_verification( $t3, $_, $data3 ) for 0 .. 9;
    is $client3->hashing_queue_size(), 10, '10 pieces queued';
    $client3->_process_hashing_queue(10.0);
    ok $client3->hashing_queue_size() < 10, 'hashing queue drained after processing';
};
#
done_testing;
