use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes 'usleep';

use Socket;
use IO::Socket;
use IO::Socket::INET;
use TestUtil::Socket;

use SPVM 'Sys::Ioctl';
use SPVM 'TestCase::Sys::Ioctl';

my $localhost = "127.0.0.1";

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Port
my $port = TestUtil::Socket::search_available_port;

ok(SPVM::TestCase::Sys::Ioctl->ioctl($port));

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
