use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use Eval::Closure qw( eval_closure );
use Specio::Declare;
use Specio::Library::Builtins;

{
    my $str = t('Str');
    my $int = t('Int');

    my ( $str_source, $str_env ) = $str->inline_coercion_and_check('$value1');
    my ( $int_source, $int_env ) = $int->inline_coercion_and_check('$value2');

    my $sub
        = 'sub { '
        . 'my $value1 = shift;'
        . 'my $value2 = shift;'
        . 'my $str_val = '
        . $str_source . ';'
        . 'my $int_val = '
        . $int_source . ';'
        . 'return ($str_val, $int_val)' . ' }';

    my $coerce_and_check;
    is(
        exception {
            $coerce_and_check = eval_closure(
                source      => $sub,
                environment => {
                    %{$str_env},
                    %{$int_env},
                },
                description => 'inlined coerce and check sub for str and int',
            );
        },
        undef,
        'no exception evaling a closure for str and int inlining in one sub',
    );

    is_deeply(
        [ $coerce_and_check->( 'string', 42 ) ],
        [ 'string', 42 ],
        'both types pass check and are returned'
    );

    like(
        exception { $coerce_and_check->( [], 42 ) },
        qr/Validation failed for type named Str/,
        'got exception passing arrayref for Str value'
    );

    like(
        exception { $coerce_and_check->( 'string', [] ) },
        qr/Validation failed for type named Int/,
        'got exception passing arrayref for Int value'
    );
}

{
    my $enum1 = enum( Enum1 => values => [qw( foo bar baz )] );
    my $enum2 = enum( Enum2 => values => [qw( a b c )] );

    my ( $enum1_source, $enum1_env )
        = $enum1->inline_coercion_and_check('$value1');
    my ( $enum2_source, $enum2_env )
        = $enum2->inline_coercion_and_check('$value2');

    my $sub
        = 'sub { '
        . 'my $value1 = shift;'
        . 'my $value2 = shift;'
        . 'my $enum1_val = '
        . $enum1_source . ';'
        . 'my $enum2_val = '
        . $enum2_source . ';'
        . 'return ($enum1_val, $enum2_val)' . ' }';

    my $coerce_and_check;
    is(
        exception {
            $coerce_and_check = eval_closure(
                source      => $sub,
                environment => {
                    %{$enum1_env},
                    %{$enum2_env},
                },
                description => 'inlined coerce and check sub for two enums',
            );
        },
        undef,
        'no exception evaling a closure for inlining two enums in one sub',
    );

    is_deeply(
        [ $coerce_and_check->( 'foo', 'a' ) ],
        [ 'foo', 'a' ],
        'both types pass check and are returned'
    );

    like(
        exception { $coerce_and_check->( [], 'c' ) },
        qr/Validation failed for type named Enum1/,
        'got exception passing arrayref for Enum1 value'
    );

    like(
        exception { $coerce_and_check->( 'bar', [] ) },
        qr/Validation failed for type named Enum2/,
        'got exception passing arrayref for Enum2 value'
    );
}

{
    # Note that the same bug would apply to role types and other special types
    # that have a specialized _inline_generator.
    my $foo = declare(
        'Foo',
        parent => any_isa_type('Specio::Coercion'),
    );

    my $constraint;
    is(
        exception { $constraint = $foo->_generated_inline_sub },
        undef,
        'building an inline sub for an empty subtype of an any_isa_type does not die'
    );

    ok(
        !$constraint->('Specio::Constraint::Simple'),
        'generated constraint rejects values as expected'
    );
    ok(
        $constraint->('Specio::Coercion'),
        'generated constraint accepts values as expected'
    );

    my $code;
    is(
        exception { $code = $foo->inline_check('$x') },
        undef,
        'building inline code for an empty subtype of an any_isa_type does not die'
    );

    like(
        $code,
        qr/\$x->isa\((["'])Specio::Coercion\1\)/,
        'generated code contains expected check'
    );
}

done_testing();
