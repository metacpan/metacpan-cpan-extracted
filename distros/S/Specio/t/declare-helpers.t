use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;
use Test::Specio qw( describe test_constraint :vars );

use Specio::Declare;
use Specio::PartialDump qw( partial_dump );

# The glob vars only work when they're use in the same package as where
# they're declared. Globs are weird.
my $GLOB = do {
    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'once';
    *SOME_GLOB;
};

## no critic (Variables::RequireInitializationForLocalVars)
local *FOO;
my $GLOB_OVERLOAD = _T::GlobOverload->new( \*FOO );

local *BAR;
{
    ## no critic (InputOutput::ProhibitBarewordFileHandles, InputOutput::RequireBriefOpen)
    open BAR, '<', $0 or die "Could not open $0 for the test";
}
my $GLOB_OVERLOAD_FH = _T::GlobOverload->new( \*BAR );

## no critic (Modules::ProhibitMultiplePackages)
{

    package Foo;

    sub new {
        return bless {}, shift;
    }

    sub foo {42}
}

{

    package Baz;

    ## no critic (ClassHierarchies::ProhibitExplicitISA)
    our @ISA = 'Foo';

    sub bar {84}
}

{

    package Quux;

    sub whatever { }
}

{
    package Role::Foo;
    use Role::Tiny;
}

{
    package Does::Role::Foo;
    use Role::Tiny::With;
    with 'Role::Foo';

    sub new {
        return bless {}, shift;
    }
}

{
    my $tc = object_can_type(
        'Need2Obj',
        methods => [qw( foo bar )],
    );

    is( $tc->name, 'Need2Obj', 'constraint has the expected name' );

    test_constraint(
        $tc,
        {
            accept => [ Baz->new ],
            reject => [
                $ZERO,
                $ONE,
                $BOOL_OVERLOAD_TRUE,
                $BOOL_OVERLOAD_FALSE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $NUM_OVERLOAD_ZERO,
                $NUM_OVERLOAD_ONE,
                $NUM_OVERLOAD_NEG,
                $NUM_OVERLOAD_NEG_DECIMAL,
                $NUM_OVERLOAD_DECIMAL,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $STR_OVERLOAD_EMPTY,
                $STR_OVERLOAD_FULL,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $SCALAR_OVERLOAD,
                $ARRAY_REF,
                $ARRAY_OVERLOAD,
                $HASH_REF,
                $HASH_OVERLOAD,
                $CODE_REF,
                $CODE_OVERLOAD,
                $GLOB,
                $GLOB_REF,
                $GLOB_OVERLOAD,
                $GLOB_OVERLOAD_FH,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $REGEX_OVERLOAD,
                $FAKE_REGEX,
                $OBJECT,
                $UNDEF,
            ],
        },
    );
}

subtest(
    'any_can_type which needs 2 methods',
    sub {
        my $tc = any_can_type(
            'Need2Any',
            methods => [qw( foo bar )],
        );

        is( $tc->name, 'Need2Any', 'constraint has the expected name' );

        test_constraint(
            $tc,
            {
                accept => [ 'Baz', Baz->new ],
                reject => [
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

subtest(
    'any_can_type which needs 3 methods',
    sub {
        my $tc = object_can_type(
            'Need3Obj',
            methods => [qw( foo bar baz )],
        );

        test_constraint(
            $tc,
            {
                reject => [
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

subtest(
    'object_can_type which needs 2 methods',
    sub {
        my $tc = object_can_type(
            methods => [qw( foo bar )],
        );

        test_constraint(
            $tc,
            {
                accept => [ Baz->new ],
                reject => [
                    'Baz',
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

subtest(
    'object_can_type which needs 3 methods',
    sub {
        my $tc = object_can_type(
            methods => [qw( foo bar baz )],
        );

        test_constraint(
            $tc,
            {
                reject => [
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );

        ok(
            !$tc->value_is_valid( Baz->new ),
            'Baz object is not valid for anon ObjectCan type'
        );
    }
);

subtest(
    'object_isa_type (Foo class)',
    sub {
        my $tc = object_isa_type('Foo');

        is( $tc->name, 'Foo', 'name defaults to class name' );

        test_constraint(
            $tc,
            {
                accept => [
                    Foo->new,
                    Baz->new
                ],
                reject => [
                    'Baz',
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );

        is(
            exception {
                is(
                    $tc . q{},
                    object_isa_type('Foo') . q{},
                    'object_isa_type returns the same type for the same class each time'
                );
            },
            undef,
            'no exception calling object_isa_type repeatedly with the same class name'
        );
    }
);

subtest(
    'any_isa_type (isa Foo)',
    sub {
        my $tc = any_isa_type(
            'FooAny',
            class => 'Foo',
        );

        is( $tc->name, 'FooAny', 'can provide an explicit name' );

        test_constraint(
            $tc,
            {
                accept => [
                    'Foo',
                    Foo->new,
                    'Baz',
                    Baz->new
                ],
                reject => [
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );

        is(
            exception {
                is(
                    $tc . q{},
                    any_isa_type('FooAny') . q{},
                    'any_isa_type returns the same type for the same class each time'
                );
            },
            undef,
            'no exception calling any_isa_type repeatedly with the same class name'
        );
    }
);

subtest(
    'object_isa_type (isa Quux)',
    sub {
        my $tc = object_isa_type('Quux');

        test_constraint(
            $tc,
            {
                reject => [
                    'Foo',
                    Foo->new,
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

subtest(
    'any_isa_type (isa Quux)',
    sub {
        my $tc = any_isa_type(
            'QuuxAny',
            class => 'Quux',
        );

        test_constraint(
            $tc,
            {
                reject => [
                    'Foo',
                    Foo->new,
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

subtest(
    'object_does_type (Role::Foo class)',
    sub {
        my $tc = object_does_type('Role::Foo');

        is( $tc->name, 'Role::Foo', 'name defaults to role name' );

        test_constraint(
            $tc,
            {
                accept => [
                    Does::Role::Foo->new,
                ],
                reject => [
                    'Does::Role::Foo',
                    Foo->new,
                    'Foo',
                    Baz->new,
                    'Baz',
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );

        is(
            exception {
                is(
                    $tc . q{},
                    object_does_type('Role::Foo') . q{},
                    'object_does_type returns the same type for the same class each time'
                );
            },
            undef,
            'no exception calling object_does_type repeatedly with the same class name'
        );
    }
);

subtest(
    'any_does_type (does Role::Foo)',
    sub {
        my $tc = any_does_type(
            'Role::FooAny',
            role => 'Role::Foo',
        );

        test_constraint(
            $tc,
            {
                accept => [
                    'Does::Role::Foo',
                    Does::Role::Foo->new,
                ],
                reject => [
                    'Foo',
                    Foo->new,
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );

        is(
            exception {
                is(
                    $tc . q{},
                    any_does_type('Role::FooAny') . q{},
                    'any_does_type returns the same type for the same class each time'
                );
            },
            undef,
            'no exception calling any_does_type repeatedly with the same class name'
        );
    }
);

subtest(
    'enum',
    sub {
        my $tc = enum(
            'Enum1',
            values => [qw( a b c )],
        );

        test_constraint(
            $tc,
            {
                accept => [qw( a b c )],
                reject => [
                    'd',
                    42,
                    'Foo',
                    Foo->new,
                    'Baz',
                    Baz->new,
                    $ZERO,
                    $ONE,
                    $BOOL_OVERLOAD_TRUE,
                    $BOOL_OVERLOAD_FALSE,
                    $INT,
                    $NEG_INT,
                    $NUM,
                    $NEG_NUM,
                    $NUM_OVERLOAD_ZERO,
                    $NUM_OVERLOAD_ONE,
                    $NUM_OVERLOAD_NEG,
                    $NUM_OVERLOAD_NEG_DECIMAL,
                    $NUM_OVERLOAD_DECIMAL,
                    $EMPTY_STRING,
                    $STRING,
                    $NUM_IN_STRING,
                    $STR_OVERLOAD_EMPTY,
                    $STR_OVERLOAD_FULL,
                    $INT_WITH_NL1,
                    $INT_WITH_NL2,
                    $SCALAR_REF,
                    $SCALAR_REF_REF,
                    $SCALAR_OVERLOAD,
                    $ARRAY_REF,
                    $ARRAY_OVERLOAD,
                    $HASH_REF,
                    $HASH_OVERLOAD,
                    $CODE_REF,
                    $CODE_OVERLOAD,
                    $GLOB,
                    $GLOB_REF,
                    $GLOB_OVERLOAD,
                    $GLOB_OVERLOAD_FH,
                    $FH,
                    $FH_OBJECT,
                    $REGEX,
                    $REGEX_OBJ,
                    $REGEX_OVERLOAD,
                    $FAKE_REGEX,
                    $OBJECT,
                    $UNDEF,
                ],
            },
        );
    }
);

done_testing();
