use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Specio qw( test_constraint :vars );

use Specio::Library::String;

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

my $LONG_STR_255 = 'x' x 255;
my $LONG_STR_256 = 'x' x 256;

my $LONG_CODE_255 = '1' x 255;
my $LONG_CODE_256 = '1' x 256;

my @STRINGS_WITH_VSPACE = map { join $_, qw( foo bar ) } (
    "\n",
    "\r",
    "\r\n",
    "\x{2028}",
    "\x{2029}",
);

my %tests = (
    NonEmptySimpleStr => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_FULL,
            $LONG_STR_255,
        ],
        reject => [
            $EMPTY_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $STR_OVERLOAD_EMPTY,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
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
            $LONG_STR_256,
            @STRINGS_WITH_VSPACE,
        ],
    },
    NonEmptyStr => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $NUM,
            $NEG_NUM,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_FULL,
            $LONG_STR_255,
            $LONG_STR_256,
            @STRINGS_WITH_VSPACE,
        ],
        reject => [
            $EMPTY_STRING,
            $STR_OVERLOAD_EMPTY,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
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
                ),
            'Has::Spaces In It',
        ],
    },
    SimpleStr => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $LONG_STR_255,
        ],
        reject => [
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
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
            $LONG_STR_256,
            @STRINGS_WITH_VSPACE,
        ],
    },
);

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );
}

done_testing();
