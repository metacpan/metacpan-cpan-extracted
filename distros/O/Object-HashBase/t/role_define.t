use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Role::Tiny; 1 } or plan skip_all => 'Role::Tiny required';
    plan skip_all => 'Role::Tiny 1.003000 or newer required (is_role missing)'
        unless Role::Tiny->can('is_role');
}

BEGIN {
    package My::HBRole;
    use Role::Tiny;
    use Object::HashBase qw/ra -rb/;
}

ok(Role::Tiny->is_role('My::HBRole'), 'role registered with Role::Tiny');

# Accessors and constants installed on role
can_ok('My::HBRole', qw/RA RB ra rb set_ra set_rb/);
is(My::HBRole::RA(), 'ra', 'RA constant');
is(My::HBRole::RB(), 'rb', 'RB constant');

# new and init helpers NOT installed on role
ok(!My::HBRole->can('new'),           'role has no new()');
ok(!My::HBRole->can('add_pre_init'),  'role has no add_pre_init');
ok(!My::HBRole->can('add_post_init'), 'role has no add_post_init');
ok(!My::HBRole->can('_pre_init'),     'role has no _pre_init');
ok(!My::HBRole->can('_post_init'),    'role has no _post_init');

done_testing;
