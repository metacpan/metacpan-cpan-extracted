use strict;
use warnings;
use Test::More;

BEGIN {
  package MyRole;

  use Role::Tiny;

  requires qw(req1 req2);

  sub bar { 'role bar' }

  sub baz { 'role baz' }
}

BEGIN {
  package MyClass;

  use constant SIMPLE => 'simple';
  use constant REF_CONST => [ 'ref_const' ];
  use constant VSTRING_CONST => v1;

  sub req1 { }
  sub req2 { }
  sub foo { 'class foo' }
  sub baz { 'class baz' }

}

BEGIN {
  package ExtraClass;
  sub req1 { }
  sub req2 { }
  sub req3 { }
  sub foo { }
  sub baz { 'class baz' }
}

BEGIN {
  package IntermediaryRole;
  use Role::Tiny;
  requires 'req3';
}

BEGIN {
  package NoMethods;

  package OneMethod;

  sub req1 { }
}

BEGIN {
  package ExtraRole;
  use Role::Tiny;

  sub extra1 { 'role extra' }
}

sub try_apply_to {
  my $to = shift;
  eval { Role::Tiny->apply_role_to_package($to, 'MyRole'); 1 }
    and return undef;
  return $@ if $@;
  die "false exception caught!";
}

is(try_apply_to('MyClass'), undef, 'role applies cleanly');
is(MyClass->bar, 'role bar', 'method from role');
is(MyClass->baz, 'class baz', 'method from class');
ok(MyClass->does('MyRole'), 'class does role');
ok(!MyClass->does('IntermediaryRole'), 'class does not do non-applied role');
ok(!MyClass->does('Random'), 'class does not do non-role');

like(try_apply_to('NoMethods'), qr/req1, req2/, 'error for both methods');
like(try_apply_to('OneMethod'), qr/req2/, 'error for one method');

eval {
  Role::Tiny->apply_role_to_package('IntermediaryRole', 'MyRole');
  Role::Tiny->apply_role_to_package('ExtraClass', 'IntermediaryRole');
  1;
} or $@ ||= "false exception!";
is $@, '', 'No errors applying roles';

ok(ExtraClass->does('MyRole'), 'ExtraClass does MyRole');
ok(ExtraClass->does('IntermediaryRole'), 'ExtraClass does IntermediaryRole');
is(ExtraClass->bar, 'role bar', 'method from role');
is(ExtraClass->baz, 'class baz', 'method from class');

my $new_class;
eval {
    $new_class = Role::Tiny->create_class_with_roles('MyClass', 'ExtraRole');
} or $@ ||= "false exception!";
is $@, '', 'No errors creating class with roles';

isa_ok($new_class, 'MyClass');
is($new_class->extra1, 'role extra', 'method from role');

ok(Role::Tiny->is_role('MyRole'), 'is_role true for roles');
ok(!Role::Tiny->is_role('MyClass'), 'is_role false for classes');


done_testing;
