use strict;
use warnings;

use lib 't/lib';

use SharedTests;
use Test::More;

use Moose::Util qw( apply_all_roles );

{
    package RoleHCA;

    use Moose::Role;
    use MooseX::ClassAttribute;

    while ( my ( $name, $def ) = each %SharedTests::Attrs ) {
        class_has $name => %{$def};
    }
}

{
    package ClassWithRoleHCA;

    use Moose;

    with 'RoleHCA';

    has 'size' => (
        is      => 'rw',
        isa     => 'Int',
        default => 5,
    );

    sub BUILD {
        my $self = shift;

        $self->ObjectCount( $self->ObjectCount() + 1 );
    }

    sub _BuildIt {42}

    sub _CallTrigger {
        push @{ $_[0]->TriggerRecord() }, [@_];
    }
}

ok(
    ClassWithRoleHCA->meta()->does_role('RoleHCA'),
    'ClassWithRoleHCA does RoleHCA'
);

SharedTests::run_tests('ClassWithRoleHCA');

ClassWithRoleHCA->meta()->make_immutable();

ok(
    ClassWithRoleHCA->meta()->does_role('RoleHCA'),
    'ClassWithRoleHCA (immutable) does RoleHCA'
);

# These next tests are aimed at testing to-role application followed by
# to-class application
{
    package RoleWithRoleHCA;

    use Moose::Role;
    use MooseX::ClassAttribute;

    with 'RoleHCA';
}

ok(
    RoleWithRoleHCA->meta()->does_role('RoleHCA'),
    'RoleWithRoleHCA does RoleHCA'
);

{
    package ClassWithRoleWithRoleHCA;

    use Moose;

    with 'RoleWithRoleHCA';

    has 'size' => (
        is      => 'rw',
        isa     => 'Int',
        default => 5,
    );

    sub BUILD {
        my $self = shift;

        $self->ObjectCount( $self->ObjectCount() + 1 );
    }

    sub _BuildIt {42}

    sub _CallTrigger {
        push @{ $_[0]->TriggerRecord() }, [@_];
    }
}

ok(
    ClassWithRoleWithRoleHCA->meta()->does_role('RoleHCA'),
    'ClassWithRoleWithRoleHCA does RoleHCA'
);

SharedTests::run_tests('ClassWithRoleWithRoleHCA');

ClassWithRoleWithRoleHCA->meta()->make_immutable();

ok(
    ClassWithRoleWithRoleHCA->meta()->does_role('RoleHCA'),
    'ClassWithRoleWithRoleHCA (immutable) does RoleHCA'
);

{
    package InstanceWithRoleHCA;

    use Moose;

    has 'size' => (
        is      => 'rw',
        isa     => 'Int',
        default => 5,
    );

    sub _BuildIt {42}

    sub _CallTrigger {
        push @{ $_[0]->TriggerRecord() }, [@_];
    }
}

my $instance = InstanceWithRoleHCA->new();

apply_all_roles( $instance, 'RoleHCA' );

ok(
    $instance->meta()->does_role('RoleHCA'),
    '$instance does RoleHCA'
);

$instance->ObjectCount(1);

SharedTests::run_tests($instance);

$instance->meta()->make_immutable();

ok(
    $instance->meta()->does_role('RoleHCA'),
    '$instance (immutable) does RoleHCA'
);

done_testing();
