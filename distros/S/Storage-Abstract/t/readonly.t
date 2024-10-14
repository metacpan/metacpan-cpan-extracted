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

	isa_ok $err, 'Storage::Abstract::X::StorageError';
	like $err, qr/is readonly/;
};

subtest 'should not be able to dispose' => sub {
	my $err = dies {
		$storage->dispose('foo');
	};

	isa_ok $err, 'Storage::Abstract::X::StorageError';
	like $err, qr/is readonly/;
};

done_testing;

