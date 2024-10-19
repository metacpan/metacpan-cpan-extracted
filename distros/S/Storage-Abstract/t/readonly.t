use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests whether it's impossible to store in a readonly driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

$storage->store('foo', get_testfile_handle);
$storage->store('bar', get_testfile_handle);
$storage->set_readonly(1);

subtest 'should not be able to store' => sub {
	my $err = dies {
		$storage->store('some/file', get_testfile_handle);
	};

	isa_ok $err, 'Storage::Abstract::X::Readonly';
	like $err, qr/is readonly/;
};

subtest 'should not be able to dispose' => sub {
	my $err = dies {
		$storage->dispose('foo');
	};

	isa_ok $err, 'Storage::Abstract::X::Readonly';
	like $err, qr/is readonly/;
};

my $metastorage = Storage::Abstract->new(
	driver => 'Subpath',
	source => $storage,
	subpath => '/test',
);

ok $metastorage->readonly, 'readonly ok';

$metastorage->set_readonly(0);
ok !$metastorage->readonly, 'readonly removed ok';
ok !$storage->readonly, 'readonly removed from source ok';

$storage->set_readonly(1);
ok $metastorage->readonly, 'readonly added to source ok';

my $composite_metastorage = Storage::Abstract->new(
	driver => 'composite',
	source => [$storage],
);

ok $composite_metastorage->readonly, 'composite readonly ok';
ok dies { $composite_metastorage->set_readonly(0) }, 'composite readonly setter dies ok';

done_testing;

