use Test2::V0;
use Storage::Abstract;
use Data::Dumper;

use lib 't/lib';
use Storage::Abstract::Test;
use File::Spec;

################################################################################
# This tests the composite driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'composite',
	sources => [
		{
			driver => 'directory',
			directory => File::Spec->catdir(File::Spec->curdir, qw(t testfiles)),
			readonly => !!1,
		},
		Storage::Abstract->new(
			driver => 'memory',
		),
	],
);

ok $storage->is_stored('page.html'), 'page.html stored ok';
ok $storage->is_stored('utf8.txt'), 'utf8 stored ok';
ok !$storage->is_stored('foo'), 'foo not stored ok';

ok lives {
	$storage->store('foo', get_testfile_handle);
	ok $storage->is_stored('foo'), 'foo stored ok';
} or diag(Dumper($storage->driver->errors));

ok !$storage->driver->sources->[0]->is_stored('foo'), 'not stored in readonly driver ok';
ok $storage->driver->sources->[1]->is_stored('foo'), 'stored in memory driver ok';

is slurp_handle($storage->retrieve('foo')), slurp_handle($storage->retrieve('page.html')), 'new file ok';

$storage->retrieve('foo', \my %info);
is $info{mtime}, within(time, 3), 'mtime ok';
is $info{size}, get_testfile_size, 'size ok';

is $storage->list, bag {
	item 'foo';
	item 'page.html';
	item 'utf8.txt';
	item 'deeply/nested.txt';
	item 'deeply/nested/file.txt';

	end();
},
	'file list ok';

$storage->dispose('foo');
ok !$storage->is_stored('foo'), 'foo disposed ok';

# check if various driver-specific methods exist
ok lives {
	$storage->driver->sources;
	$storage->driver->errors;
	$storage->driver->clear_cache;
};

done_testing;

