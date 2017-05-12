use strict;
use warnings;

use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);
use Moose::Util qw(does_role);
use MooseX::APIRole::Internals qw(role_for create_role_for);

{ package Role;
  use Moose::Role;
  requires 'coffee';

  sub oh_nice_a_sub {}
}

my $rolemeta = Role->meta;

ok !role_for($rolemeta), 'no role yet';

my $role = create_role_for($rolemeta);
ok $role, 'got new role';
is refaddr $role, refaddr role_for($rolemeta), 'cache works';

is_deeply [sort $role->get_required_method_list], [sort qw/coffee oh_nice_a_sub/],
    'role role does the methods that we think it should';

ok $role->is_anon_role, 'is anon role';

lives_ok {
    $role->apply($rolemeta);
} 'applying the role role to the original role works';

lives_ok {
  package Class;
  use Moose;
  with 'Role';

  sub coffee {}
} 'making a class that does Role and $role works';

my $class;
lives_ok {
    $class = Class->new;
} 'we can instantiate Class';

ok does_role($class, 'Role'), 'Class does Role';
ok does_role($class, $role), 'Class does $role';
ok does_role('Role', $role), 'Role does $role';

can_ok $class, 'coffee', 'oh_nice_a_sub';

# now try creating a role for this class (do role role roles work?)
my $class_role = create_role_for($class->meta);
ok $class_role, 'created class role';

is_deeply
    [sort $class_role->get_required_method_list],
    [sort qw/coffee oh_nice_a_sub/],
  'class role has correct required methods';

lives_ok {
    $class_role->apply($class->meta);
} 'applying the class role to the class succeeds';

throws_ok {
    package Another::Class;
    use Moose;
    with $class_role;

    sub coffee { 'foo' }
} qr/requires the method 'oh_nice_a_sub'/,
    'Another::Class does not automatically get a oh_nice_a_sub';

done_testing;
