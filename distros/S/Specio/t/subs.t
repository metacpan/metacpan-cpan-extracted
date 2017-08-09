use strict;
use warnings;

use lib 't/lib';

use Test::Fatal;
use Test::More 0.96;
use Test::Specio qw( builtins_tests describe :vars );

use Specio::Declare;
use Specio::Subs qw(
    Specio::Library::Builtins
    Specio::Library::NoInline
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

{
    my $tests = builtins_tests( $GLOB, $GLOB_OVERLOAD, $GLOB_OVERLOAD_FH );
    for my $name ( sort keys %{$tests} ) {
        test_subs( $name, $tests->{$name} );
    }

    test_subs( 'IntNI', $tests->{Int} );
}

{
    like(
        exception { Specio::Subs->import('Specio::Library::CannotSub') },
        qr/Cannot use 'My Type' type to create a check sub. It results in an invalid Perl subroutine name/,
        'got exception trying to make subs from a library where the types are not valid sub names'
    );
}
subtest(
    'coercions',
    sub {
        is(
            exception { Specio::Subs->import('Specio::Library::Coercions') },
            undef,
            'no exception making subs from library with coercions'
        );

        is(
            to_IntC( [ 1, 2, 3 ] ),
            3,
            'to_IntC(ARRAYREF) returns 3'
        );

        is(
            force_IntC( [ 1, 2, 3 ] ),
            3,
            'force_IntC(ARRAYREF) returns 3'
        );

        is(
            to_IntC( { a => 1, b => 2 } ),
            2,
            'to_IntC(HASHREF) returns 2'
        );

        is(
            force_IntC( { a => 1, b => 2 } ),
            2,
            'force_IntC(HASHREF) returns 2'
        );

        is_deeply(
            to_IntC( \'x' ),
            \'x',
            'to_IntC(SCALARREF) returns original value'
        );

        like(
            exception { force_IntC( \'x' ) },
            qr/Validation failed for type named IntC/,
            'force_IntC(SCALARREF) throws exception'
        );

    }
);

sub test_subs {
    my $name  = shift;
    my $tests = shift;

    my $is_sub = 'is_' . $name;
    my $is     = __PACKAGE__->can($is_sub)
        or die "No sub named $is_sub in main";
    my $assert = __PACKAGE__->can( 'assert_' . $name );

    subtest(
        $name,
        sub {
            for my $val ( @{ $tests->{accept} } ) {
                ok( $is->($val), 'is: ' . describe($val) );
                is(
                    exception { $assert->($val) },
                    undef,
                    'assert: ' . describe($val)
                );
            }

            for my $val ( @{ $tests->{reject} } ) {
                ok( !$is->($val), '!is: ' . describe($val) );
                like(
                    exception { $assert->($val) },
                    qr/Validation failed/,
                    '!assert: ' . describe($val)
                );
            }
        }
    );
}

done_testing();
