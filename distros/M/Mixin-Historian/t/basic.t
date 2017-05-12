#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;

use Mixin::Historian;
use Mixin::Historian::Driver::Array;

my $driver;
BEGIN {
  $driver = Mixin::Historian::Driver::Array->new;
}

{
  package TestObject;
  use Mixin::Historian -history => {
    driver => $driver,
    type   => {
      chargen => [ qw(class alignment) ],
      levelup => { indexed => [ qw(enemy new_level) ] },
      death   => [ qw(killer implement) ],
    }
  };

  sub new {
    my ($class, $id) = @_;
    return bless { id => $id } => $class;
  }

  sub id { $_[0]{id} }
}

my $object = TestObject->new(10);
isa_ok($object, 'TestObject');

$object->add_history({
  type  => 'chargen',
  agent => 'mailto:rjbs@example.com',
  via   => 'ip://10.20.30.40',

  class     => 'paladin',
  alignment => 'Lawful Good',
  deity     => 'Cuthbert',
});

$object->add_history({
  type  => 'levelup',
  agent => 'game://player/joe',
  via   => 'app://Game::DND::Whatever',

  enemy     => 'basilisk',
  new_level => '12',
  reward    => 'bag of beholding',
});

cmp_deeply(
  [ $driver->entries ],
  [
    {
      time   => ignore(),
      record => {
        type  => 'chargen',
        agent => 'mailto:rjbs@example.com',
        via   => 'ip://10.20.30.40',
        class     => 'paladin',
        alignment => 'Lawful Good',
        deity     => 'Cuthbert',
      },
    },
    {
      time   => ignore(),
      record => {
        type  => 'levelup',
        agent => 'game://player/joe',
        via   => 'app://Game::DND::Whatever',
        enemy     => 'basilisk',
        new_level => '12',
        reward    => 'bag of beholding',
      },
    },
  ],
  "we log two items and they go into bucket",
);

done_testing;
