use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('String::Truncate', qw(elide trunc)); }

my $brain = "this is your brain";

is(
  elide($brain, 16, { truncate => 'ends' }),
  "... is your b...",
  "elide both ends",
);

eval { elide($brain, 5, { truncate => 'ends' }) };
like($@, qr/longer/, "marker can't exceed 1/2 length for end elision");

is(
  elide("I will use short ones to get more.", 20,
    { truncate => 'ends', at_space => 1 }
  ),
  "...short ones to...",
  "at_space lets us break betwen words (elide, at ends)",
);
