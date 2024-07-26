use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::Hash';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::Hash->new);
ok(SPVM::TestCase::R::NDArray::Hash->set);
ok(SPVM::TestCase::R::NDArray::Hash->get);
ok(SPVM::TestCase::R::NDArray::Hash->get_byte);
ok(SPVM::TestCase::R::NDArray::Hash->get_short);
ok(SPVM::TestCase::R::NDArray::Hash->get_int);
ok(SPVM::TestCase::R::NDArray::Hash->get_long);
ok(SPVM::TestCase::R::NDArray::Hash->get_float);
ok(SPVM::TestCase::R::NDArray::Hash->get_float_complex);
ok(SPVM::TestCase::R::NDArray::Hash->get_double);
ok(SPVM::TestCase::R::NDArray::Hash->get_double_complex);
ok(SPVM::TestCase::R::NDArray::Hash->get_string);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
