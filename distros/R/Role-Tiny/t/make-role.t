use strict;
use warnings;
use Test::More;

use Role::Tiny ();

Role::Tiny->make_role('Foo');
{
  no warnings 'once';
  *Foo::foo = sub {42};
}

ok( Role::Tiny->is_role('Foo'), 'Foo is_role');

for my $m (qw(requires with before around after)) {
  ok( !Foo->can($m), "Foo cannot '$m'" );
}

Role::Tiny->apply_roles_to_package('FooFoo', 'Foo');
can_ok 'FooFoo', 'foo';

done_testing;
