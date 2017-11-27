use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );
use Specio::Library::Builtins;

{
    my $sub = validation_for(
        params => {
            foo => 1,
            bar => { optional => 1 },
        },
    );

    like(
        dies { $sub->( foo => 42, extra => [] ) },
        qr/Found extra parameters passed to an un-named validation subroutine: \[extra\]/,
        'dies when given one extra parameter'
    );

    like(
        dies { $sub->( foo => 42, extra => [], more => 0 ) },
        qr/Found extra parameters passed to an un-named validation subroutine: \[extra, more\]/,
        'dies when given two extra parameters'
    );
}

{
    my $sub = validation_for(
        params => {
            foo => 1,
        },
        slurpy => 1,
    );

    like(
        dies { $sub->() },
        qr/foo is a required parameter/,
        'foo is still required when slurpy is true'
    );

    is(
        {
            $sub->(
                foo => 42,
                bar => 'whatever',
            )
        },
        {
            foo => 42,
            bar => 'whatever',
        },
        'extra parameters are returned',
    );
}

{
    my $sub = validation_for(
        params => {
            foo => 1,
        },
        slurpy => t('Int'),
    );

    like(
        dies { $sub->() },
        qr/foo is a required parameter/,
        'foo is still required when slurpy is a type constraint'
    );

    is(
        {
            $sub->(
                foo => 42,
                bar => 43,
            )
        },
        {
            foo => 42,
            bar => 43,
        },
        'extra parameters are returned when they pass the type constraint',
    );

    like(
        dies {
            $sub->( foo => 42, bar => 'string' );
        },
        qr/Validation failed for type named Int.+with value "string"/,
        'extra parameters are type checked with one extra',
    );

    like(
        dies {
            $sub->( foo => 42, baz => 1, bar => 'string' );
        },
        qr/Validation failed for type named Int.+with value "string"/,
        'all extra parameters are type checked with multiple extras',
    );
}

done_testing();
