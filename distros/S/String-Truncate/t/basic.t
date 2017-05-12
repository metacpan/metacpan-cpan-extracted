use strict;
use warnings;

use Test::More 0.88;

BEGIN { use_ok('String::Truncate', qw(elide trunc)); }

my $brain = "this is your brain";
# len: 18 -- 123456789012345678

my %code = (
  elide   => \&elide,
  trunc   => \&trunc,
  'S:T:e' => String::Truncate->can('elide'),
  'S:T:t' => String::Truncate->can('trunc'),
);

while (my ($name, $code) = each %code) {
  is(
    $code->($brain, 50),
    "this is your brain",
    "don't $name short strings",
  );

  is(
    $code->($brain, 18),
    $brain,
    "don't $name exact-length strings",
  );
}

is(
  elide($brain, 16),
  "this is your ...",
  "right-side elide example",
);

is(
  trunc($brain, 16),
  "this is your bra",
  "right-side trunc example",
);

is(
  elide($brain, 16, { truncate => 'left' }),
  "...is your brain",
  "left-side elide example",
);

is(
  trunc($brain, 16, { truncate => 'left' }),
  "is is your brain",
  "left-side trunc example",
);

is(
  elide($brain, 16, { truncate => 'middle' }),
  "this is... brain",
  "middle-side elide example",
);

is(
  trunc($brain, 16, { truncate => 'middle' }),
  "this is ur brain",
  "middle-side trunc example",
);

is(
  elide($brain, 16, { truncate => 'middle', marker => '..' }),
  "this is..r brain",
  "middle-side elide example with short marker",
);

is(
  elide($brain, 15, { truncate => 'middle', marker => '..' }),
  "this is.. brain",
  "middle-side example with short marker and side-length mismatch",
);

eval { elide($brain, 2) };
like($@, qr/longer/, "can't truncate to less than marker");

eval { elide($brain, 20, { truncate => 'backside' }) };
like($@, qr/invalid/, "only left|right|middle are valid");

eval { trunc($brain, 16, { truncate => 'middle', marker => '..' }); };
like($@, qr/marker may not be passed/, "can't pass marker to trunc");

is(
  elide($brain, 10, { marker => ' &c.' }),
  "this i &c.",
  "custom marker",
);

is(
  elide("foobar", 6),
  "foobar",
  "we don't elide anything if length == maxlength",
);

is(
  elide("!!", 2),
  "!!",
  "we don't care about marker length if marker isn't needed",
);

is(
  elide("foobar", 5),
  "fo...",
  "keep-left elision of a very short string",
);

is(
  #      12345678901234567890123456789012
  trunc("This should break between words.", 14, { at_space => 1 }),
  "This should",
  "at_space lets us break betwen words (at right)",
);

{
  my $s = 'a ' x 20 . "\n\n" . 'b ' x 20;

  like(
    elide($s, 50, { at_space => 1 }),
    qr/b/,
    "newlines don't break at_space",
  );
}

is(
  #      12345678901234567890123456789012
  trunc("This should break between words.", 14, { at_space => 1 }),
  "This should",
  "at_space lets us break betwen words (at right)",
);

is(
  #      21098765432109876543210987654321
  trunc("This should break between words.", 14,
    { truncate => 'left', at_space => 1 }
  ),
  "between words.",
  "at_space lets us break betwen words (at left)",
);

is(
  #      12345678901234567890123456789012
  elide("This should break between words.", 14, { at_space => 1 }),
  "This should...",
  "at_space lets us break betwen words (elide, at right)",
);

is(
  #      21098765432109876543210987654321
  elide("This should break between words.", 14,
    { truncate => 'left', at_space => 1 }
  ),
  "...words.",
  "at_space lets us break betwen words (elide, at left)",
);

is(
  #      12345678901234567890123456789012
  elide("This should break between words.", 20,
    { truncate => 'middle', at_space => 1 }
  ),
  "This...words.",
  "at_space lets us break betwen words (elide, at middle)",
);

is(
  #      123456789012345678901234567890123
  elide("Thisisonereallylongstringnospace.", 20, { at_space => 1 }),
  "Thisisonereallylo...",
  "if it can't break at a word boundary, it breaks as late as possible",
);

done_testing;
