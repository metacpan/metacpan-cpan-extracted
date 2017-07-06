#!perl

use strict;
use warnings;

use MooX::Cmd::ChainedOptions ();

use Test2::Bundle::Extended;

like(
    dies { MooX::Cmd::ChainedOptions->import },
    qr/must use MooX::Cmd/,
    'incorrect importing package'
);

{
  package MyTest;
  use Moo;
  use MooX::Cmd execute_from_new => 0;
  with 'MooX::Cmd::ChainedOptions::Base';

  no warnings 'redefine';
  sub command_chain{ [] }
}

like(
    dies { MyTest->new->_parent  },
    qr/unable to determine parent/,
    'chain parent not available (should never occur)'
);

done_testing;
