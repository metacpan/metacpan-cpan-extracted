use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes 'usleep';

use SPVM 'TestCase::Sys::Poll::PollfdArray';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

ok(SPVM::TestCase::Sys::Poll::PollfdArray->fields);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->new);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->fd);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->set_fd);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->events);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->set_events);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->revents);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->set_revents);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->push);

ok(SPVM::TestCase::Sys::Poll::PollfdArray->remove);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
