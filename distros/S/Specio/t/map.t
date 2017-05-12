use strict;
use warnings;

use Test::More 0.96;
use Test::Specio qw( test_constraint :vars );

use Specio::Declare;
use Specio::Library::Builtins;
use Specio::Library::String;
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
    'UCStrToIntMap',
    parent => t(
        'Map',
        of => {
            key   => t('UCStr'),
            value => t('Int'),
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
    t('UCStrToIntMap'),
    {
        accept => [
            { FOO => 42 },
            _T::HashOverload->new( { FOO => 42 } ),
            $HASH_REF,
            _T::HashOverload->new( {} ),
        ],
        reject => [
            { foo => 42 },
            _T::HashOverload->new( { foo => 42 } ),
            { FOO => 42.1 },
            _T::HashOverload->new( { FOO => 42.1 } ),
            { FOO => [] },
            _T::HashOverload->new( { FOO => [] } ),
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
    t(
        'Map',
        of => {
            key   => t('NonEmptyStr'),
            value => t( 'HashRef', of => t('Int') ),
        },
        )->name,
    'Map{ NonEmptyStr => HashRef[Int] }',
    'Map type has expected generated name'
);

done_testing();
