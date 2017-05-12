#!perl
use strict;

use Test::More tests => 12;

use String::Formatter;

my $fmt = String::Formatter->new({
  codes => {
    a => "apples",
    b => "bananas",
    g => "grapefruits",
    m => "melons",
    w => "watermelons",
    '*' => 'brussel sprouts',
  },
});

{
  my $have = $fmt->format(qq(please have some %w\n));
  my $want = "please have some watermelons\n";

  is($have, $want, "formatting with no text after last code");
}

{
  my $have = $fmt->format(qq(w: %w\nb: %b\n));
  my $want = "w: watermelons\nb: bananas\n";

  is($have, $want, "format with multiple newlines");
}

{
  my $have = $fmt->format(q(10%% discount on %w));
  my $want = '10% discount on watermelons';

  is($have, $want, "%% -> %");
}

{
  my $have = $fmt->format(q(I like %a, %b, and %g, but not %m or %w.));
  my $want = 'I like apples, bananas, and grapefruits, '
           . 'but not melons or watermelons.';

  is($have, $want, "formatting with text after last code");
}

{
  my $have = $fmt->format(q(This has no stuff.));
  my $want = 'This has no stuff.';

  is($have, $want, "formatting with no %codes");
}

{
  my $ok    = eval { $fmt->format(q(What is %z for?)); 1 };
  my $error = $@;
  like($error, qr/Unknown conversion/i, 'unknown conversions are fatal');
}

{
  my $have = $fmt->format("We have %.5w.");
  my $want = "We have water.";
  is($have, $want, "truncate at max_chars");
}

{
  my $have = $fmt->format("We have %10a.");
  my $want = "We have     apples.";
  is($have, $want, "left-pad to reach min_chars");
}

{
  my $have = $fmt->format("We have %10.a.");
  my $want = "We have     apples.";
  is($have, $want, "left-pad to reach min_chars (with dot)");
}

{
  my $have = $fmt->format("We have %-10a.");
  my $want = "We have apples    .";
  is($have, $want, "right-pad to reach min_chars (-10)");
}

{
  my $have = $fmt->format('Please do not mention the %*.');
  my $want = 'Please do not mention the brussel sprouts.';
  is($have, $want, "non-identifier format characters");
}

{
  my $fmt = String::Formatter->new({
    input_processor => 'require_single_input',
    string_replacer => 'keyed_replace',

    codes => {
      g => 'groan',
      r => 'request',
    },
  });

  {
    my $zombie = {
        groan => 'nnnnngh',
        request => "Send... more...brainz...",
    };
    my $have = $fmt->format(q(%g... zombie says: %r), $zombie);
    my $want = "nnnnngh... zombie says: Send... more...brainz...";
    is($have, $want, "keyed_replace GOOD. fire BAD");
  }
}

