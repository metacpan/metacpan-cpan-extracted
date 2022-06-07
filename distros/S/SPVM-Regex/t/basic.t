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
  ok(SPVM::TestCase::Regex->replace_all_cb);
  ok(SPVM::TestCase::Regex->replace_all);
  ok(SPVM::TestCase::Regex->replace);
  ok(SPVM::TestCase::Regex->replace_cb);
  ok(SPVM::TestCase::Regex->match_start_and_end);
  ok(SPVM::TestCase::Regex->match_capture);
  ok(SPVM::TestCase::Regex->match_char_class_range);
  ok(SPVM::TestCase::Regex->match_char_class);
  ok(SPVM::TestCase::Regex->match_char_class_negate);
  ok(SPVM::TestCase::Regex->match_not_space);
  ok(SPVM::TestCase::Regex->match_space);
  ok(SPVM::TestCase::Regex->match_not_word);
  ok(SPVM::TestCase::Regex->match_word);
  ok(SPVM::TestCase::Regex->match_number);
  ok(SPVM::TestCase::Regex->match_not_number);
  ok(SPVM::TestCase::Regex->match_end);
  ok(SPVM::TestCase::Regex->match_start);
  ok(SPVM::TestCase::Regex->match_quantifier);
  ok(SPVM::TestCase::Regex->match_one_or_zero);
  ok(SPVM::TestCase::Regex->match_zero_more);
  ok(SPVM::TestCase::Regex->match_one_more);
  ok(SPVM::TestCase::Regex->match_offset);
  ok(SPVM::TestCase::Regex->match);
  ok(SPVM::TestCase::Regex->compile);
  ok(SPVM::TestCase::Regex->extra);
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
