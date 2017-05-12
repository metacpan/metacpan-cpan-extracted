#! /usr/bin/perl
#
# tests Params::Validate::Checks pos_int check does what's required

use warnings;
use strict;

use Test::Most 0.23;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
  use_ok 'Params::Validate::Checks::Integer', qw<validate as>
      or die "Loading Params::Validate::Checks::Integer failed";
};

sub square
{
  my %arg = validate @_, {num => {as 'integer'}};

  $arg{num} * $arg{num};
}

lives_and { is square(num => 256), 65536 }
    'allows multi-digit numbers';

lives_and { is square(num => 0), 0 }
    'zero ok';

lives_and { is square(num => -5), 25 }
    'negative ints ok';

throws_ok { square(num => 2.4) }
     qr/did not pass the 'integer' callback/
   ,'complains at fractional numbers';

throws_ok { square(num => '68A') }
    qr/did not pass the 'integer' callback/
  , 'complains at numbers with trailing junk';

done_testing;
