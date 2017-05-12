#!/usr/bin/env perl
use strictures 1;

use Test::More;
use MooX::Adopt::Class::Accessor::Fast;

{
  package MyClass::Accessor::Chained::Fast;
  use strictures 1;
  use base 'Class::Accessor::Fast';
}

{
   package TestPackage;
   use base qw/MyClass::Accessor::Chained::Fast/;
   __PACKAGE__->mk_accessors('foo');
}

my $i = bless {}, 'TestPackage';
my $other_i = $i->foo('bar');
is($other_i, $i, 'Accessor returns instance as opposed to value.');

done_testing;
