#! /usr/bin/perl
#
# tests that Params::Validate::Checks hasn't broken any of the basic
# Params::Validate functionality, and the normal error messages are raised for
# the wrong number of named parameters


use warnings;
use strict;

use Test::More tests => 6;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
};

sub repeat
{
  my %arg = validate @_,
  {
    message => {as 'string'},
    count => {as 'pos_int'},
  };

  $arg{message} x $arg{count};
}

lives_and { is repeat(message => 'splat', count => 3), 'splatsplatsplat' }
    'arguments passed successfully';

throws_ok { repeat() }
    qr/^Mandatory parameters '\w+', '\w+' missing/,
    'complains at no arguments';

throws_ok { repeat(message => 'yo') }
    qr/^Mandatory parameter 'count' missing/,
    'complains at one argument missing';

throws_ok { repeat(message => 'hmmm', count => 3, colour => 'purple' ) }
    qr/not listed in the validation options: colour/,
    'complains at unexpected argument';

TODO:
{
  local $TODO = 'Params::Validate hole -- see Cpan RT #29762';

  throws_ok { repeat(message => 'wow', count => 3, count => 9) }
      qr/count specified multiple times/,
      'complains at repeated argument';
}
