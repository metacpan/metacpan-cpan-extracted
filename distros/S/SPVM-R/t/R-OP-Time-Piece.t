use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Time::Piece';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Time::Piece->c);
ok(SPVM::TestCase::R::OP::Time::Piece->eq);
ok(SPVM::TestCase::R::OP::Time::Piece->ne);
ok(SPVM::TestCase::R::OP::Time::Piece->gt);
ok(SPVM::TestCase::R::OP::Time::Piece->ge);
ok(SPVM::TestCase::R::OP::Time::Piece->lt);
ok(SPVM::TestCase::R::OP::Time::Piece->le);
ok(SPVM::TestCase::R::OP::Time::Piece->rep);
ok(SPVM::TestCase::R::OP::Time::Piece->rep_length);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
