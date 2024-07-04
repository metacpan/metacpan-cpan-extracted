use v5.36.0;
use Test::More;
use Test::Deep ':v1';
use Test::Fatal;

use Slack::BlockKit::Sugar '-all';

like(
  exception { header(mrkdwn("_Very_ Important")) },
  qr/non-plain_text text object provided to header/,
  "a header text object must be plain text",
);

cmp_deeply(
  header(text("Very Important"))->as_struct,
  {
    type => 'header',
    text => { type => 'plain_text', text => 'Very Important' },
  },
  "a boring header works",
);

done_testing;
