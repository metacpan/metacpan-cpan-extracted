#! /usr/bin/perl
#
# tests registering new Params::Validate::Checks checks


use warnings;
use strict;

use Test::More tests => 12;
use Test::Exception;
use Test::Warn;


BEGIN
{
  use_ok 'Params::Validate::Checks'
      or die "Loading Params::Validate::Checks failed";
};


lives_and
{
  ok Params::Validate::Checks::register
      playing_card => qr/^(?:[A2-9JQK]|10)[CDHS]\z/,
      palindrome => sub { $_[0] eq reverse $_[0] },
      big_odd => {callbacks =>
      {
        odd => sub { $_[0] =~ /^\d*[13579]\z/ },
        big => sub { $_[0] > 20 },
      }}
      ;


} 'register completed and returned a true value';


sub play
{
  my %arg = validate @_, {card => {as 'playing_card'}};

  $arg{card};
}

lives_and { is play(card => '9S'), '9S' }
    'registered pattern check accepted';

throws_ok { play(card => '15S') }
    qr/did not pass regex check/,
    'registered pattern check complains about invalid input';


sub puzzle
{
  my %arg = validate @_, {secret => {as 'palindrome'}};

  42;
}

lives_and { is puzzle(secret => 'level'), 42 }
    'registered sub check accepted';

throws_ok { puzzle(secret => 'A man, a plot, a kayak, Atol: Panama') }
    qr/did not pass the 'palindrome' callback/,
    'registered sub check complains about invalid input';


sub half
{
  my %arg = validate @_, {num => {as 'big_odd'}};

  ($arg{num} - 1) / 2;
}

lives_and { is half(num => '31'), 15 }
    'registered hash check accepted';

throws_ok { half(num => 30) }
    qr/did not pass the 'odd' callback/,
    'registered sub check complains about invalid input';


dies_ok { Params::Validate::Checks::register 'limerick' }
    'register complains if passed a name without a check';

dies_ok { Params::Validate::Checks::register list => [qw<compo clegg foggy>] }
    'register complains if passed an array ref as a check';

dies_ok { Params::Validate::Checks::register statler => 'waldorf' }
    'register complains if passed a non-reference as a check';

warning_like { Params::Validate::Checks::register palindrome => qr/civic|eve/ }
    qr/^Overwriting existing check/,
    'overing an existing check warns';
