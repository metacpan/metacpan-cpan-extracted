use strict;
use warnings;
use Test::More 0.88;

{
  package Test::MooseX::Types::Structured::IncorrectMessage;

  use Moose;
  use MooseX::Types::Moose qw(Str Int);
  use MooseX::Types::Structured qw(Tuple Dict);
  use MooseX::Types -declare => [qw(WrongMessage MyInt)];

  subtype MyInt,
    as Int,
    message { 'Oh, my Int!' };

  subtype WrongMessage,
    as Dict[name=>Str, age=>MyInt];

  has 'person' => (
    is  => 'rw',
    required => 1,
    isa => WrongMessage,
  );
}

my %init_args = (
  person => {
    name => 'a',
    age => 'v',
  },
);

SKIP: {
  skip 'Deeper Error Messges not yet supported', 1,1;

  ok(
    Test::MooseX::Types::Structured::IncorrectMessage->new(%init_args),
    'Made a class',
  );
}

done_testing;
