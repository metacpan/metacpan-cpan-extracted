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
    'Tuple[ UCStr, Int, Str ]',
    parent => t(
        'Tuple',
        of => [
            t('UCStr'),
            t('Int'),
            t('Str'),
        ],
    ),
);

declare(
    'Tuple[ UCStr, Int, Str? ]',
    parent => t(
        'Tuple',
        of => [
            t('UCStr'),
            t('Int'),
            optional( t('Str') ),
        ],
    ),
);

declare(
    'Tuple[ UCStr, Int, Str?, Str? ]',
    parent => t(
        'Tuple',
        of => [
            t('UCStr'),
            t('Int'),
            optional( t('Str') ),
            optional( t('Str') ),
        ],
    ),
);

declare(
    'Tuple[UCStr, Int, Str...]',
    parent => t(
        'Tuple',
        of => [
            t('UCStr'),
            t('Int'),
            slurpy( t('Str') ),
        ],
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
    t('Tuple[ UCStr, Int, Str ]'),
    {
        accept => [
            [ 'FOO', 42, 'bar' ],
        ],
        reject => [
            [ 'FOO', 42 ],
            [ 'FOO', 42, 'bar', 5 ],
            [ 'foo', 42, 'bar' ],
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
    t('Tuple[ UCStr, Int, Str? ]'),
    {
        accept => [
            [ 'FOO', 42, 'bar' ],
            [ 'FOO', 42 ],
        ],
        reject => [
            [ 'FOO', 42, 'bar', 5 ],
            [ 'foo', 42, 'bar' ],
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
    t('Tuple[ UCStr, Int, Str?, Str? ]'),
    {
        accept => [
            [ 'FOO', 42, 'bar', 'buz' ],
            [ 'FOO', 42, 'bar' ],
            [ 'FOO', 42 ],
        ],
        reject => [
            [ 'FOO', 42, 'bar', [] ],
            [ 'FOO', 42, [] ],
            [ 'foo', 42, 'bar' ],
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
    t('Tuple[UCStr, Int, Str...]'),
    {
        accept => [
            [ 'FOO', 42, 'bar' ],
            [ 'FOO', 42 ],
            [ 'FOO', 42, ('bar') x 4 ],
        ],
        reject => [
            [ 'FOO', 42, 'bar', [] ],
            [ 'foo', 42, 'bar' ],
            [ 'foo', 42, [] ],
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
    t('Tuple[ UCStr, Int, Str ]')->parent->name,
    'Tuple[ UCStr, Int, Str ]',
    'got expected generated name for simple Tuple'
);

is(
    t('Tuple[ UCStr, Int, Str? ]')->parent->name,
    'Tuple[ UCStr, Int, Str? ]',
    'got expected generated name for Tuple with optional element'
);

is(
    t('Tuple[UCStr, Int, Str...]')->parent->name,
    'Tuple[ UCStr, Int, Str... ]',
    'got expected generated name for Tuple with slurpy'
);

done_testing();
