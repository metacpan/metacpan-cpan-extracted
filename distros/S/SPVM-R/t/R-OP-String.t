use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::String';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::String->c);
ok(SPVM::TestCase::R::OP::String->concat);
ok(SPVM::TestCase::R::OP::String->eq);
ok(SPVM::TestCase::R::OP::String->ne);
ok(SPVM::TestCase::R::OP::String->gt);
ok(SPVM::TestCase::R::OP::String->ge);
ok(SPVM::TestCase::R::OP::String->lt);
ok(SPVM::TestCase::R::OP::String->le);
ok(SPVM::TestCase::R::OP::String->rep);
ok(SPVM::TestCase::R::OP::String->rep_length);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
