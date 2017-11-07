use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Specio qw( test_constraint :vars );

use B ();
use Specio::Library::String;

my %tests = (
    PackageName => {
        accept => [
            $CLASS_NAME,
            $STR_OVERLOAD_CLASS_NAME, qw(
                Specio
                Spec::Library::Builtins
                strict
                _Foo
                A123::456
                ),
            "Has::Chinese::\x{3403}::In::It"
        ],
        reject => [
            $EMPTY_STRING,
            $STR_OVERLOAD_EMPTY,
            qw(
                0Foo
                Foo:Bar
                Foo:::Bar
                Foo:
                Foo::
                Foo::Bar::
                ::Foo
                My-Distro
                ),
            'Has::Spaces In It',
        ],
    },
    DistName => {
        accept => [
            qw(
                Specio
                Spec-Library-Builtins
                strict
                _Foo
                A123-456
                ),
            "Has-Chinese-\x{3403}-In-It"
        ],
        reject => [
            $EMPTY_STRING,
            $STR_OVERLOAD_EMPTY,
            qw(
                0Foo
                Foo:Bar
                Foo-:Bar
                Foo:
                Foo-
                Foo-Bar-
                -Foo
                My::Package
                ),
            'Has-Spaces In It',
        ],
    },
    Identifier => {
        accept => [
            qw(
                _
                a
                b
                c
                d
                A
                B
                C
                D
                Foo
                Bar
                _what_
                foo_bar
                f1234
                f1j2_o1
                ),
            "\x{3403}",
            "has_\x{3403}",
            "has_\x{3403}_in_it",
        ],
        reject => [
            q{ },
            $EMPTY_STRING,
            'a b',
            '4foo',
        ]
    },
    SafeIdentifier => {
        accept => [
            qw(
                c
                d
                A
                B
                C
                D
                Foo
                Bar
                _what_
                foo_bar
                f1234
                f1j2_o1
                ),
            "\x{3403}",
            "has_\x{3403}",
            "has_\x{3403}_in_it",
        ],
        reject => [
            qw(
                _
                a
                b
                ),
            q{ },
            $EMPTY_STRING,
            'a b',
            '4foo',
        ]
    },
    LaxVersionStr => {
        accept => [
            qw(
                v1.2.3.4
                v1.2
                1.2.3
                1.2345.6
                v1.23_4
                1.2345
                1.2345_01
                0.1
                v0.1.2
                )
        ],
        reject => [
            qw(
                1.2_3_4
                42.a
                a.b
                vA.b
                ),
        ],
    },
    StrictVersionStr => {
        accept => [
            qw(
                v1.2.3.4
                v1.234.5
                2.3456
                0.1
                v0.1.2
                ),
        ],
        reject => [
            qw(
                v1.2
                1.2345.6
                v1.23_4
                1.2345_01
                )
        ],
    },
);

$tests{ModuleName} = $tests{PackageName};

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );
}

done_testing();
