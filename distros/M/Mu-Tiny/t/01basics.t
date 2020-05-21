use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN {
  package Foo;

  use Mu::Tiny;

  ro 'foo';
  ro 'bar';
  lazy baz => sub { 4 };

}

my $ok = eval { Foo->new; 1 };

my $err= $@;

ok !$ok, 'new() failed';

ok +($err =~ /foo/ and $err =~ /bar/), 'both missing required attrs reported';

my $obj = Foo->new(foo => 1, bar => 2);

is $obj->foo, 1, 'constructor population';
is $obj->baz, 4, 'lazy builder population';
