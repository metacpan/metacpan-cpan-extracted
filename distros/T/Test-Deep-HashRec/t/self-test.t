use strict;
use warnings;

use Test::Deep;
use Test::Deep::HashRec;
use Test::More;

sub rec {
  hashrec({
    required => { a => ignore },
    optional => { b => undef, c => superhashof({ deep => 1 }) },
  });
}

cmp_deeply(
  { a => 1 },
  rec(),
  "a1",
);

# cmp_deeply(
#   [],
#   rec(),
#   "top level bogus type",
# );
# 
# cmp_deeply(
#   { x => [] },
#   { x => rec() },
#   "deep bogus type",
# );
# 
# cmp_deeply(
#   { x => [] },
#   rec(),
#   "x",
# );
# 
# cmp_deeply(
#   { x => { a => 1, b => [] } },
#   { x => rec() },
#   "deep check fail",
# );
# 
# cmp_deeply(
#   { a => 1, b => undef },
#   rec(),
#   "a:1 b:undef",
# );
# 
# cmp_deeply(
#   { a => 1, b => 1 },
#   rec(),
#   "a:1 b:1",
# );

done_testing;
