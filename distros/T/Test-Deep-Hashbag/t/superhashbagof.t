use strict;
use warnings;

use lib 't/lib';
use TDHTester;

use Test::Tester;
use Test::More 0.88;
use Test::Fatal;

use Test::Deep;
use Test::Deep::Hashbag;

# Good cases

good_test(
  {
    cat => 'meow',
    dog => 'woof',
    bird => 'tweet'
  },
  superhashbagof(
    cat => 'meow',
    ignore() => 'woof'
  ),
  "superhashbagof, 1 required key, 1 ignored key",
);

good_test(
  {
    cat => 'meow',
    dog => 'woof',
    bird => 'tweet'
  },
  superhashbagof(
    cat => 'meow',
    dog => 'woof'
  ),
  "superhashbagof 2 required keys, no ignored keys",
);

good_test(
  {
    cat => 'meow',
    dog => 'woof',
    bird => 'tweet'
  },
  superhashbagof(
    ignore() => 'meow',
    ignore() => 'woof'
  ),
  "superhashbagof no required keys, 2 ignored keys",
);

# Bad cases

bad_test(
  {
    cat => 'meow',
    dog => 'woof'
  },
  superhashbagof(
    cat => 'meow',
    ignore() => 'woof',
    bird => 'tweet',
  ),
  <<EOF,
Comparing hash keys of \$data
Missing: 'bird'
EOF
  "superhashbagof missing a required key",
);

bad_test(
  {
    cat => 'meow',
    dog => 'neigh'
  },
  superhashbagof(
    cat => 'meow',
    dog => 'woof'
  ),
  <<EOF,
Compared \$data->{"dog"}
   got : 'neigh'
expect : 'woof'
EOF
  "superhashbagof required key has wrong value",
);

bad_test(
  {
    cat => 'meow',
    dog => 'woof',
    bird => 'tweet'
  },
  superhashbagof(
    ignore() => 'meow',
    ignore() => 'chirp'
  ),
  <<EOF,
Comparing \$data
Failed to find all required items in the remaining hash keys.
Expected to match 2 items, best case match was 1.
Keys with no match: 'bird', 'dog'
Matchers that failed to match:
\$VAR1 = [
          'chirp'
        ];
EOF
  'superhashbagof one ignored key had no matching value',
);

bad_test(
  { },
  superhashbagof(ignore() => 'woof'),
  <<EOF,
Comparing \$data
Failed to find all required items in the remaining hash keys.
Expected to match 1 items, best case match was 0.
Keys with no match: 
Matchers that failed to match:
\$VAR1 = [
          'woof'
        ];
EOF
  'superhashbagof when no data to test detects missing matchers',
);

bad_test(
  {
    cat => 'meow',
  },
  superhashbagof(
    cat => 'meow',
    ignore() => 'woof'
  ),
  <<EOF,
Comparing \$data
Failed to find all required items in the remaining hash keys.
Expected to match 1 items, best case match was 0.
Keys with no match: 
Matchers that failed to match:
\$VAR1 = [
          'woof'
        ];
EOF
  'superhashbagof when no data to test after required keys detects missing matchers',
);

done_testing;
