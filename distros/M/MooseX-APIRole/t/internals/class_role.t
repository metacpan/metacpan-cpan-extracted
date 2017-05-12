use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);
use Moose::Util qw(does_role);
use MooseX::APIRole::Internals qw(role_for create_role_for);

{ package Class;
  use Moose;
  has 'foo' => (
      reader   => 'get_foo',
      writer   => 'set_foo',
      accessor => 'foo',
      traits   => ['Counter'],
      isa      => 'Num',
      handles  => {
          inc_foo => 'inc',
      },
      required => 1,
  );

  sub bar {}
}

my $role = create_role_for(Class->meta, 'Class::Role');
is $role->name, 'Class::Role', 'got correct name';

is_deeply [sort $role->get_required_method_list],
          [sort qw/get_foo set_foo foo inc_foo bar/],
    'got required methods';

lives_ok {
    $role->apply(Class->meta);
} 'applying Class::Role to Class works';

ok does_role('Class', 'Class::Role'), 'class does class::role';
ok does_role('Class', $role), 'and $role';

{ package Sub::Class;
  use Moose;
  extends 'Class';

  sub baz {}
}

ok does_role('Sub::Class', 'Class::Role'), 'subclass also does the role';
my $subrole = create_role_for(Sub::Class->meta, 'Sub::Class::Role');

ok does_role('Sub::Class::Role', 'Class::Role'), 'the subrole does the original role';

done_testing;
