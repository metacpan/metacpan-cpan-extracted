use strict;
use warnings;
use Test::More;

my $backcompat_called;
{
  package RoleExtension;
  use base 'Role::Tiny';

  sub apply_single_role_to_package {
    my $me = shift;
    $me->SUPER::apply_single_role_to_package(@_);
    $backcompat_called++;
  }
}
{
  package RoleExtension2;
  use base 'Role::Tiny';

  sub role_application_steps {
    $_[0]->SUPER::role_application_steps;
  }

  sub apply_single_role_to_package {
    my $me = shift;
    $me->SUPER::apply_single_role_to_package(@_);
    $backcompat_called++;
  }

}

{
  package Role1;
  $INC{'Role1.pm'} = __FILE__;
  use Role::Tiny;
  sub sub1 {}
}

{
  package Role2;
  $INC{'Role2.pm'} = __FILE__;
  use Role::Tiny;
  sub sub2 {}
}

{
  package Class1;
  RoleExtension->apply_roles_to_package(__PACKAGE__, 'Role1', 'Role2');
}

is $backcompat_called, 2,
  'overridden apply_single_role_to_package called for backcompat';

$backcompat_called = 0;
{
  package Class2;
  RoleExtension2->apply_roles_to_package(__PACKAGE__, 'Role1', 'Role2');
}
is $backcompat_called, 0,
  'overridden role_application_steps prevents backcompat attempt';

{
  package ClassWithoutExtraMethod;
  sub foo {}
}
{
  package RoleWithRequires;
  use Role::Tiny;
  requires 'extra_sub';
}
eval { Role::Tiny->create_class_with_roles('ClassWithoutExtraMethod', 'RoleWithRequires') };
like $@, qr/extra_sub/,
  'requires checked properly during create_class_with_roles';


SKIP: {
  skip "Class::Method::Modifiers not installed or too old", 1
    unless eval "use Class::Method::Modifiers 1.05; 1";
  {
    package RoleWithAround;
    use Role::Tiny;
    around extra_sub => sub { my $orig = shift; $orig->(@_); };
  }

  eval { Role::Tiny->create_class_with_roles('ClassWithoutExtraMethod', 'RoleWithAround') };
  like $@, qr/extra_sub/,
    'requires for modifiers checked properly during create_class_with_roles';
}

{
  package SimpleRole1;
  use Role::Tiny;
  sub role_method { __PACKAGE__ }
}

{
  package SimpleRole2;
  use Role::Tiny;
  sub role_method { __PACKAGE__ }
}

{
  package SomeEmptyClass;
  $INC{'SomeEmptyClass.pm'} ||= __FILE__;
}

{
  my $create_class = Role::Tiny->create_class_with_roles('SomeEmptyClass', 'SimpleRole1');
  Role::Tiny->apply_roles_to_package( $create_class, 'SimpleRole2' );

  my $manual_extend = 'ManualExtend';
  @ManualExtend::ISA = qw(SomeEmptyClass);
  Role::Tiny->apply_roles_to_package( $manual_extend, 'SimpleRole1' );
  Role::Tiny->apply_roles_to_package( $manual_extend, 'SimpleRole2' );

  is $create_class->role_method, $manual_extend->role_method,
    'methods added by create_class_with_roles treated equal to those added with apply_roles_to_package';
}

SKIP: {
  skip "Class::Method::Modifiers not installed or too old", 1
    unless eval "use Class::Method::Modifiers 1.05; 1";
  {
    package CreateMITest::Top;
    sub method { return __PACKAGE__ }

    package CreateMITest::Left;
    our @ISA = qw(CreateMITest::Top);

    package CreateMITest::Right;
    our @ISA = qw(CreateMITest::Top);
    sub method { return (__PACKAGE__, $_[0]->SUPER::method); }

    package CreateMITest::Bottom;
    our @ISA = qw(CreateMITest::Left CreateMITest::Right);
  }

  {
    package CreateMITest::MyRole;
    use Role::Tiny;
    around method => sub {
      my ($orig, $self) = (shift, shift);
      return (__PACKAGE__, $self->$orig);
    };
  }

  {
    package CreateMITest::MyChild;
    use Role::Tiny::With;
    our @ISA = qw(CreateMITest::Bottom);
    with 'CreateMITest::MyRole';
  }

  my $child_with = 'CreateMITest::MyChild';
  my $child_gen = Role::Tiny->create_class_with_roles('CreateMITest::Bottom', 'CreateMITest::MyRole');

  my @want = $child_with->method;
  my @got = $child_gen->method;

  is join(', ', @got), join(', ', @want),
    'create_class_with_roles follows same MRO as equivalent using with';
}

done_testing;
