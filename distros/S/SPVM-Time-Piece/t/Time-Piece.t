use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Time::Piece';

use SPVM 'Time::Piece';
use SPVM::Time::Piece;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

{
  ok(SPVM::TestCase::Time::Piece->localtime);
}

{
  ok(SPVM::TestCase::Time::Piece->gmtime);
}

{
  ok(SPVM::TestCase::Time::Piece->strftime);
}

{
  ok(SPVM::TestCase::Time::Piece->accessors);
}

{
  ok(SPVM::TestCase::Time::Piece->tzoffset);
}

{
  ok(SPVM::TestCase::Time::Piece->julian_day);
}

{
  ok(SPVM::TestCase::Time::Piece->mjd);
}

{
  ok(SPVM::TestCase::Time::Piece->week);
}

{
  ok(SPVM::TestCase::Time::Piece->is_leap_year);
}

{
  ok(SPVM::TestCase::Time::Piece->month_last_day);
}

{
  ok(SPVM::TestCase::Time::Piece->strftime);
}

{
  ok(SPVM::TestCase::Time::Piece->strptime);
}

{
  ok(SPVM::TestCase::Time::Piece->localtime_tp);
}

{
  ok(SPVM::TestCase::Time::Piece->clone);
}

{
  ok(SPVM::TestCase::Time::Piece->truncate);
}

{
  ok(SPVM::TestCase::Time::Piece->add);
}

{
  ok(SPVM::TestCase::Time::Piece->subtract);
}

{
  ok(SPVM::TestCase::Time::Piece->subtract_tp);
}

{
  ok(SPVM::TestCase::Time::Piece->compare);
}

{
  ok(SPVM::TestCase::Time::Piece->add_months);
}

{
  ok(SPVM::TestCase::Time::Piece->add_years);
}

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Time::Piece");
  is($SPVM::Time::Piece::VERSION, $version_string);
}

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
