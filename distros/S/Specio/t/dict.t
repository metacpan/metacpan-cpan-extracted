use strict;
use warnings;

use Test::More 0.96;
use Test::Specio qw( test_constraint :vars );

use Specio::Declare;
use Specio::Library::Builtins;
use Specio::Library::Structured;

## no critic (Subroutines::ProtectPrivateSubs)
declare(
    'UCStr',
    parent => t('Str'),
    inline => sub {
        $_[0]->parent->_inline_check( $_[1] ) . " && $_[1] =~ /^[A-Z]+\$/";
    },
);
## use critic

declare(
    'Dict{ bar => Int, foo => UCStr }',
    parent => t(
        'Dict',
        of => {
            kv => {
                foo => t('UCStr'),
                bar => t('Int'),
            },
        },
    ),
);

declare(
    'Dict{ bar => Int, baz => Num?, foo => UCStr }',
    parent => t(
        'Dict',
        of => {
            kv => {
                foo => t('UCStr'),
                bar => t('Int'),
                baz => optional( t('Num') ),
            },
        },
    ),
);

declare(
    'Dict{ bar => Int, baz => Num?, foo => UCStr, HashRef... }',
    parent => t(
        'Dict',
        of => {
            kv => {
                foo => t('UCStr'),
                bar => t('Int'),
                baz => optional( t('Num') ),
            },
            slurpy => t('HashRef'),
        },
    ),
);

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

test_constraint(
    t('Dict{ bar => Int, foo => UCStr }'),
    {
        accept => [
            {
                foo => 'BAZ',
                bar => 42,
            },
            _T::HashOverload->new(
                {
                    foo => 'BAZ',
                    bar => 42,
                }
            ),
        ],
        reject => [
            $HASH_REF,
            {
                foo => 'baz',
                bar => 42,
            },
            {
                foo => 'BAZ',
                bar => 42.1,
            },
            { foo => 'BAZ' },
            { bar => 42 },
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

test_constraint(
    t('Dict{ bar => Int, baz => Num?, foo => UCStr }'),
    {
        accept => [
            {
                foo => 'BAZ',
                bar => 42,
            },
            _T::HashOverload->new(
                {
                    foo => 'BAZ',
                    bar => 42,
                }
            ),
            {
                foo => 'BAZ',
                bar => 42,
                baz => 42.1,
            },
            _T::HashOverload->new(
                {
                    foo => 'BAZ',
                    bar => 42,
                    baz => 42.1,
                }
            ),
        ],
        reject => [
            $HASH_REF,
            {
                foo => 'baz',
                bar => 42,
            },
            {
                foo => 'BAZ',
                bar => 42.1,
            },
            {
                foo => 'BAZ',
                bar => 42,
                baz => 'string',
            },
            { foo => 'BAZ' },
            { bar => 42 },
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

test_constraint(
    t('Dict{ bar => Int, baz => Num?, foo => UCStr, HashRef... }'),
    {
        accept => [
            {
                foo  => 'BAZ',
                bar  => 42,
                quux => {},
            },
            _T::HashOverload->new(
                {
                    foo  => 'BAZ',
                    bar  => 42,
                    quux => {},
                }
            ),
            {
                foo  => 'BAZ',
                bar  => 42,
                baz  => 42.1,
                quux => { x => 1 },
            },
            _T::HashOverload->new(
                {
                    foo  => 'BAZ',
                    bar  => 42,
                    baz  => 42.1,
                    quux => { x => 1 },
                }
            ),
        ],
        reject => [
            $HASH_REF,
            {
                foo => 'baz',
                bar => 42,
            },
            {
                foo => 'BAZ',
                bar => 42.1,
            },
            {
                foo => 'BAZ',
                bar => 42,
                baz => 'string',
            },
            { foo => 'BAZ' },
            { bar => 42 },
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
    t('Dict{ bar => Int, foo => UCStr }')->parent->name,
    'Dict{ bar => Int, foo => UCStr }',
    'got expected name for simple Dict'
);

is(
    t('Dict{ bar => Int, baz => Num?, foo => UCStr }')->parent->name,
    'Dict{ bar => Int, baz => Num?, foo => UCStr }',
    'got expected name for Dict with optional key'
);

is(
    t('Dict{ bar => Int, baz => Num?, foo => UCStr, HashRef... }')
        ->parent->name,
    'Dict{ bar => Int, baz => Num?, foo => UCStr, HashRef... }',
    'got expected name for slurpy Dict with optional key'
);

done_testing();
