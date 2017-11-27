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
            bar => {
                type     => t('Int'),
                optional => 1,
            },
        },
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when given foo param but no bar'
    );

    is(
        dies { $sub->( foo => 42, bar => 42 ) },
        undef,
        'lives when given foo and bar params'
    );

    like(
        dies { $sub->( bar => 42 ) },
        qr/foo is a required parameter/,
        'dies when not given foo param'
    );
}

done_testing();
