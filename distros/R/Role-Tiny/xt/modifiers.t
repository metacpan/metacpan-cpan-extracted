use strict;
use warnings;
use Test::More;

use Class::Method::Modifiers 1.05 ();

BEGIN {
  package MyRole;

  use Role::Tiny;

  around foo => sub { my $orig = shift; join ' ', 'role foo', $orig->(@_) };
}

BEGIN {
  package ExtraRole;

  use Role::Tiny;
}

BEGIN {
  package MyClass;

  sub foo { 'class foo' }
}

BEGIN {
  package ExtraClass;

  use Role::Tiny::With;

  with qw(MyRole ExtraRole);

  sub foo { 'class foo' }
}

BEGIN {
  package BrokenRole;
  use Role::Tiny;

  around 'broken modifier' => sub { my $orig = shift; $orig->(@_) };
}

BEGIN {
  package MyRole2;
  use Role::Tiny;
  with 'MyRole';
}

BEGIN {
  package ExtraClass2;
  use Role::Tiny::With;
  with 'MyRole2';
  sub foo { 'class foo' }
}

sub try_apply_to {
  my $to = shift;
  eval { Role::Tiny->apply_role_to_package($to, 'MyRole'); 1 }
    and return undef;
  return $@ if $@;
  die "false exception caught!";
}

is(try_apply_to('MyClass'), undef, 'role applies cleanly');
is(MyClass->foo, 'role foo class foo', 'method modifier');
is(ExtraClass->foo, 'role foo class foo', 'method modifier with composition');

is(ExtraClass2->foo, 'role foo class foo',
  'method modifier with role composed into role');

eval {
  Role::Tiny->create_class_with_roles('MyClass', 'BrokenRole');
  1;
} or $@ ||= 'false exception!';
like $@, qr/Evaling failed:/,
  'exception caught creating class with broken modifier in a role';

done_testing;
