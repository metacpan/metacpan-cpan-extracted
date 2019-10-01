use strict;
use warnings;
use Test::More;

BEGIN {
  package MyRole;

  use Role::Tiny;

  sub bar { 'role bar' }

  sub baz { 'role baz' }
}

BEGIN {
  package MyClass;

  use Role::Tiny::With;

  with 'MyRole';

  sub foo { 'class foo' }

  sub baz { 'class baz' }

}

is(MyClass->foo, 'class foo', 'method from class no override');
is(MyClass->bar, 'role bar',  'method from role');
is(MyClass->baz, 'class baz', 'method from class');

BEGIN {
  package RoleWithStub;

  use Role::Tiny;

  sub foo { 'role foo' }

  sub bar ($$);
}

{
  package ClassConsumeStub;
  use Role::Tiny::With;

  eval {
    with 'RoleWithStub';
  };
}

is $@, '', 'stub composed without error';
ok exists &ClassConsumeStub::bar,
  'stub exists in consuming class';
ok !defined &ClassConsumeStub::bar,
  'stub consumed as stub';

done_testing;
