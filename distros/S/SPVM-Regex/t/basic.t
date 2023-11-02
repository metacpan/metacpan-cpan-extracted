use Test::More;

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'Fn';
use SPVM::Regex;

use SPVM 'TestCase::Regex';
use SPVM 'Regex';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

# SPVM::Regex
{

  ok(SPVM::TestCase::Regex->replace);
  ok(SPVM::TestCase::Regex->replace_g);
  ok(SPVM::TestCase::Regex->replace_common);
  ok(SPVM::TestCase::Regex->match_start_and_end);
  ok(SPVM::TestCase::Regex->match_capture);
  ok(SPVM::TestCase::Regex->match_char_class_range);
  ok(SPVM::TestCase::Regex->match_char_class_negate);
  ok(SPVM::TestCase::Regex->match_char_class);
  ok(SPVM::TestCase::Regex->match_not_space);
  ok(SPVM::TestCase::Regex->match_space);
  ok(SPVM::TestCase::Regex->match_not_word);
  ok(SPVM::TestCase::Regex->match_word);
  ok(SPVM::TestCase::Regex->match_not_number);
  ok(SPVM::TestCase::Regex->match_number);
  ok(SPVM::TestCase::Regex->match_end);
  ok(SPVM::TestCase::Regex->match_start);
  ok(SPVM::TestCase::Regex->match_quantifier);
  ok(SPVM::TestCase::Regex->match_one_or_zero);
  ok(SPVM::TestCase::Regex->match_one_more);
  ok(SPVM::TestCase::Regex->match_zero_more);
  ok(SPVM::TestCase::Regex->match_forward);
  ok(SPVM::TestCase::Regex->match);
  ok(SPVM::TestCase::Regex->split);
  ok(SPVM::TestCase::Regex->buffer_match);
  ok(SPVM::TestCase::Regex->buffer_match_forward);
  ok(SPVM::TestCase::Regex->buffer_replace);
  ok(SPVM::TestCase::Regex->buffer_replace_g);

  # Extra
  {

    {
      is(SPVM::TestCase::Regex->extra_url_escape("fooあbarい"), 'foo%E3%81%82bar%E3%81%84');
    };

    ok(SPVM::TestCase::Regex->extra);
    
    {
      is(SPVM::TestCase::Regex->extra_url_escape('business;23'), 'business%3B23');
    };

    {
      is(SPVM::TestCase::Regex->extra_url_escape('foobar123-._~'), 'foobar123-._~');
    };

    {
      is(SPVM::TestCase::Regex->extra_url_unescape('business%3B23'), 'business;23');
    };

    {
      is(SPVM::TestCase::Regex->extra_url_unescape('foobar123-._~'), 'foobar123-._~');
    };

    {
      is(SPVM::TestCase::Regex->extra_url_unescape('foo%E3%81%82bar%E3%81%84'), "fooあbarい");
    };
  }
}

# Version
{
  is($SPVM::Regex::VERSION, SPVM::Fn->get_version_string('Regex'));
}

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
