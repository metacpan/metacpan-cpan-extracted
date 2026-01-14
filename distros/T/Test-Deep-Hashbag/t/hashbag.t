use strict;
use warnings;

use lib 't/lib';
use TDHTester;

use Test::More 0.88;
use Test::Fatal;

use Test::Deep;
use Test::Deep::Hashbag;

# Good cases

good_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(cat => 'meow', ignore() => 'woof'),
  "1 required key, 1 ignored key",
);

good_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(cat => 'meow', dog => 'woof'),
  "2 required keys, no ignored keys",
);

good_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(ignore() => 'meow', ignore() => 'woof'),
  "no required keys, 2 ignored keys",
);

good_test(
  {
    cat => {
      talk => 'meow',
      eat  => 'milk',
    },
    dog => {
      talk => 'woof',
      eat  => 'anything',
    },
  },
  hashbag(
    ignore() => hashbag(ignore() => 'meow', ignore() => ignore()),
    ignore() => hashbag(ignore() => 'woof', ignore() => ignore()),
  ),
  'hashbag containing hashbags',
);

good_test(
  {
    first  => 'abcdef',
    second => 'abcdefg',
    third  => 'abcdefgh',
    fourth => 'abcdefghi',
  },
  hashbag(
    ignore() => re('a.*'),    # match all
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*g.?$'), # match second and third
    ignore() => re('a.*h.?$'), # match third and fourth
  ),
  'expects that match multiple items collapse properly',
);

good_test(
  {
    first  => 'abcdef',
    second => 'abcdefg',
    third  => 'abcdefgh',
    fourth => 'abcdefghi',
    map { $_ => $_ } 'a'..'z',
  },
  hashbag(
    ignore() => re('a.*'),     # match many
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*g.?$'), # match second and third
    ignore() => re('a.*h.?$'), # match third and fourth
    map { ignore() => $_ } 'a'..'z',
  ),
  'large data sets are quick to compute solutions',
);

# Bad cases
my $arr = [];
my $arr_str = "$arr";

bad_test(
  $arr,
  hashbag(cat => 'meow'),
  <<EOF,
Comparing \$data
got    : $arr_str
expect : A hashref
EOF
  "testing against a non-hashref",
);

bad_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(cat => 'meow', bird => 'tweet', ignore() => 'woof'),
  <<EOF,
Comparing hash keys of \$data
Missing: 'bird'
EOF
  "missing a required key",
);

bad_test(
  { cat => 'meow', dog => 'neigh' },
  hashbag(cat => 'meow', dog => 'woof'),
  <<EOF,
Compared \$data->{"dog"}
   got : 'neigh'
expect : 'woof'
EOF
  "required key has wrong value",
);

bad_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(ignore() => 'meow'),
  <<EOF,
Comparing \$data
We expected 1 ignored() keys, but we found 2 keys left?
Remaining keys: 'cat', 'dog'
EOF
  "expected 1 ignored key, had 2 keys",
);

bad_test(
  { cat => 'meow', dog => 'woof' },
  hashbag(ignore() => 'meow', ignore() => 'chirp'),
  <<EOF,
Comparing \$data
Failed to find all required items in the remaining hash keys.
Expected to match 2 items, best case match was 1.
Keys with no match: 'dog'
Matchers that failed to match:
\$VAR1 = [
          'chirp'
        ];
EOF
  'one ignored key had no matching value',
);

# Here, the first regexp could match the third element, and the
# other regexps all match the first and second element, leaving
# 'fourth' with no match. We can easily detect this case and provide
# useful feedback
bad_test(
  {
    first  => 'abcdef',
    second => 'abcdefg',
    third  => 'abcdefgh',
    fourth => 'abcdefghi',
  },
  hashbag(
    ignore() => re('a.*'),     # match all
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
  ),
  [
    qr/Comparing \$data/,
    qr/\QFailed to find all required items in the remaining hash keys.\E/,
    qr/\QExpected to match 4 items, best case match was 3.\E/,
    qr/Keys with no match: '(fourth|third)'/,
    qr/\QMatchers that failed to match:\E/,
    qr/\$VAR1\Q = [\E/,
    qr/\Qbless( {\E/,
    qr/\Q'val' => qr\/a.*f.?\E\$\Q\/\E/,
    qr/\Q}, 'Test::Deep::Regexp' )\E/,
    qr/\Q];\E/,
  ],
  'matchers match multiple keys but one value has no matcher',
);

# Here, all elements had at least 2 matches, but we could not collapse
# all possibilities down to a case where each element is matched at least
# once.
bad_test(
  {
    first  => 'abcdef',
    second => 'abcdefg',
    third  => 'abcdefgh',
    fourth => 'abcdefghi',
    fifth  => 'abcdefghij',
  },
  hashbag(
    ignore() => re('a.*'),     # match all
    ignore() => re('a.*'),     # match all
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
  ),
  [
    qr/Comparing \$data/,
    qr/\QFailed to find all required items in the remaining hash keys.\E/,
    qr/\QExpected to match 5 items, best case match was 4.\E/,
    qr/Keys with no match: '(third|fourth|fifth)'/,
    qr/\QMatchers that failed to match:\E/,
    qr/\$VAR1\Q = [\E/,
    qr/\Qbless( {\E/,
    qr/\Q'val' => qr\/a.*f.?\E\$\Q\/\E/,
    qr/\Q}, 'Test::Deep::Regexp' )\E/,
    qr/\Q];\E/,
  ],
  'all keys matched at least twice but no solution',
);

# Like above, but with a lot of possiblities to ensure we detect failures
# quickly
bad_test(
  {
    first  => 'abcdef',
    second => 'abcdefg',
    third  => 'abcdefgh',
    fourth => 'abcdefghi',
    fifth  => 'abcdefghij',
    map { $_ => $_ } 'a'..'z',
  },
  hashbag(
    ignore() => re('a.*'),     # match many
    ignore() => re('a.*'),     # match many
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
    ignore() => re('a.*f.?$'), # match first and second
    map { ignore() => $_ } 'a'..'z',
  ),
  [
    qr/Comparing \$data/,
    qr/\QFailed to find all required items in the remaining hash keys.\E/,
    qr/\QExpected to match 31 items, best case match was 30.\E/,
    qr/Keys with no match: '(third|fourth|fifth)'/,
    qr/\QMatchers that failed to match:\E/,
    qr/\$VAR1\Q = [\E/,
    qr/\Qbless( {\E/,
    qr/\Q'val' => qr\/a.*f.?\E\$\Q\/\E/,
    qr/\Q}, 'Test::Deep::Regexp' )\E/,
    qr/\Q];\E/,
  ],
  'with lots of possibilities we detect failures quickly still',
);

# Exceptions
like(
  exception {
    hashbag(cat => 'meow', cat => 'woof');
  },
  qr/Duplicate key 'cat' passed to hashbag/,
  "duplicate keys check",
);

like(
  exception {
    hashbag('meow'),
  },
  qr/hashbag needs an even list of pairs/,
  "odd number of items passed in check",
);

like(
  exception {
    hashbag([] => 'uhoh'),
  },
  qr/hashbag keys must be simple scalars.*got: ARRAY/,
  "refs / blessed objects as keys that aren't ignore()",
);

# END #

done_testing;
