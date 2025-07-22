use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Object::Configure') }

# Define our test class
{
	package My::EnvTest::Class;
	use Object::Configure;

	sub new {
		my ($class, %args) = @_;
		my $params = Object::Configure::configure($class, \%args);
		return bless $params, $class;
	}
}

local %ENV;

# Mock environment variables with the expected prefix
$ENV{'My__EnvTest__Class__env_flag'} = 'true';
$ENV{'My__EnvTest__Class__level'} = 'debug';

# Create the object without passing those values explicitly
my $obj = My::EnvTest::Class->new(foo => 'bar');

isa_ok($obj, 'My::EnvTest::Class', 'object created with env overrides');

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

# Confirm values came from %ENV
is($obj->{env_flag}, 'true', 'env_flag read from environment');
is($obj->{level}, 'debug', 'level read from environment');

# Ensure values not set via env are preserved
is($obj->{foo}, 'bar', 'non-env value preserved');

# Logger should still be initialized
ok($obj->{logger}, 'logger initialized');
isa_ok($obj->{logger}, 'Log::Abstraction');

# Clean up environment variables
# delete $ENV{'My::EnvTest::Class::env_flag'};
# delete $ENV{'My::EnvTest::Class::level'};

done_testing();
