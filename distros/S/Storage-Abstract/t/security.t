use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests some security edge cases
################################################################################

subtest 'should not allow leaving root in subpath' => sub {
	my $storage = Storage::Abstract->new(
		driver => 'subpath',
		source => {
			driver => 'directory',
			directory => '.',
			readonly => !!1,
		},
		subpath => 't',
	);

	like dies { $storage->is_stored('../Changes') }, qr{trying to leave root}, 'updir ok';
};

subtest 'should treat slashes and backslashes differently on unix' => sub {
	skip_all 'this test is designed only for unix'
		unless $^O =~ /bsd/i || $^O =~ /linux/i;

	my $storage = Storage::Abstract->new(
		driver => 'directory',
		directory => 't',
		readonly => !!1,
	);

	ok $storage->is_stored('paths.t'), 'sanity test ok';

	# try slash
	like dies { $storage->is_stored('../Changes') }, qr{trying to leave root}, 'slash 1 ok';
	ok $storage->is_stored('lib/../paths.t'), 'slash 2 ok';

	# try backslash - should be ignored (treated as a part of the path)
	ok !$storage->is_stored('..\Changes'), 'backslash 1 ok';
	ok !$storage->is_stored('lib\..\paths.t'), 'backslash 2 ok';
};

done_testing;

