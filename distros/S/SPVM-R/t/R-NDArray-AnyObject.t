use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::AnyObject';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::AnyObject->data);
ok(SPVM::TestCase::R::NDArray::AnyObject->new);
ok(SPVM::TestCase::R::NDArray::AnyObject->create_default_data);
ok(SPVM::TestCase::R::NDArray::AnyObject->elem_to_string);
ok(SPVM::TestCase::R::NDArray::AnyObject->elem_assign);
ok(SPVM::TestCase::R::NDArray::AnyObject->elem_assign);
ok(SPVM::TestCase::R::NDArray::AnyObject->elem_clone);
ok(SPVM::TestCase::R::NDArray::AnyObject->elem_cmp);
ok(SPVM::TestCase::R::NDArray::AnyObject->clone);
ok(SPVM::TestCase::R::NDArray::AnyObject->slice);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
