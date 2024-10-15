use Test2::V0;
use Storage::Abstract;
use Storage::Abstract::Driver::Null;

################################################################################
# This tests whether constructor works as expected
################################################################################

my $driver = Storage::Abstract::Driver::Null->new;

subtest 'should construct using full namespace' => sub {
	my $storage = Storage::Abstract->new(
		driver => '+Storage::Abstract::Driver::Null',
	);

	isa_ok $storage->driver, 'Storage::Abstract::Driver::Null';
};

subtest 'should construct using hash' => sub {
	my $storage = Storage::Abstract->new(
		driver => $driver,
	);

	is $storage->driver, $driver, 'driver ok';
};

subtest 'should construct using hash reference' => sub {
	my $storage = Storage::Abstract->new(
		{
			driver => $driver,
		}
	);

	is $storage->driver, $driver, 'driver ok';
};

done_testing;

