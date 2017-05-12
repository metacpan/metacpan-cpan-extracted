# -*- perl -*-

# t/003_io.t - check module loading and saveing .torrent files

use Test::More qw(no_plan);

BEGIN { use_ok( 'Net::BitTorrent::File' ); }

my $test_string = 'Test string';
my $test_file = 't/testdata/test.torrent';
my $test_save = 't/testdata/save.torrent';
my $test_pieces = 'AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB';
my $pieces_array = ['AAAAAAAAAAAAAAAAAAAA','BBBBBBBBBBBBBBBBBBBB'];
my $info = {
	files => 'nothing',
	pieces => $test_pieces,
	length => 42,
	piece_length => 2**18,
	name => 'test data'
};
my $data = {
	announce => $test_string,
	info => $info,
};


ok(-f $test_file, 'test file found');
my $object = Net::BitTorrent::File->new ($test_file);
isa_ok ($object, 'Net::BitTorrent::File', 'object from file');

is_deeply($object->info(), $info, 'info loaded correctly');
isnt($object->info_hash(), undef, 'info_hash generated');
is_deeply($object->pieces_array(), $pieces_array, 'pieces_array generated');
is_deeply($object->{'data'}, $data, 'data loaded correctly');

if(-f $test_save) {
	unlink $test_save;
}
$object->save($test_save);
ok(-f $test_save, 'saveing test file');
$object = Net::BitTorrent::File->new ($test_save);
isa_ok ($object, 'Net::BitTorrent::File', 'restoring saved file');
is_deeply($object->info(), $info, 'info reloaded correctly');
isnt($object->info_hash(), undef, 'info_hash regenerated');
is_deeply($object->pieces_array(), $pieces_array, 'pieces_array regenerated');
is_deeply($object->{'data'}, $data, 'data reloaded correctly');

unlink $test_save;
