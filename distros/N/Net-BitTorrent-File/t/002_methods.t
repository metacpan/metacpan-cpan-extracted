# -*- perl -*-

# t/002_methods.t - check module for setting and retrieving propertys

use Test::More qw(no_plan);

BEGIN { use_ok( 'Net::BitTorrent::File' ); }

my $test_string = 'Test string';
my $test_number = 42;
my $test_pieces = 'AAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBB';
my $pieces_array = ['AAAAAAAAAAAAAAAAAAAA','BBBBBBBBBBBBBBBBBBBB'];
my $info = {
		files => 'nothing',
		pieces => $test_pieces,
		length => 42,
		piece_length => 2**18,
		name => 'test data'
	};
my $files = [{length => 1, path => 'a'}, {length => 2, path => 'b'}];

my $object = Net::BitTorrent::File->new ();
isa_ok ($object, 'Net::BitTorrent::File', 'empty object');

$object->name($test_string);
is($object->name(), $test_string, 'setting name');
$object->announce($test_string);
is($object->announce(), $test_string, 'setting announce');
$object->piece_length($test_number);
is($object->piece_length(), $test_number, 'setting piece_length');
$object->length($test_number);
is($object->length(), $test_number, 'setting length');
$object->pieces($test_pieces);
is($object->pieces(), $test_pieces, 'setting pieces');
$object->gen_pieces_array();
is_deeply($object->pieces_array(), $pieces_array, 'generating pieces array');
$object->files($files);
is_deeply($object->files(), $files, 'setting files');
$object->info($info);
is_deeply($object->info(), $info, 'setting info');
$object->gen_info_hash();
isnt($object->info_hash(), undef, 'generating info hash');
