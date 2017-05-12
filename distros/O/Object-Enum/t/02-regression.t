#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Object::Enum (
  Enum => { -as => 'foo', values => ['a', 'b'] },
);

{ 
  my $warn;
  local $SIG{__WARN__} = sub { $warn = shift };
  foo();
  foo();
  is($warn, undef, "no redefine warning");
}

{
  my $obj = Object::Enum->new(['foo']);
  ok(eval { $obj->spawn->set_foo->is_foo }, "spawn works on objects");
}
