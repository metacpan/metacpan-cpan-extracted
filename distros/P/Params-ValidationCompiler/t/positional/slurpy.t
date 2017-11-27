use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );
use Specio::Library::Builtins;

{
    my $sub = validation_for(
        params => [
            1,
            { optional => 1 },
        ],
    );

    like(
        dies { $sub->( 42, 43, 44 ) },
        qr/Got 1 extra parameter/,
        'dies when given one extra parameter'
    );

    like(
        dies { $sub->( 42, 43, 44, 'whuh' ) },
        qr/Got 2 extra parameters/,
        'dies when given two extra parameters'
    );
}

{
    my $sub = validation_for(
        params => [
            1,
        ],
        slurpy => 1,
    );

    like(
        dies { $sub->() },
        qr/Got 0 parameters but expected at least 1/,
        'foo is still required when slurpy is true'
    );

    is(
        [ $sub->( 42, 'whatever' ) ],
        [ 42, 'whatever' ],
        'extra parameters are returned',
    );
}

{
    my $sub = validation_for(
        params => [
            1,
        ],
        slurpy => t('Int'),
    );

    like(
        dies { $sub->() },
        qr/Got 0 parameters but expected at least 1/,
        'foo is still required when slurpy is a type constraint'
    );

    is(
        [ $sub->( 42, 43 ) ],
        [ 42, 43 ],
        'one extra parameter is returned when they pass the type constraint',
    );

    is(
        [ $sub->( 42, 43, 44 ) ],
        [ 42, 43, 44 ],
        'two extra parameters are returned when they pass the type constraint',
    );
}

done_testing();
