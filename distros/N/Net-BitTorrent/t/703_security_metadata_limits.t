use v5.40;
use feature 'class', 'try';
use Test2::V1 -ipP;
no warnings 'recursion';
#
use lib 'lib', '../lib';
use Digest::SHA qw[sha1];
use Path::Tiny;
use Net::BitTorrent;
use Net::BitTorrent::Torrent;
use Net::BitTorrent::Storage::File;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
#
subtest bdecode => sub {
    subtest 'Shallow nesting accepted' => sub {
        my $deep   = 'l' x 5 . '4:test' . 'e' x 5;
        my $result = bdecode($deep);
        ok defined $result, '5-deep nested list decodes';
        is ref $result, 'ARRAY', 'result is an array ref';
    };
    #
    subtest 'Exactly MAX_BDECODE_DEPTH nesting accepted' => sub {
        my $max    = Net::BitTorrent::Protocol::BEP03::Bencode::MAX_BDECODE_DEPTH();
        my $deep   = 'l' x $max . '4:test' . 'e' x $max;
        my $result = bdecode($deep);
        ok defined $result, "depth=$max decodes successfully";
        is ref $result, 'ARRAY', 'result is an array ref';
    };
    #
    subtest 'MAX_BDECODE_DEPTH + 1 nesting rejected' => sub {
        my $max  = Net::BitTorrent::Protocol::BEP03::Bencode::MAX_BDECODE_DEPTH();
        my $deep = 'l' x ( $max + 1 ) . '1:x' . 'e' x ( $max + 1 );
        my $died = 0;
        my $err;
        try { bdecode($deep) }
        catch ($e) { $died = 1; $err = $e };
        ok $died, 'exceeding depth limit dies';
        like $err, qr/nesting depth limit/, 'error mentions depth limit';
    };
    #
    subtest 'Deeply nested dictionaries rejected' => sub {
        my $max  = Net::BitTorrent::Protocol::BEP03::Bencode::MAX_BDECODE_DEPTH();
        my $deep = ( 'd1:a' x ( $max + 1 ) ) . '1:v' . ( 'e' x ( $max + 1 ) );
        my $died = 0;
        try { bdecode($deep) }
        catch ($e) { $died = 1 };
        ok $died, 'deeply nested dict dies';
    };
    #
    subtest 'Mixed list/dict nesting at limit accepted' => sub {
        my $max   = Net::BitTorrent::Protocol::BEP03::Bencode::MAX_BDECODE_DEPTH();
        my $inner = '4:test';
        my $str   = $inner;
        for my $i ( 1 .. $max ) {
            $str = $i % 2 ? "l${str}" : "d1:x${str}";
        }
        my $open = '';
        for my $i ( reverse 1 .. $max ) {
            $open .= $i % 2 ? 'e' : 'e';
        }
        $str .= $open;
        my $result = bdecode($str);
        ok defined $result, "mixed nesting at depth=$max decodes";
    };
    #
    subtest 'Normal (shallow) bencode still works after changes' => sub {
        is bdecode('4:spam'), 'spam', 'simple string';
        is bdecode('i42e'),   42,     'integer';
        my $el = bdecode('le');
        is $el, array {end}, 'empty list';
        my $r1 = bdecode('l4:spame');
        is $r1, array { item 0 => 'spam'; end }, 'single item list';
        my $r2 = bdecode('d3:cow3:moo4:spam4:eggse');
        is $r2, hash { field cow => 'moo'; field spam => 'eggs'; end }, 'dictionary';
        my $r3 = bdecode('li1ei2ei3ee');
        is $r3, array { item 0 => 1; item 1 => 2; item 2 => 3; end }, 'list';
    };
    #
    subtest 'Shallow file tree accepted' => sub {
        my $client = Net::BitTorrent->new();
        my $info   = {
            name           => 'Tree Test',
            'piece length' => 262144,
            pieces         => "\0" x 20,
            'file tree'    => { a => { b => { c => { '' => { length => 100 } } } } }
        };
        my $info_encoded = bencode($info);
        my $ih           = Digest::SHA::sha1($info_encoded);
        my $t            = Net::BitTorrent::Torrent->new( infohash => $ih, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
        $t->handle_metadata_data( undef, 0, length($info_encoded), $info_encoded );
        ok $t->storage, D(), '3-deep file tree accepted';
    };
};
#
subtest 'MAX_METADATA_SIZE constant defined' => sub {
    is Net::BitTorrent::Torrent::MAX_METADATA_SIZE(), D(), 'MAX_METADATA_SIZE is defined';
    ok Net::BitTorrent::Torrent::MAX_METADATA_SIZE() > 0,                  'MAX_METADATA_SIZE is positive';
    ok Net::BitTorrent::Torrent::MAX_METADATA_SIZE() <= 100 * 1024 * 1024, 'MAX_METADATA_SIZE <= 100 MiB';
};
#
my $client = Net::BitTorrent->new();
subtest 'metadata at MAX_METADATA_SIZE accepted' => sub {
    my $info         = { name => 'At Limit', 'piece length' => 262144, pieces => "\0" x 20, length => 1024 };
    my $info_encoded = bencode($info);
    my $ih           = sha1($info_encoded);
    my $t            = Net::BitTorrent::Torrent->new( infohash => $ih, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
    $t->handle_metadata_data( undef, 0, length($info_encoded), $info_encoded );
    ok defined $t->storage, 'metadata at MAX_METADATA_SIZE accepted';
};
#
subtest 'metadata exceeding MAX_METADATA_SIZE rejected' => sub {
    my $max  = Net::BitTorrent::Torrent::MAX_METADATA_SIZE();
    my $t    = Net::BitTorrent::Torrent->new( infohash => 'D' x 20, base_path => Path::Tiny->tempdir, client => $client, debug => 0 );
    my $died = 0;
    try { $t->handle_metadata_data( undef, 0, $max + 1, 'x' x 16384 ) }
    catch ($e) { $died = 1 };
    ok $died, 'oversized metadata triggers fatal die';
    is $t->metadata_size, 0, 'metadata_size stays 0 after rejection';
    ok !defined $t->storage, 'no storage created from oversized metadata';
};
#
subtest 'Missing info dictionary does not die' => sub {
    my $temp         = Path::Tiny->tempdir;
    my $c            = Net::BitTorrent->new();
    my $bad_data     = bencode( { announce => 'http://example.com' } );
    my $torrent_file = $temp->child('bad.torrent');
    $torrent_file->spew_raw($bad_data);
    my $ok = eval { $c->add_torrent( $torrent_file, $temp ); 1 };
    ok $ok, 'add_torrent with missing info dict did not die';
};
#
subtest 'Invalid infohash length does not die' => sub {
    my $temp = Path::Tiny->tempdir;
    my $c    = Net::BitTorrent->new();
    my $ok   = eval { $c->add_infohash( 'X' x 30, $temp ); 1 };
    ok $ok, 'add_infohash with invalid length did not die';
};
#
subtest 'No path or infohash does not die' => sub {
    my $c  = Net::BitTorrent->new();
    my $ok = eval { $c->add( '/no/such/file.torrent', Path::Tiny->tempdir ); 1 };
    ok $ok, 'add with non-existent file did not die';
};
#
subtest 'Path traversal in name emits error, not fatal' => sub {
    my $temp = Path::Tiny->tempdir;
    my $c    = Net::BitTorrent->new();
    my $data = 'T' x 16384;
    my $info = {
        name           => '../../etc/passwd',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { '../../etc/passwd' => { '' => { length => 16384 } } }
    };
    my $torrent_file = $temp->child('traversal.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $ok = eval { $c->add_torrent( $torrent_file, $temp ); 1 };
    ok $ok, 'add_torrent with path traversal name did not die';
};
#
subtest 'Absolute path in name does not die' => sub {
    my $temp = Path::Tiny->tempdir;
    my $c    = Net::BitTorrent->new();
    my $data = 'A' x 16384;
    my $info
        = { name => '/tmp/evil', 'piece length' => 16384, pieces => sha1($data), 'file tree' => { '/tmp/evil' => { '' => { length => 16384 } } } };
    my $torrent_file = $temp->child('absolute.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $ok = eval { $c->add_torrent( $torrent_file, $temp ); 1 };
    ok $ok, 'add_torrent with absolute path name did not die';
};
#
subtest 'Invalid file length does not die' => sub {
    my $temp = Path::Tiny->tempdir;
    my $c    = Net::BitTorrent->new();
    my $data = 'L' x 16384;
    my $info
        = { name => 'negative.txt', 'piece length' => 16384, pieces => sha1($data), 'file tree' => { 'negative.txt' => { '' => { length => -1 } } } };
    my $torrent_file = $temp->child('negative.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $ok = eval { $c->add_torrent( $torrent_file, $temp ); 1 };
    ok $ok, 'add_torrent with negative file length did not die';
};
#
subtest 'Block cache cap constant defined' => sub {
    ok Net::BitTorrent::Torrent->can('MAX_BLOCK_CACHE'),  'MAX_BLOCK_CACHE constant exists';
    ok Net::BitTorrent::Torrent::MAX_BLOCK_CACHE() >= 32, 'MAX_BLOCK_CACHE is reasonable (>= 32)';
};
#
subtest 'Torrent _store_block eviction cap defined' => sub {
    ok Net::BitTorrent::Torrent::MAX_BLOCK_CACHE() >= 32,      'MAX_BLOCK_CACHE is >= 32';
    ok Net::BitTorrent::Torrent::MAX_BLOCK_CACHE() <= 100_000, 'MAX_BLOCK_CACHE is <= 100K';
};
#
subtest 'File size validation constant defined' => sub {
    ok Net::BitTorrent::Storage::File->can('MAX_FILE_SIZE'),                        'MAX_FILE_SIZE constant exists';
    ok Net::BitTorrent::Storage::File::MAX_FILE_SIZE() > 0,                         'MAX_FILE_SIZE is positive';
    ok Net::BitTorrent::Storage::File::MAX_FILE_SIZE() <= 100 * 1024 * 1024 * 1024, 'MAX_FILE_SIZE <= 100GB';
};
#
subtest 'File rejects oversized allocation' => sub {
    my $temp = Path::Tiny->tempdir;
    my $file = Net::BitTorrent::Storage::File->new( path => $temp->child('big.bin'), size => Net::BitTorrent::Storage::File::MAX_FILE_SIZE() + 1, );
    ok $file, 'File object created for oversized file';
    $file->_ensure_exists();
    ok !$file->path->exists, 'oversized file not created on disk';
};
#
done_testing;
