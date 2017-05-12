use strict;
use warnings;

use Test::More;

use Pod::Elemental::Types -all;

is(
  to_ChompedString("this is a string\n"),
  "this is a string",
  "we can 'autochomp'",
);

done_testing;
