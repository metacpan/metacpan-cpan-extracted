use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the subpath driver
################################################################################

my $nested_storage = Storage::Abstract->new(
	driver => 'memory',
);

my $storage = Storage::Abstract->new(
	driver => 'subpath',
	subpath => '/foo',
	source => $nested_storage,
);

$nested_storage->store('foo', \'foo');
$nested_storage->store('foo/bar', \'bar');
$nested_storage->store('foo/bar/baz', \'baz');

ok $storage->is_stored('bar/baz'), 'baz stored ok';
is slurp_handle($storage->retrieve('bar/baz', \my %info)), 'baz', 'baz content ok';
is $info{mtime}, within(time, 3), 'mtime ok';
is $info{size}, 3, 'size ok';

$storage->store('foo', \'foo2');
ok $nested_storage->is_stored('foo/foo'), 'nested foo stored ok';

is $storage->list, bag {
	item 'foo';
	item 'bar';
	item 'bar/baz';

	end();
}, 'file list ok';

$storage->dispose('foo');
ok !$storage->is_stored('foo'), 'nested foo disposed ok';

done_testing;

