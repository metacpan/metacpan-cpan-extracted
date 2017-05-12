#! /usr/bin/perl
#
# tests Params::Validate::Checks pos_int check does what's required

use warnings;
use strict;

use Test::More tests => 6;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
};

sub square
{
  my %arg = validate @_, {num => {as 'pos_int'}};

  $arg{num} * $arg{num};
}

lives_and { is square(num => 256), 65536 }
    'allows multi-digit numbers';

throws_ok { square(num => 0) }
    qr/did not pass regex check/,
    'complains at zero';

throws_ok { square(num => -5) }
    qr/did not pass regex check/,
    'complains negative numbers';

throws_ok { square(num => 2.4) }
    qr/did not pass regex check/,
    'complains at fractional numbers';

throws_ok { square(num => '68A') }
    qr/did not pass regex check/,
    'complains at numbers with trailing junk';
