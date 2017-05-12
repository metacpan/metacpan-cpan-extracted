#!/usr/bin/perl -w

use Test::More tests => 30;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('SDL::App::FPS::Group');
  }

can_ok ('SDL::App::FPS::Group', qw/ 
  member members add del named
  new _init activate is_active deactivate id clear
  /);

##############################################################################
package DummyThing;

# a dummy package to simulate some object

my $id = 0;
sub new { $id++; bless { id => $id, name => 'DummyThing #' . $id }, 'DummyThing'; }

my $done = 0;
sub done
  {
  $done++;
  }

sub name
  {
  my $self = shift;
  'DummyThing #' . $self->{id};
  }

sub activate
  {
  $_[0]->{active} = 1;
  }

sub deactivate
  {
  $_[0]->{active} = 0;
  }

sub is_active
  {
  $_[0]->{active};
  }

##############################################################################

package main;

# create group

my $group = SDL::App::FPS::Group->new( 'main' );

is (ref($group), 'SDL::App::FPS::Group', 'group new worked');
is ($group->id(), 1, 'group id is 1');
is ($group->name(), 'Group #1', "knows it's name");

is ($group->named('DummyThing #1'), (), "no match");

is ($group->members(), 0, 'group has 0 members');

# add somethig
$group->add( DummyThing->new() );
is ($group->members(), 1, 'group has 1 members');
is (ref($group->member(1)), 'DummyThing', 'group member 1 exist');
is ($group->contains(1), 1, 'group member 1 exist');

# mass-add 
$group->add( DummyThing->new(), DummyThing->new() );
is ($group->members(), 3, 'group has 3 members');
is (ref($group->member(1)), 'DummyThing', 'group member 1 exist');
is (ref($group->member(2)), 'DummyThing', 'group member 2 exist');
is (ref($group->member(3)), 'DummyThing', 'group member 3 exist');
is ($group->contains(1), 1, 'group member 1 exist');
is ($group->contains(2), 1, 'group member 2 exist');
is ($group->contains(3), 1, 'group member 3 exist');

is ($group->named('DummyThing #1')->name(), 'DummyThing #1', "match");
is ($group->named('Dummything #1'), undef, "no match");

my $name = qr/dummy/;
is ($group->named($name), undef, "no match");
$name = qr/dummy/i;
is (my @a = $group->named($name), 3, "3 matches");

##############################################################################
# by_name

is ($group->contains(3), 1, 'group member 3 exist');

# for_each
is ($group->for_each('done'), $group, 'for_each did something');
is ($done, 3 , 'three member methods called' );

# activate/deactivate all
$group->deactivate();
for my $id (1..3)
  {
  is ($group->member($id)->is_active(), 0, "$id got deactivated");
  }

$group->activate();
for my $id (1..3)
  {
  is ($group->member($id)->is_active(), 1, "$id got activated");
  }

