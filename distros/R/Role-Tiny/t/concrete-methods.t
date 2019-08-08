use strict;
use warnings;
use Test::More;

{
  package MyRole1;

  sub before_role {}

  use Role::Tiny;
  no warnings 'once';

  our $GLOBAL1 = 1;
  sub after_role {}
}

{
  package MyClass1;
  no warnings 'once';

  our $GLOBAL1 = 1;
  sub method {}
}

my $role_methods = Role::Tiny->_concrete_methods_of('MyRole1');
is_deeply([sort keys %$role_methods], ['after_role'],
  'only subs after Role::Tiny import are methods' );

my @role_method_list = Role::Tiny->methods_provided_by('MyRole1');
is_deeply(\@role_method_list, ['after_role'],
  'methods_provided_by gives method list' );

my $class_methods = Role::Tiny->_concrete_methods_of('MyClass1');
is_deeply([sort keys %$class_methods], ['method'],
  'only subs from non-Role::Tiny packages are methods' );

eval { Role::Tiny->methods_provided_by('MyClass1') };
like $@,
  qr/is not a Role::Tiny/,
  'methods_provided_by refuses to work on classes';

done_testing;
