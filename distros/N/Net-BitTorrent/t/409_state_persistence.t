use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Path::Tiny;
use Digest::SHA qw[sha1 sha256];
subtest 'State Persistence' => sub {
    my $temp = Path::Tiny->tempdir;

    # Create a torrent
    my $data        = 'A' x 16384;
    my $pieces_root = sha256($data);
    my $info        = {
        name           => 'persist.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'persist.txt' => { '' => { length => 16384, 'pieces root' => $pieces_root } } },
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add_torrent( $torrent_file, $temp );

    # Mock some progress and VERIFY
    $t->bitfield->set(0);
    $t->storage->verify_block( $pieces_root, 0, $data );
    $t->storage->write_block( $pieces_root, 0, $data );

    # Dump state
    my $state = $t->dump_state();
    ok $state->{bitfield},                       'State has bitfield';
    ok $state->{storage},                        'State has storage';
    ok $state->{storage}{'persist.txt'}{merkle}, 'Storage state has merkle tree for persist.txt';

    # Create new instance and load state
    my $client2 = Net::BitTorrent->new();
    my $t2      = $client2->add_torrent( $torrent_file, $temp );
    ok !$t2->bitfield->get(0), 'New instance bitfield is empty initially';
    $t2->load_state($state);
    ok $t2->bitfield->get(0), 'Loaded instance bitfield has piece 0 set';
    is $t2->metadata->{info}{name}, 'persist.txt', 'Metadata restored correctly';

    # Verify Merkle tree restoration
    my $file2 = $t2->storage->get_file_by_root($pieces_root);
    ok $file2->merkle, 'File 2 has merkle tree';
    is $file2->merkle->root, $pieces_root, 'Merkle root is correct after load (assuming it was verified before)';
};
#
subtest 'client load_state ignores wrong-length node_id' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $orig_id = $client->node_id;

    # Write a state file with wrong-length node_id
    use JSON::PP qw[encode_json];
    my $state_file = $temp->child('bad_state.json');
    $state_file->spew_utf8( encode_json( { node_id => 'short', torrents => {} } ) );
    $client->load_state($state_file);
    is $client->node_id, $orig_id, 'node_id unchanged after load_state with wrong-length node_id';
};
#
subtest 'DHT import_state ignores wrong-length node_id' => sub {
    my $dht       = Net::BitTorrent::DHT->new( port => 0, ssrf_bypass => 1, boot_nodes => [] );
    my $orig_id   = $dht->node_id_bin;
    my $bad_state = { id => 'tooshort' };                                                         # Only 8 bytes instead of 20
    $dht->import_state($bad_state);
    is $dht->node_id_bin, $orig_id, 'node_id_bin unchanged after import_state with wrong-length node_id';
};
#
subtest 'client load_state rejects malformed JSON' => sub {
    my $temp       = Path::Tiny->tempdir;
    my $client     = Net::BitTorrent->new();
    my $orig_id    = $client->node_id;
    my $state_file = $temp->child('bad.json');
    $state_file->spew_utf8('{ this is not valid json }');
    my $ok = eval { $client->load_state($state_file); 1 };
    ok $ok, 'load_state with malformed JSON did not die';
    is $client->node_id, $orig_id, 'node_id unchanged after malformed JSON';
};
#
subtest 'client load_state rejects non-hash JSON' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $orig_id = $client->node_id;
    use JSON::PP qw[encode_json];
    my $state_file = $temp->child('array.json');
    $state_file->spew_utf8( encode_json( [ 1, 2, 3 ] ) );
    my $ok = eval { $client->load_state($state_file); 1 };
    ok $ok, 'load_state with array JSON did not die';
    is $client->node_id, $orig_id, 'node_id unchanged after non-hash JSON';
};
#
subtest 'client load_state ignores invalid torrent hex keys' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $orig_id = $client->node_id;
    use JSON::PP qw[encode_json];
    my $state_file = $temp->child('bad_keys.json');
    $state_file->spew_utf8( encode_json( { node_id => $orig_id, torrents => { 'not_a_valid_hex' => {} } } ) );
    my $ok = eval { $client->load_state($state_file); 1 };
    ok $ok, 'load_state with invalid hex keys did not die';
};
#
subtest 'client load_state ignores torrent entries that are not hashes' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $orig_id = $client->node_id;
    use JSON::PP qw[encode_json];
    my $valid_hex  = 'a' x 40;
    my $state_file = $temp->child('bad_entry.json');
    $state_file->spew_utf8( encode_json( { node_id => $orig_id, torrents => { $valid_hex => 'not_a_hash' } } ) );
    my $ok = eval { $client->load_state($state_file); 1 };
    ok $ok, 'load_state with non-hash torrent entry did not die';
};
#
subtest 'torrent load_state validates bitfield size' => sub {
    my $temp2   = Path::Tiny->tempdir;
    my $client2 = Net::BitTorrent->new();
    my $data2   = 'B' x 16384;
    my $info2   = {
        name           => 'bf_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data2),
        'file tree'    => { 'bf_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data2) } } }
    };
    my $torrent_file2 = $temp2->child('test.torrent');
    $torrent_file2->spew_raw( bencode( { info => $info2 } ) );
    my $t = $client2->add_torrent( $torrent_file2, $temp2 );
    $t->start();
    my $ok = eval { $t->load_state( { bitfield => 'x' x 10 } ); 1 };
    ok $ok,                   'load_state with wrong bitfield size did not die';
    ok !$t->bitfield->get(0), 'bitfield not corrupted by wrong-size data';
};
#
subtest 'torrent load_state validates metadata structure' => sub {
    my $temp3   = Path::Tiny->tempdir;
    my $client3 = Net::BitTorrent->new();
    my $data3   = 'M' x 16384;
    my $info3   = {
        name           => 'meta_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data3),
        'file tree'    => { 'meta_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data3) } } }
    };
    my $torrent_file3 = $temp3->child('test.torrent');
    $torrent_file3->spew_raw( bencode( { info => $info3 } ) );
    my $t2 = $client3->add_torrent( $torrent_file3, $temp3 );
    $t2->start();
    my $ok = eval { $t2->load_state( { metadata => 'not_a_hash' } ); 1 };
    ok $ok, 'load_state with invalid metadata did not die';
};
#
done_testing;
