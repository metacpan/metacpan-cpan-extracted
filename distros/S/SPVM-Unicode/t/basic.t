use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::Unicode';

use SPVM 'Unicode';
use SPVM::Unicode;
use SPVM 'Fn';

my $api = SPVM::api();

# Start objects count
my $start_memory_blocks_count = $api->get_memory_blocks_count();

{
  ok(SPVM::TestCase::Unicode->uchar);
  ok(SPVM::TestCase::Unicode->uchar_to_utf8);
  ok(SPVM::TestCase::Unicode->utf32_to_utf16);
  ok(SPVM::TestCase::Unicode->utf16_to_utf32);
  ok(SPVM::TestCase::Unicode->utf8_to_utf16);
  ok(SPVM::TestCase::Unicode->utf16_to_utf8);
  ok(SPVM::TestCase::Unicode->ERROR_INVALID_UTF8);
  ok(SPVM::TestCase::Unicode->is_unicode_scalar_value);
}

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Unicode");
  is($SPVM::Unicode::VERSION, $version_string);
}

# All object is freed
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
