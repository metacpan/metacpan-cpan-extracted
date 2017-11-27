use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );

{
    my $sub = validation_for(
        params => [
            bar => 0,
            foo => 1,
        ],
        named_to_list => 1,
    );

    is(
        [ $sub->( foo => 'test' ) ], [ undef, 'test' ],
        'passing required param returns optional values as undef'
    );

    is(
        [ $sub->( foo => 'test', bar => 'b' ) ], [ 'b', 'test' ],
        'optional params are returned as expected'
    );
}

{
    # We have to handle a single named argument specially to avoid warnings.
    validation_for(
        params => [
            bar => 0,
        ],
        named_to_list => 1,
    );
}

done_testing();
