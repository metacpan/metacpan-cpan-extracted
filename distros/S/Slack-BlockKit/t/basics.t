use v5.36.0;
use Test::More;
use Test::Deep ':v1';
use Test::Fatal;

use Slack::BlockKit;

like(
  exception { Slack::BlockKit::BlockCollection->new },
  qr/can't be empty/,
  "a block collection must have a blocks array",
);

like(
  exception { Slack::BlockKit::BlockCollection->new({ blocks => [] }) },
  qr/can't be empty/,
  "a block collection must have a non-empty blocks array",
);

{
  my $col = Slack::BlockKit::BlockCollection->new({
    blocks => [ Slack::BlockKit::Block::Divider->new ]
  });

  cmp_deeply(
    $col->as_struct,
    [ { type => 'divider' } ],
    "the simplest thing possible: just a divider",
  );
}

{
  my $e = exception {
    Slack::BlockKit::BlockCollection->new({ blocks => [
      Slack::BlockKit::BlockCollection->new({
        blocks => [ Slack::BlockKit::Block::Divider->new ]
      })
    ] })
  };

  like(
    $e,
    qr/with value.+BlockCollection/, # kinda vague, but gets point across
    "BlockCollections do not nest",
  );

  # Moose::Exception::ValidationFailedForInlineTypeConstraint but I'm not sure
  # I want to enshrine that in the test.
  isa_ok($e, 'Moose::Exception', 'the error we got');
}

done_testing;
