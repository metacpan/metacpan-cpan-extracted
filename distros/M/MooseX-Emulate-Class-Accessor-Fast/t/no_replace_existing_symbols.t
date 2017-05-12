#!/usr/binperl -w

use strict;
use warnings;
use Test::More tests => 6;

{
  package SomeClass;
  use Moose;
  with 'MooseX::Emulate::Class::Accessor::Fast';

  sub anaccessor { 'wibble' }

}
{
  package SubClass;
  use base qw/SomeClass/;

  sub anotherone { 'flibble' }
  __PACKAGE__->mk_accessors(qw/ anaccessor anotherone /);
}

# 1, 2
my $someclass = SomeClass->new;
is($someclass->anaccessor, 'wibble');
$someclass->anaccessor('fnord');
is($someclass->anaccessor, 'wibble');

# 3-6
my $subclass = SubClass->new;
ok( not defined $subclass->anaccessor );
$subclass->anaccessor('fnord');
is($subclass->anaccessor, 'fnord');
is($subclass->anotherone, 'flibble');
$subclass->anotherone('fnord');
is($subclass->anotherone, 'flibble');
