use strict;
use warnings;
use Test::More;

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose ':all';
use MooseX::Types::Structured ':all';
use MooseX::Types::Meta ':all';
use Scalar::Util 'blessed';

sub test {
    my ($name, $code) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $name => sub {
        $code->();
        done_testing;
    };
}

sub check_is {
    my ($type, $thing) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    (my $type_name = $type->name) =~ s/^MooseX::Types::Meta:://;
    ok(
        $type->check($thing),
        (blessed($thing) && $thing->can('name') ? $thing->name : $thing) . ' isa ' . $type_name,
    );
}

sub check_isnt {
    my ($type, $thing) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    (my $type_name = $type->name) =~ s/^MooseX::Types::Meta:://;
    ok(
        !$type->check($thing),
        (blessed($thing) && $thing->can('name') ? $thing->name : $thing) . ' is not a ' . $type_name,
    );
}

{
    package TestClass;
    use Moose;
    use namespace::autoclean;

    has attr => (
        is => 'ro',
    );

    sub foo { 42 }

    __PACKAGE__->meta->add_method(bar => sub { 23 });

    sub baz { 13 }
    before baz => sub {};

    __PACKAGE__->meta->make_immutable;
}

{
    package TestRole;
    use Moose::Role;
    use namespace::autoclean;

    has attr => (
        is => 'ro',
    );

    sub foo { }
}

test TypeConstraint => sub {
    check_is(TypeConstraint, $_) for TypeConstraint, Int;
    check_isnt(TypeConstraint, $_) for \42, 'Moose::Meta::TypeConstraint';
};

test Class => sub {
    check_is(Class, $_) for (
        MooseX::Types::Meta->meta,
        TestClass->meta,
        Moose::Meta::Class->meta,
    );

    check_isnt(Class, $_) for 42, TestRole->meta;
};

test Role => sub {
    check_is(Role, $_) for TestRole->meta;
    check_isnt(Role, $_) for TestClass->meta, 13;
};

test Attribute => sub {
    check_is(Attribute, $_) for (
        TestClass->meta->get_attribute('attr'),
        Moose::Meta::Class->meta->get_attribute('constructor_class'),
    );

    check_isnt(Attribute, $_) for (
        TestRole->meta->get_attribute('attr'),
        \42,
    );
};

test RoleAttribute => sub {
    check_is(RoleAttribute, $_) for (
        TestRole->meta->get_attribute('attr'),
    );

    check_isnt(RoleAttribute, $_) for (
        TestClass->meta->get_attribute('attr'),
        Moose::Meta::Class->meta->get_attribute('constructor_class'),
        TestClass->meta,
    );
};

test Method => sub {
    check_is(Method, $_) for (
        (map { TestClass->meta->get_method($_) } qw(foo bar baz attr)),
        (map { TestRole->meta->get_method($_)  } qw(foo attr)),
        Moose::Meta::Class->meta->get_method('create'),
        Moose::Meta::Class->meta->get_method('new'),
    );

    check_isnt(Method, $_) for (
        TestClass->meta->get_attribute('attr'),
        TestClass->meta,
    );
};

test TypeCoercion => sub {
    my $tc = subtype as Int;
    coerce $tc, from Str, via { 0 + $_ };

    check_is(TypeCoercion, $_) for $tc->coercion;
    check_isnt(TypeCoercion, $_) for $tc, Str, 42;
};

test StructuredTypeConstraint => sub {
    check_is(StructuredTypeConstraint, $_) for (
        Dict,
        Dict[],
        Dict[foo => Int],
        Map,
        Map[],
        Map[Int, Str],
        Tuple,
        Tuple[],
        Tuple[Int, Int],
        (subtype as Dict[]),
    );

    check_isnt(StructuredTypeConstraint, $_) for (
        ArrayRef,
        ArrayRef[Dict[]],
    );
};

test StructuredTypeCoercion => sub {
    my $tc = subtype as Dict[];
    coerce $tc, from Undef, via { +{} };

    check_is(StructuredTypeCoercion, $_) for $tc->coercion;
    check_isnt(StructuredTypeCoercion, $_) for $tc, Str, 42;
};

test TypeEquals => sub {
    check_is(TypeEquals[Num], $_) for Num;
    check_isnt(TypeEquals[Num], $_) for Int, Str;
};

test SubtypeOf => sub {
    check_is(SubtypeOf[Str], $_) for Num, Int, ClassName, RoleName;
    check_isnt(SubtypeOf[Str], $_) for Str, Value, Ref, Defined, Any, Item;
};

test TypeOf => sub {
    check_is(TypeOf[Str], $_) for Str, Num, Int, ClassName, RoleName;
    check_isnt(TypeOf[Str], $_) for Value, Ref, Defined, Any, Item;
};

test 'MooseX::Role::Parameterized' => sub {
    plan skip_all => 'MooseX::Role::Parameterized required'
        unless eval { require MooseX::Role::Parameterized; 1 };

    eval <<'EOR' or fail;
package TestRole::Parameterized;
use MooseX::Role::Parameterized;
role {
    sub foo { }
};
1;
EOR

    test ParameterizableRole => sub {
        check_is(ParameterizableRole, $_) for (
            TestRole::Parameterized->meta,
        );

        check_isnt(ParameterizableRole, $_) for (
            TestRole->meta,
        );
    };

    test ParameterizedRole => sub {
        check_is(ParameterizedRole, $_) for (
            TestRole::Parameterized->meta->generate_role(
                consumer   => Moose::Meta::Class->create_anon_class,
                parameters => {},
            ),
        );

        check_isnt(ParameterizedRole, $_) for (
            TestRole->meta,
        );
    };
};

# TypeEquals
# TypeOf
# SubtypeOf

done_testing;
