use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );

{
    my $sub = validation_for(
        params => {
            foo => { default => 42 },
            bar => { default => undef },
            baz => { default => 'string' },
            buz => {
                default => sub { [] }
            },
        },
    );

    is(
        { $sub->() },
        {
            foo => 42,
            bar => undef,
            baz => 'string',
            buz => [],
        },
        'all defaults are used when no values are passed'
    );

    is(
        { $sub->( foo => 99 ) },
        {
            foo => 99,
            bar => undef,
            baz => 'string',
            buz => [],
        },
        'defaults are not used when when a value is passed'
    );
}

done_testing();
