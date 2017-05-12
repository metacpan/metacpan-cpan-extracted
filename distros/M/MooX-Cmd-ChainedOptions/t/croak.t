#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MooX::Cmd::ChainedOptions ();

like(
    exception { MooX::Cmd::ChainedOptions->import },
    qr/must use MooX::Cmd/,
    'incorrect importing package'
);

{
  package T;
  use Moo;
  use MooX::Cmd execute_from_new => 0;
  with 'MooX::Cmd::ChainedOptions::Base';

  no warnings 'redefine';
  sub command_chain{ [] }
}

like(
    exception { T->new->_parent },
    qr/unable to determine parent/,
    'chain parent not available (should never occur)'
);

done_testing;