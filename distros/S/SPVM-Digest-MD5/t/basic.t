use Test::More;

use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::Digest::MD5';

use SPVM 'Digest::MD5';
use SPVM::Digest::MD5;
use SPVM 'Fn';

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# SPVM::Digest::MD5
{
  # Class Methods
  {
    # md5
    ok(SPVM::TestCase::Digest::MD5->md5);
    
    # md5_hex
    ok(SPVM::TestCase::Digest::MD5->md5_hex);
    
    # new
    ok(SPVM::TestCase::Digest::MD5->new);
  }
  
  # Instance Methods
  {
    # add
    ok(SPVM::TestCase::Digest::MD5->add);
    
    # digest
    ok(SPVM::TestCase::Digest::MD5->digest);
    
    # hexdigest
    ok(SPVM::TestCase::Digest::MD5->hexdigest);
  }
}

# Version
{
  is($SPVM::Digest::MD5::VERSION, SPVM::Fn->get_version_string('Digest::MD5'));
}

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
