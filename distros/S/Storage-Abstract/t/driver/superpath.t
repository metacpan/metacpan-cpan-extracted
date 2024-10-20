use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the superpath driver
################################################################################

my $nested_storage = Storage::Abstract->new(
	driver => 'memory',
);

my $storage = Storage::Abstract->new(
	driver => 'superpath',
	superpath => '/foo',
	source => $nested_storage,
);

$nested_storage->store('foo', \'foo');
$nested_storage->store('bar', \'bar');
$nested_storage->store('bar/baz', \'baz');

ok $storage->is_stored('foo/bar/baz'), 'baz stored ok';
is slurp_handle($storage->retrieve('foo/bar/baz', \my %info)), 'baz', 'baz content ok';
is $info{mtime}, within(time, 3), 'mtime ok';
is $info{size}, 3, 'size ok';

$storage->store('foo/foo2', \'foo2');
ok $nested_storage->is_stored('foo2'), 'nested foo stored ok';

is $storage->list, bag {
	item 'foo/foo';
	item 'foo/foo2';
	item 'foo/bar';
	item 'foo/bar/baz';

	end();
}, 'file list ok';

$storage->dispose('foo/foo2');
ok !$storage->is_stored('foo/foo2'), 'nested foo disposed ok';

subtest 'should handle paths outside of superpath' => sub {
	ok !$storage->is_stored('bar'), 'is_stored ok';
	isa_ok dies { $storage->store('bar', \'bar') }, 'Storage::Abstract::X::Readonly';
	isa_ok dies { $storage->retrieve('bar') }, 'Storage::Abstract::X::NotFound';
	isa_ok dies { $storage->dispose('bar') }, 'Storage::Abstract::X::NotFound';
};

done_testing;

