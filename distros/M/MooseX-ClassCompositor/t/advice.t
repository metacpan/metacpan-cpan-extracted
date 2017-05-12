#!perl
use strict;
use warnings;
use Test::More;

use MooseX::ClassCompositor;
use MooseX::StrictConstructor::Trait::Class;

{
  package Role;
  use Moose::Role;

  has xyz => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub {  []  },
    traits  => [ 'Array' ],
    handles => { push_xyz => 'push' },
  );

  after push_xyz => sub {
    $::after++;
  };
}

our $after;

for my $strict (0, 1) {
  $after = 0;

  my $comp = MooseX::ClassCompositor->new({
    class_basename => 'X',
    role_prefixes   => {
      ''  => '',
    },
    class_metaroles => {
      $strict
      ? (class => [ 'MooseX::StrictConstructor::Trait::Class' ])
      : ()
    },
  });

  my $class = $comp->class_for('Role');

  $class->new->push_xyz(1);

  is($after, 1, "advice called for strict=$strict");
};

done_testing;
