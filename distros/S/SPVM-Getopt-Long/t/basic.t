use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Getopt::Long';

use SPVM 'Getopt::Long';
use SPVM::Getopt::Long;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Getopt::Long->bool);

ok(SPVM::TestCase::Getopt::Long->bool_array);

ok(SPVM::TestCase::Getopt::Long->int);

ok(SPVM::TestCase::Getopt::Long->int_array);

ok(SPVM::TestCase::Getopt::Long->double);

ok(SPVM::TestCase::Getopt::Long->double_array);

ok(SPVM::TestCase::Getopt::Long->string);

ok(SPVM::TestCase::Getopt::Long->string_array);

ok(SPVM::TestCase::Getopt::Long->multiple_names);

ok(SPVM::TestCase::Getopt::Long->option_value);

ok(SPVM::TestCase::Getopt::Long->stop_parsing);

ok(SPVM::TestCase::Getopt::Long->extra);

ok(SPVM::TestCase::Getopt::Long->exceptions);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Getopt::Long");
  is($SPVM::Getopt::Long::VERSION, $version_string);
}

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
