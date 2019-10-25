use strict;
use warnings;
use Test::More;

BEGIN {
  package Role1; use Role::Tiny;
  sub foo1 { 1 }
}
BEGIN {
  package Role2; use Role::Tiny;
  sub foo2 { 2 }
}
BEGIN {
  package BaseClass;
  sub foo { 0 }
}

eval {
  Role::Tiny->create_class_with_roles(
    'BaseClass',
    qw(Role2 Role1 Role1 Role2 Role2),
  );
};

like $@, qr/\ADuplicated roles: Role1, Role2 /,
  'duplicate roles detected';

BEGIN {
  package AnotherRole;
  use Role::Tiny;
  with 'Role1';
}

BEGIN {
  package AnotherClass;
  use Role::Tiny::With;
  with 'AnotherRole';
  delete $AnotherClass::{foo1};
  with 'AnotherRole';
}

ok +AnotherClass->can('foo1'),
  'reapplying roles re-adds missing methods';

done_testing;
