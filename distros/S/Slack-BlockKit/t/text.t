use v5.36.0;
use Test::More;
use Test::Deep ':v1';
use Test::Deep::JType;
use Test::Fatal;

use Slack::BlockKit::Sugar '-all';

my $text = "This is some boring text.";

like(
  exception { text($text, { verbatim => 1 }) },
  qr/verbatim.+plain_text/,
  "can't use verbatim option in a plain text object",
);

like(
  exception { mrkdwn($text, { emoji => 1 }) },
  qr/emoji.+mrkdwn/,
  "can't use emoji option in a mrkdwn object",
);

cmp_deeply(
  mrkdwn($text, { verbatim => 1 })->as_struct,
  {
    type => 'mrkdwn',
    text => $text,
    verbatim => jtrue(),
  },
  "verbatim becomes a bool",
);

cmp_deeply(
  text($text, { emoji => 1 })->as_struct,
  {
    type  => 'plain_text',
    text  => $text,
    emoji => jtrue(),
  },
  "emoji becomes a bool",
);

done_testing;
