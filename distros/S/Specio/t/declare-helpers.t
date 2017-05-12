use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use Specio::Declare;
use Specio::PartialDump qw( partial_dump );

## no critic (Modules::ProhibitMultiplePackages)
{

    package Foo;

    sub new {
        return bless {}, shift;
    }

    sub foo {42}
}

{

    package Bar;

    ## no critic (ClassHierarchies::ProhibitExplicitISA)
    our @ISA = 'Foo';

    sub bar {84}
}

{

    package Quux;

    sub whatever { }
}

{
    my $tc = object_can_type(
        'Need2O',
        methods => [qw( foo bar )],
    );

    is( $tc->name, 'Need2O', 'constraint has the expected name' );
    ok(
        $tc->value_is_valid( Bar->new ),
        'Bar object is valid for named ObjectCan type'
    );

    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval { $tc->validate_or_die( Foo->new ) };
    ## use critic
    my $e = $@;
    like(
        $e->message,
        qr/\QFoo is missing the 'bar' method/,
        'got expected error message for failure with ObjectCan type'
    );
}

{
    my $tc = any_can_type(
        'Need2A',
        methods => [qw( foo bar )],
    );

    is( $tc->name, 'Need2A', 'constraint has the expected name' );

    for my $thing ( 'Bar', Bar->new ) {
        my $desc = ref $thing ? 'Bar class name' : 'Bar object';

        ok(
            $tc->value_is_valid('Bar'),
            "$desc is valid for named AnyCan type"
        );
    }

    for my $thing ( 'Foo', Foo->new ) {
        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval { $tc->validate_or_die($thing) };
        ## use critic
        my $e = $@;
        like(
            $e->message,
            qr/\QFoo is missing the 'bar' method/,
            'got expected error message for failure with AnyCan type'
        );
    }
}

{
    my $tc = object_can_type(
        'Need3',
        methods => [qw( foo bar baz )],
    );

    ok(
        !$tc->value_is_valid( Bar->new ),
        'Bar object is not valid for named ObjectCan type'
    );
}

{
    my $tc = object_can_type(
        methods => [qw( foo bar )],
    );

    ok(
        $tc->value_is_valid( Bar->new ),
        'Bar object is valid for anon ObjectCan type'
    );
}

{
    my $tc = object_can_type(
        methods => [qw( foo bar baz )],
    );

    ok(
        !$tc->value_is_valid( Bar->new ),
        'Bar object is not valid for anon ObjectCan type'
    );
}

{
    my $tc = object_isa_type('Foo');

    is( $tc->name, 'Foo', 'name defaults to class name' );

    ok(
        $tc->value_is_valid( Foo->new ),
        'Foo object is valid for object isa type (requires Foo)'
    );

    ok(
        $tc->value_is_valid( Bar->new ),
        'Bar object is valid for object isa type (requires Foo)'
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

{
    my $tc = any_isa_type(
        'FooAny',
        class => 'Foo',
    );

    is( $tc->name, 'FooAny', 'can provide an explicit name' );

    for my $class (qw( Foo Bar )) {
        for my $thing ( $class, $class->new ) {
            my $desc
                = ref $thing
                ? ( ref $thing ) . ' object'
                : "$thing class name";

            ok(
                $tc->value_is_valid( Foo->new ),
                "$desc is valid for any isa type (requires Foo)"
            );
        }
    }

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

{
    my $tc = object_isa_type('Quux');

    ok(
        !$tc->value_is_valid( Foo->new ),
        'Foo object is not valid for object isa type (requires NonExistent)'
    );

    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval { $tc->validate_or_die( Foo->new ) };
    ## use critic
    my $e = $@;
    like(
        $e->message,
        qr/\Q/,
        'got expected error message for failure with ObjectCan type'
    );
}

{
    my $tc = any_isa_type(
        'QuuxAny',
        class => 'Quux',
    );

    for my $thing ( 'Foo', Foo->new ) {
        my $desc = ref $thing ? 'Foo class name' : 'Foo object';
        ok(
            !$tc->value_is_valid($thing),
            "$desc is not valid for any isa type (requires Quux)"
        );

        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval { $tc->validate_or_die($thing) };
        ## use critic
        my $e = $@;
        like(
            $e->message,
            qr/\Q/,
            'got expected error message for failure with AnyCan type'
        );
    }
}

{
    require Specio::Constraint::Enum;

    my $tc = enum(
        'Enum1',
        values => [qw( a b c )],
    );

    for my $value (qw( a b c )) {
        ok(
            $tc->value_is_valid($value),
            "enum type accepts '$value'"
        );
    }

    for my $value ( 'd', 42, [] ) {
        ok(
            !$tc->value_is_valid($value),
            'enum type rejects ' . partial_dump($value)
        );
    }
}

done_testing();
