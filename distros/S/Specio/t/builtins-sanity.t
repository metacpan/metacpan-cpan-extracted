use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Specio qw( builtins_tests describe test_constraint :vars );

use Specio::Library::Builtins;

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

my $tests = builtins_tests( $GLOB, $GLOB_OVERLOAD, $GLOB_OVERLOAD_FH );
for my $name ( sort keys %{$tests} ) {
    test_constraint( $name, $tests->{$name} );
}

my %ptype_tests = (
    Maybe => {
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
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
            $UNDEF,
        ],
        reject => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
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
        ],
    },
    ScalarRef => {
        accept => [
            \$ZERO,
            \$ONE,
            \$INT,
            \$NEG_INT,
            \$NUM,
            \$NEG_NUM,
            \$EMPTY_STRING,
            \$STRING,
            \$NUM_IN_STRING,
            \$INT_WITH_NL1,
            \$INT_WITH_NL2,
        ],
        reject => [
            \$BOOL_OVERLOAD_TRUE,
            \$BOOL_OVERLOAD_FALSE,
            \$STR_OVERLOAD_EMPTY,
            \$STR_OVERLOAD_FULL,
            \$NUM_OVERLOAD_ZERO,
            \$NUM_OVERLOAD_ONE,
            \$NUM_OVERLOAD_NEG,
            \$NUM_OVERLOAD_NEG_DECIMAL,
            \$NUM_OVERLOAD_DECIMAL,
            \$SCALAR_REF,
            \$SCALAR_REF_REF,
            \$SCALAR_OVERLOAD,
            \$ARRAY_REF,
            \$ARRAY_OVERLOAD,
            \$HASH_REF,
            \$HASH_OVERLOAD,
            \$CODE_REF,
            \$CODE_OVERLOAD,
            \$GLOB,
            \$GLOB_REF,
            \$GLOB_OVERLOAD,
            \$GLOB_OVERLOAD_FH,
            \$FH,
            \$FH_OBJECT,
            \$REGEX,
            \$REGEX_OBJ,
            \$REGEX_OVERLOAD,
            \$FAKE_REGEX,
            \$OBJECT,
            \$UNDEF,
        ],
    },
    ArrayRef => {
        accept => [
            [],
            (
                map { [$_] } $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $GLOB,
            ),
        ],
        reject => [
            map { [$_] } $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
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
    HashRef => {
        accept => [
            {},
            (
                map { { foo => $_ } } $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $GLOB,
            )
        ],
        reject => [
            map { { foo => $_ } } $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
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

# We want to test all parameterized types using a type parameter that actually
# checks the value (so not Any or Item).
for my $pair (
    [ 'Maybe'   => \&describe ],
    [ ScalarRef => sub { 'scalar ref to ' . describe( ${ $_[0] } ) } ],
    [ ArrayRef  => sub { 'array ref to ' . describe( $_[0]->[0] ) } ],
    [ HashRef   => sub { 'hash ref to ' . describe( $_[0]->{foo} ) } ],
    ) {
    my ( $ptype, $describe ) = @{$pair};
    my $constraint = t( $ptype, of => t('Value') );

    test_constraint(
        $constraint,
        $ptype_tests{$ptype},
        $describe,
    );

    next unless $tests->{$ptype}{reject};

    # A parameterized type should reject all of the things that the
    # unparameterized version rejects.
    test_constraint(
        $constraint,
        { reject => $tests->{$ptype}{reject} },
        \&describe,
    );
}

my %substr_test_str = (
    ClassName => 'x' . $CLASS_NAME,
);

# We need to test that the Str constraint (and types that derive from it)
# accept the return val of substr() - which means passing that return val
# directly to the checking code
for my $type_name (qw( Str Num Int ClassName )) {
    my $str = $substr_test_str{$type_name} || '123456789123456789';

    my $type = t($type_name);

    my $name = $type->name;

    my $not_inlined = $type->_constraint_with_parents;

    my $inlined;
    if ( $type->can_be_inlined ) {
        $inlined = $type->_generated_inline_sub;
    }

    ok(
        $type->value_is_valid( substr( $str, 1, 9 ) ),
        $type_name . ' accepts return val from substr using ->value_is_valid'
    );
    ok(
        $not_inlined->( substr( $str, 1, 9 ) ),
        $type_name
            . ' accepts return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 1, 9 ) ),
        $type_name
            . ' accepts return val from substr using inlined constraint'
    );

    # only Str accepts empty strings.
    next unless $type_name eq 'Str';

    ok(
        $type->value_is_valid( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using ->value_is_valid'
    );
    ok(
        $not_inlined->( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using inlined constraint'
    );
}

done_testing();
