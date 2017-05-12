use strict;
use warnings;

use lib 't/lib';

use Test::Fatal;
use Test::More 0.96;
use Test::Specio qw( test_constraint :vars );

use Specio::Constraint::Union;
use Specio::Declare;
use Specio::DeclaredAt;
use Specio::Library::Builtins;

# The test output looks something like this:
#
# "Attempt to free unreferenced scalar: SV 0xf64bf0 at /home/autarch/perl5/perlbrew/perls/perl-5.12.5/lib/site_perl/5.12.5/Test/Builder.pm line 302."
#
# But the problem isn't in Test::Builder. It's something to do with
# overloading, because it happens when we try to test the non-inlined types
# with a NumOverload object.
plan skip_all =>
    'This test triggers some odd overloading bug that causes a segfault on older perls'
    if $] < 5.014;

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

my %tests = (
    accept => [
        $ZERO,
        $ONE,
        $INT,
        $NEG_INT,
        $NUM_OVERLOAD_ZERO,
        $NUM_OVERLOAD_ONE,
        $NUM_OVERLOAD_NEG,
        qw(
            1e20
            1e100
            -1e10
            -1e+10
            1E20
            ),
        $ARRAY_REF,
        $ARRAY_OVERLOAD,
    ],
    reject => [
        $BOOL_OVERLOAD_TRUE,
        $BOOL_OVERLOAD_FALSE,
        $NUM,
        $NEG_NUM,
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
        qw(
            1e-10
            -1e-10
            1.23456e10
            1.23456e-10
            -1.23456e10
            -1.23456e-10
            -1.23456e+10
            ),
    ],
);

subtest(
    'unnamed union made of two builtins',
    sub {
        my $unnamed_union = Specio::Constraint::Union->new(
            of => [ t('Int'), t('ArrayRef') ],
            declared_at => Specio::DeclaredAt->new_from_caller(0),
        );

        ok(
            $unnamed_union->_has_inline_generator,
            'union of two types with inline generator has a generator'
        );
        is(
            $unnamed_union->name,
            'Int | ArrayRef',
            'name is generated from constituent types'
        );
        ok(
            !$unnamed_union->is_anon,
            'unnamed union is not anonymous because name is generated'
        );
        is(
            $unnamed_union->parent,
            undef,
            'parent method returns undef'
        );
        ok(
            !$unnamed_union->_has_parent,
            'union has no parent'
        );

        test_constraint( $unnamed_union, \%tests );
    }
);

subtest(
    'explicitly named union made of two builtins',
    sub {
        my $named_union = union(
            'MyUnion',
            of => [ t('Int'), t('ArrayRef') ],
        );
        is(
            $named_union->name,
            'MyUnion',
            'name passed to union() is used'
        );

        test_constraint( $named_union, \%tests );
    }
);

subtest(
    'union made of two types without inline generators',
    sub {
        my $my_int = anon(
            parent     => t('Num'),
            constraint => sub {
                return (
                    (
                               defined( $_[0] )
                            && !ref( $_[0] )
                            && (
                            do {
                                ( my $val1 = $_[0] )
                                    =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
                            }
                            )
                    )
                        || (
                           Scalar::Util::blessed( $_[0] )
                        && overload::Overloaded( $_[0] )
                        && defined overload::Method( $_[0], '0+' )
                        && do {
                            ( my $val2 = $_[0] + 0 )
                                =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
                        }
                        )
                );
            },
        );

        my $my_arrayref = anon(
            parent     => t('Ref'),
            constraint => sub {
                return (
                    ref( $_[0] ) eq 'ARRAY'
                        || ( Scalar::Util::blessed( $_[0] )
                        && overload::Overloaded( $_[0] )
                        && defined overload::Method( $_[0], '@{}' ) )
                );
            },
        );

        my $no_inline_union = union(
            of => [ $my_int, $my_arrayref ],
        );
        is(
            $no_inline_union->name,
            undef,
            'no name if union includes anonymous types',
        );
        ok(
            $no_inline_union->is_anon,
            'union is anonymous if any of its constituents are anonymous'
        );

        test_constraint( $no_inline_union, \%tests );
    }
);

subtest(
    'union made of builtin and type without inline generator',
    sub {
        my $my_int = anon(
            parent     => t('Num'),
            constraint => sub {
                return (
                    (
                               defined( $_[0] )
                            && !ref( $_[0] )
                            && (
                            do {
                                ( my $val1 = $_[0] )
                                    =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
                            }
                            )
                    )
                        || (
                           Scalar::Util::blessed( $_[0] )
                        && overload::Overloaded( $_[0] )
                        && defined overload::Method( $_[0], '0+' )
                        && do {
                            ( my $val2 = $_[0] + 0 )
                                =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
                        }
                        )
                );
            },
        );
        my $mixed_inline_union = union(
            of => [ $my_int, t('ArrayRef') ],
        );
        is(
            $mixed_inline_union->name,
            undef,
            'no name if union includes anonymous types',
        );
        ok(
            $mixed_inline_union->is_anon,
            'union is anonymous if any of its constituents are anonymous'
        );

        test_constraint( $mixed_inline_union, \%tests );
    }
);

done_testing();
