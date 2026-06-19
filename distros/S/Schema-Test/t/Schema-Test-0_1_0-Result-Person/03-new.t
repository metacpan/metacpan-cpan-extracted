use strict;
use warnings;

use Schema::Test::0_1_0::Result::Person;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $source = Schema::Test::0_1_0::Result::Person->result_source_instance;
my $obj = Schema::Test::0_1_0::Result::Person->new({
	-result_source => $source,
});
isa_ok($obj, 'Schema::Test::0_1_0::Result::Person');
isa_ok($obj, 'DBIx::Class::Core');
