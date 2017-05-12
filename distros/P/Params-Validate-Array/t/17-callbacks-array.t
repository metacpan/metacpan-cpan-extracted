use strict;
use warnings;

use Params::Validate::Array qw(validate validate_pos SCALAR);
use Test::More;

{
    my @p = ( foo => 1, bar => 2 );

    eval {
        validate(
            @p, [
                foo => {
                    type      => SCALAR,
                    callbacks => {
                        'bigger than bar' => sub { $_[0] > $_[1]->{bar} }
                    },
                },
                bar => { type => SCALAR },
            ]
        );
    };

    like( $@, qr/bigger than bar/ );

    $p[1] = 3;
    eval {
        validate(
            @p, [
                foo => {
                    type      => SCALAR,
                    callbacks => {
                        'bigger than bar' => sub { $_[0] > $_[1]->{bar} }
                    },
                },
                bar => { type => SCALAR },
            ]
        );
    };

    is( $@, q{} );
}

done_testing();
