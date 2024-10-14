use Test2::V0;
use Storage::Abstract;

################################################################################
# This tests whether file path resolving works as expected
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Null',
);

# test invalid paths
my $err;

subtest 'path is empty' => sub {
	$err = dies { $storage->is_stored('') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/is empty/;
};

subtest 'path has no filename' => sub {
	$err = dies { $storage->is_stored('.') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/has no filename/;

	$err = dies { $storage->is_stored('/') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/has no filename/;

	$err = dies { $storage->is_stored('a/') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/has no filename/;
};

subtest 'path is trying to leave root' => sub {
	$err = dies { $storage->is_stored('..') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/trying to leave root/;

	$err = dies { $storage->is_stored('../a') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/trying to leave root/;

	$err = dies { $storage->is_stored('a/../../b') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/trying to leave root/;

	$err = dies { $storage->is_stored('./../a') };
	isa_ok $err, 'Storage::Abstract::X::PathError';
	like $err, qr/trying to leave root/;
};

# test valid paths
subtest 'path is valid and stored' => sub {
	ok !$storage->is_stored('a/b/c/d'), 'stored ok';
	ok !$storage->is_stored('/a/b/c/d'), 'stored ok';
	ok !$storage->is_stored('./a/b/c/d'), 'stored ok';
	ok !$storage->is_stored('a/b/c/d/../d'), 'stored ok';
	ok !$storage->is_stored('./a/../a/b/../b/c/../c/././d'), 'stored ok';
};

done_testing;

