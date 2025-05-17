use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use Cwd;

use SPVM 'Fn';

use SPVM 'FindBin';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count();

# Perl $FindBin::Bin resolve symbolic link, but SPVM dose not do.

warn "[Test Output]FindBin->Bin:" . SPVM::FindBin->Bin;

is(SPVM::FindBin->Bin, $FindBin::Bin);

warn "[Test Output]FindBin->Script:" . SPVM::FindBin->Script;

is(SPVM::FindBin->Script, $FindBin::Script);

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
