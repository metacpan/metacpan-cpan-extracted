use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;

plan tests => 4;

    use_ok( 'TAP::Runner::Option' );

    like(
        exception { TAP::Runner::Option->new },
        qr/^Attribute \(name\) is required/,
        'Check that name required',
    );

    like(
        exception {
            TAP::Runner::Option->new(
                name => 'test_option_name',
            )
        },
        qr/^Attribute \(values\) is required/,
        'Check that values required',
    );

    cmp_deeply(
        TAP::Runner::Option->new(
            name   => 'test_option',
            values => [ 1, 2 ,3 ],
        ),
        all(
            isa( 'TAP::Runner::Option' ),
            methods(
                get_values_array => [
                    [ 'test_option' => '1' ],
                    [ 'test_option' => '2' ],
                    [ 'test_option' => '3' ],
                ],
            ),
        ),
        'get_values_array functionality test',
    );

done_testing;
