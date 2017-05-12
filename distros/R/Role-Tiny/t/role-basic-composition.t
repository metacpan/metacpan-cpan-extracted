use strict;
use warnings;
use Test::More;
require Role::Tiny;

{

    package My::Does::Basic1;
    use Role::Tiny;
    requires 'turbo_charger';

    sub method {
        return __PACKAGE__ . " method";
    }
}
{

    package My::Does::Basic2;
    use Role::Tiny;
    requires 'turbo_charger';

    sub method2 {
        return __PACKAGE__ . " method2";
    }
}

eval <<'END_PACKAGE';
package My::Class1;
use Role::Tiny 'with';
with qw(
    My::Does::Basic1
    My::Does::Basic2
);
sub turbo_charger {}
END_PACKAGE
ok !$@, 'We should be able to use two roles with the same requirements'
    or die $@;

{

    package My::Does::Basic3;
    use Role::Tiny;
    with 'My::Does::Basic2';

    sub method3 {
        return __PACKAGE__ . " method3";
    }
}

eval <<'END_PACKAGE';
package My::Class2;
use Role::Tiny 'with';
with qw(
    My::Does::Basic3
);
sub new { bless {} => shift }
sub turbo_charger {}
END_PACKAGE
ok !$@, 'We should be able to use roles which consume roles'
    or die $@;
can_ok 'My::Class2', 'method2';
is My::Class2->method2, 'My::Does::Basic2 method2',
  '... and it should be the correct method';
can_ok 'My::Class2', 'method3';
is My::Class2->method3, 'My::Does::Basic3 method3',
  '... and it should be the correct method';

ok My::Class2->Role::Tiny::does_role('My::Does::Basic3'), 'A class DOES roles which it consumes';
ok My::Class2->Role::Tiny::does_role('My::Does::Basic2'),
  '... and should do roles which its roles consumes';
ok !My::Class2->Role::Tiny::does_role('My::Does::Basic1'),
  '... but not roles which it never consumed';

my $object = My::Class2->new;
ok $object->Role::Tiny::does_role('My::Does::Basic3'), 'An instance DOES roles which its class consumes';
ok $object->Role::Tiny::does_role('My::Does::Basic2'),
  '... and should do roles which its roles consumes';
ok !$object->Role::Tiny::does_role('My::Does::Basic1'),
  '... but not roles which it never consumed';


{
    package GenAccessors;
    BEGIN { $INC{'GenAccessors.pm'} = __FILE__ }

    sub import {
        my ( $class, @methods ) = @_;
        my $target = caller;

        foreach my $method (@methods) {
            no strict 'refs';
            *{"${target}::${method}"} = sub {
                @_ > 1 ? $_[0]->{$method} = $_[1] : $_[0]->{$method};
            };
        }
    }
}

{
    {
        package Role::Which::Imports;
        use Role::Tiny;
        use GenAccessors qw(this that);
    }
    {
       package Class::With::ImportingRole;
       use Role::Tiny 'with';
       with 'Role::Which::Imports';
       sub new { bless {} => shift }
    }
    my $o = Class::With::ImportingRole->new;

    foreach my $method (qw/this that/) {
        can_ok $o, $method;
        ok $o->$method($method), '... and calling "allow"ed methods should succeed';
        is $o->$method, $method, '... and it should function correctly';
    }
}

{
    {
        package Role::WithImportsOnceRemoved;
        use Role::Tiny;
        with 'Role::Which::Imports';
    }
    {
        package Class::With::ImportingRole2;
        use Role::Tiny 'with';
$ENV{DEBUG} = 1;
        with 'Role::WithImportsOnceRemoved';
        sub new { bless {} => shift }
    }
    ok my $o = Class::With::ImportingRole2->new,
        'We should be able to use roles which compose roles which import';

    foreach my $method (qw/this that/) {
        can_ok $o, $method;
        ok $o->$method($method), '... and calling "allow"ed methods should succeed';
        is $o->$method, $method, '... and it should function correctly';
    }
}

{
    {
        package Method::Role1;
        use Role::Tiny;
        sub method1 { }
        requires 'method2';
    }

    {
        package Method::Role2;
        use Role::Tiny;
        sub method2 { }
        requires 'method1';
    }
    my $success = eval q{
        package Class;
        use Role::Tiny::With;
        with 'Method::Role1', 'Method::Role2';
        1;
    };
    is $success, 1, 'composed mutually dependent methods successfully' or diag "Error: $@";
}

SKIP: {
  skip "Class::Method::Modifiers not installed or too old", 1
    unless eval "use Class::Method::Modifiers 1.05; 1";
    {
        package Modifier::Role1;
        use Role::Tiny;
        sub foo {
        }
        before 'bar', sub {};
    }

    {
        package Modifier::Role2;
        use Role::Tiny;
        sub bar {
        }
        before 'foo', sub {};
    }
    my $success = eval q{
        package Class;
        use Role::Tiny::With;
        with 'Modifier::Role1', 'Modifier::Role2';
        1;
    };
    is $success, 1, 'composed mutually dependent modifiers successfully' or diag "Error: $@";
}

{
    {
        package Base::Role;
        use Role::Tiny;
        requires qw/method1 method2/;
    }

    {
        package Sub::Role1;
        use Role::Tiny;
        with 'Base::Role';
        sub method1 {}
    }

    {
        package Sub::Role2;
        use Role::Tiny;
        with 'Base::Role';
        sub method2 {}
    }

    my $success = eval q{
        package Diamant::Class;
        use Role::Tiny::With;
        with qw/Sub::Role1 Sub::Role2/;
        1;
    };
    is $success, 1, 'composed diamantly dependent roles successfully' or diag "Error: $@";
}

{
    {
        package My::Does::Conflict;
        use Role::Tiny;

        sub method {
            return __PACKAGE__ . " method";
        }
    }
    {
        package My::Class::Base;

        sub turbo_charger {
            return __PACKAGE__ . " turbo charger";
        }
        sub method {
            return __PACKAGE__ . " method";
        }
    }
    my $success = eval q{
        package My::Class::Child;
        use base 'My::Class::Base';
        use Role::Tiny::With;
        with qw/My::Does::Basic1 My::Does::Conflict/;
        1;
    };
    is $success, 1, 'role conflict resolved by superclass method' or diag "Error: $@";
    can_ok 'My::Class::Child', 'method';
    is My::Class::Child->method, 'My::Class::Base method', 'inherited method prevails';
}

done_testing;
