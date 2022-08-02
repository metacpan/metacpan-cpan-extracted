use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'TestCase::Regex';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# SPVM::Regex
{
  ok(SPVM::TestCase::Regex->replace_g_cb== 1);
  ok(SPVM::TestCase::Regex->replace_g== 1);
  ok(SPVM::TestCase::Regex->replace== 1);
  ok(SPVM::TestCase::Regex->replace_cb== 1);
  ok(SPVM::TestCase::Regex->match_start_and_end== 1);
  ok(SPVM::TestCase::Regex->match_capture== 1);
  ok(SPVM::TestCase::Regex->match_char_class_range== 1);
  ok(SPVM::TestCase::Regex->match_char_class_negate== 1);
  ok(SPVM::TestCase::Regex->match_char_class== 1);
  ok(SPVM::TestCase::Regex->match_not_space== 1);
  ok(SPVM::TestCase::Regex->match_space== 1);
  ok(SPVM::TestCase::Regex->match_not_word== 1);
  ok(SPVM::TestCase::Regex->match_word== 1);
  ok(SPVM::TestCase::Regex->match_not_number== 1);
  ok(SPVM::TestCase::Regex->match_number== 1);
  ok(SPVM::TestCase::Regex->match_end== 1);
  ok(SPVM::TestCase::Regex->match_start== 1);
  ok(SPVM::TestCase::Regex->match_quantifier== 1);
  ok(SPVM::TestCase::Regex->match_one_or_zero== 1);
  ok(SPVM::TestCase::Regex->match_one_more== 1);
  ok(SPVM::TestCase::Regex->match_zero_more== 1);
  ok(SPVM::TestCase::Regex->match_offset== 1);
  ok(SPVM::TestCase::Regex->match== 1);
  
  # Extra
  {
    ok(SPVM::TestCase::Regex->extra== 1);
    is(SPVM::TestCase::Regex->extra_url_escape, 1);
  }
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
