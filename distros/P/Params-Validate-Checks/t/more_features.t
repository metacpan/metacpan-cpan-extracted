#! /usr/bin/perl
#
# tests that Params::Validate::Checks hasn't broken any of the other
# Params::Validate functionality its docs claim it works with


use warnings;
use strict;

use Test::More tests => 12;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as validate_pos>
      or die "Loading Params::Validate::Checks failed";
};

sub repeat
{
  my %arg = validate @_,
  {
    message => {as 'string'},
    count => {as 'pos_int', default => 3},
    suffix => {as 'string', optional => 1},

  };

  my $output = $arg{message} x $arg{count};
  $output .= $arg{suffix} if exists $arg{suffix};

  $output;
}

lives_and { is repeat(message => '*', count => 4, suffix => '.'), "****." }
    'explicit args still work when optional';

throws_ok { repeat() }
    qr/^Mandatory parameter 'message' missing/,
    'complains about compulsory argument even when others are optional';

lives_and { is repeat(message => '+', count => 8), '++++++++' }
    'optional argument can be omitted';

throws_ok { repeat(message => 'ooops', count => 2, suffix => "\n\n\n") }
    qr/did not pass the 'one line' callback/,
    'complains if optional parameter supplied but invalid';

throws_ok { repeat(message => 'ooops', count => 2, suffix => undef) }
    qr/did not pass the 'not empty' callback/,
    'complains undef supplied, even for an optional parameter';

lives_and { is repeat(message => 'hi'), 'hihihi' }
    'argument with default can be omitted';

throws_ok { repeat(message => 'grrr', count => 'three') }
    qr/did not pass regex check/,
    'complains if parameter with default supplied but invalid';


sub occupy
{
  my %arg = validate @_,
  {
    people => {as 'pos_int'},
    room => {regex => qr/^[0-2]\.[1-9]\d*\z/},
  };

  "$arg{people} people in room $arg{room}";
}

lives_and { is occupy(people => 12, room => '2.18'), '12 people in room 2.18' }
    'mixing named and hand-rolled checks works';


sub scale_mark
{
  my ($mark, $max)
      = validate_pos @_, {as 'pos_int'}, {as 'pos_int', default => 20};

  int ($mark / $max * 100 + 0.5);
}

lives_and { is scale_mark(7, 10), 70 }
    'validate_pos works when arguments supplied';

lives_and { is scale_mark(7), 35 }
    'validate_pos works when argument with default omitted';

throws_ok { scale_mark(7, 'x') }
    qr/did not pass regex check/,
    'complains if positinal parameter with default supplied but invalid';

