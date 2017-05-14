use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use Specio::Declare;

## no critic (Modules::ProhibitMultiplePackages)
{
    package Class::DoesNoRoles;

    sub new {
        return bless {}, shift;
    }
}

{
    package Role::MooseStyle;

    use Role::Tiny;
}

{
    package Class::MooseStyle;

    use Role::Tiny::With;

    with 'Role::MooseStyle';

    sub new {
        bless {}, __PACKAGE__;
    }
}

{
    my $any_does_moose = any_does_type(
        'AnyDoesMoose',
        role => 'Role::MooseStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MooseStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMoose',
        role => 'Role::MooseStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MooseStyle'
    );
}

{
    is(
        exception {
            is(
                object_does_type('Role::MooseStyle') . q{},
                object_does_type('Role::MooseStyle') . q{},
                'object_does_type returns the same type for the same role each time'
            );
        },
        undef,
        'no exception calling object_does_type repeatedly with the same role name'
    );

    is(
        exception {
            is(
                any_does_type('Role::MooseStyle') . q{},
                any_does_type('Role::MooseStyle') . q{},
                'any_does_type returns the same type for the same role each time'
            );
        },
        undef,
        'no exception calling any_does_type repeatedly with the same role name'
    );
}

SKIP:
{
    skip 'These tests require Mouse and Perl 5.10+', 8
        if $] < 5.010000 || !eval { require Mouse; 1 };

    ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
    eval <<'EOF';
{
    package Role::MouseStyle;

    use Mouse::Role;
}

{
    package Class::MouseStyle;

    use Mouse;

    with 'Role::MouseStyle';
}
EOF

    die $@ if $@;

    my $any_does_moose = any_does_type(
        'AnyDoesMouse',
        role => 'Role::MouseStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MouseStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMouse',
        role => 'Role::MouseStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MouseStyle'
    );
}

SKIP:
{
    skip 'These tests require Moo', 8
        unless eval { require Moo; 1 };

    ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
    eval <<'EOF';
{
    package Role::MooStyle;

    use Moo::Role;
}

{
    package Class::MooStyle;

    use Moo;

    with 'Role::MooStyle';
}
EOF
    ## use critic

    die $@ if $@;

    my $any_does_moose = any_does_type(
        'AnyDoesMoo',
        role => 'Role::MooStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MooStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMoo',
        role => 'Role::MooStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MooStyle'
    );
}

done_testing();

sub _test_any_type {
    my $type       = shift;
    my $class_name = shift;

    my $type_name = $type->name;

    ok(
        $type->value_is_valid($class_name),
        "$class_name class name is valid for $type_name"
    );

    ok(
        $type->value_is_valid( $class_name->new ),
        "$class_name object is valid for $type_name"
    );

    ok(
        !$type->value_is_valid('Class::DoesNoRoles'),
        "Class::DoesNoRoles class name is not valid for $type_name"
    );

    ok(
        !$type->value_is_valid( Class::DoesNoRoles->new ),
        "Class::DoesNoRoles object is not valid for $type_name"
    );
}

sub _test_object_type {
    my $type       = shift;
    my $class_name = shift;

    my $type_name = $type->name;

    ok(
        !$type->value_is_valid($class_name),
        "$class_name class name is not valid for $type_name"
    );

    ok(
        $type->value_is_valid( $class_name->new ),
        "$class_name object is valid for $type_name"
    );

    ok(
        !$type->value_is_valid('Class::DoesNoRoles'),
        "Class::DoesNoRoles class name is not valid for $type_name"
    );

    ok(
        !$type->value_is_valid( Class::DoesNoRoles->new ),
        "Class::DoesNoRoles object is not valid for $type_name"
    );
}
