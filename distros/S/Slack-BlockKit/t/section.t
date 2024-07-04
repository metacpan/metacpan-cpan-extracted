use v5.36.0;
use Test::More;
use Test::Deep ':v1';
use Test::Fatal;

use Slack::BlockKit::Sugar '-all';

my $text      = "This is some boring text.";
my $text_obj  = text($text);

like(
  exception { section({ }) },
  qr/neither text nor fields provided/,
  "you must provide either text or fields (not neither)",
);

like(
  exception {
    section({ fields => [ $text_obj ], text => $text_obj }),
  },
  qr/both text and fields provided/,
  "you must provide either text or fields (not both)",
);

cmp_deeply(
  section({ fields => [ $text_obj ] })->as_struct,
  {
    type => 'section',
    fields => [
      { type => 'plain_text', text => $text },
    ],
  },
  "a boring section becomes the structure we expect",
);

done_testing;
