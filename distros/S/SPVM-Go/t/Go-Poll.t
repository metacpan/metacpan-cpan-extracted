use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use TestUtil::ServerRunner;

use SPVM 'TestCase::Go::Poll';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

{
  my $server = TestUtil::ServerRunner->new(
    code => sub {
      my ($port) = @_;
      
      TestUtil::ServerRunner->run_echo_server($port);
    },
  );
  
  ok(SPVM::TestCase::Go::Poll->basic($server->port));
}

{
  my $server = TestUtil::ServerRunner->new(
    code => sub {
      my ($port) = @_;
      
      TestUtil::ServerRunner->run_echo_server($port);
    },
  );
  
  ok(SPVM::TestCase::Go::Poll->parallel($server->port));
}

{
  my $server = TestUtil::ServerRunner->new(
    code => sub {
      my ($port) = @_;
      
      TestUtil::ServerRunner->run_echo_server($port);
    },
  );
  
  ok(SPVM::TestCase::Go::Poll->timeout($server->port));
}

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
