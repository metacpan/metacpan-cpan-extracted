use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use Cwd;

use SPVM 'Fn';

use SPVM::FindBin;

use SPVM 'FindBin';

use SPVM 'TestCase::FindBin';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count();

# init
SPVM::FindBin->init;

ok(SPVM::TestCase::FindBin->test);

is(SPVM::FindBin->Bin, "$FindBin::Bin");
is(SPVM::FindBin->Script, "$FindBin::Script");
is(SPVM::FindBin->RealBin, "$FindBin::RealBin");
is(SPVM::FindBin->RealScript, "$FindBin::RealScript");

SPVM::FindBin->again;

is(SPVM::FindBin->Bin, "$FindBin::Bin");
is(SPVM::FindBin->Script, "$FindBin::Script");
is(SPVM::FindBin->RealBin, "$FindBin::RealBin");
is(SPVM::FindBin->RealScript, "$FindBin::RealScript");

# Version
{
  is($SPVM::FindBin::VERSION, SPVM::Fn->get_version_string('FindBin'));
}

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
