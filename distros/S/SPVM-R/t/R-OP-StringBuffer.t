use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::StringBuffer';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::StringBuffer->c);
ok(SPVM::TestCase::R::OP::StringBuffer->push);
ok(SPVM::TestCase::R::OP::StringBuffer->eq);
ok(SPVM::TestCase::R::OP::StringBuffer->ne);
ok(SPVM::TestCase::R::OP::StringBuffer->gt);
ok(SPVM::TestCase::R::OP::StringBuffer->ge);
ok(SPVM::TestCase::R::OP::StringBuffer->lt);
ok(SPVM::TestCase::R::OP::StringBuffer->le);
ok(SPVM::TestCase::R::OP::StringBuffer->rep);
ok(SPVM::TestCase::R::OP::StringBuffer->rep_length);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
