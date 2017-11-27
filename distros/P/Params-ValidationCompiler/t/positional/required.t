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
            {
                type     => t('Int'),
                optional => 1,
            },
        ],
    );

    is(
        dies { $sub->(42) },
        undef,
        'lives when given 1st param but no 2nd'
    );

    is(
        dies { $sub->( 42, 42 ) },
        undef,
        'lives when given 1st and 2nd params'
    );

    like(
        dies { $sub->() },
        qr/Got 0 parameters but expected at least 1/,
        'dies when not given any params'
    );
}

{
    like(
        dies {
            validation_for(
                params => [
                    { optional => 1 },
                    { type     => t('Int') },
                ],
            );
        },
        qr/\QParameter list contains an optional parameter followed by a required parameter/,
        'cannot have positional parameters where an optional param comes before a required one'
    );

    like(
        dies {
            validation_for(
                params => [
                    { default => 42 },
                    { type    => t('Int') },
                ],
            );
        },
        qr/\QParameter list contains an optional parameter followed by a required parameter/,
        'cannot have positional parameters where a param with a default comes before a required one'
    );
}

done_testing();
