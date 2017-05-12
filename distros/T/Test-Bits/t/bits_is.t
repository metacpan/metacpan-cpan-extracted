use strict;
use warnings;

use Test::Tester;
use Test::Fatal;
use Test::More 0.88;

use Test::Bits;

_test_bits_is(
    'x',
    [ ord('x') ],
    'x == x',
    1,
);

_test_bits_is(
    'xyz',
    [ map { ord($_) } qw( x y z ) ],
    'xyz == xyz',
    1,
);

{
    my $diag
        = 'Binary data begins differing at byte 0.' . "\n"
        . '  Got:    01111001' . "\n"
        . '  Expect: 01111000' . "\n";

    _test_bits_is(
        'y',
        [ ord('x') ],
        'y != x',
        0,
        $diag,
    );
}

{
    my $diag
        = 'Binary data begins differing at byte 2.' . "\n"
        . '  Got:    01111001' . "\n"
        . '  Expect: 01111010' . "\n";

    _test_bits_is(
        'xyy',
        [ map { ord($_) } qw( x y z ) ],
        'xyy != xyz',
        0,
        $diag,
    );
}

{
    my $diag
        = 'The two pieces of binary data are not the same length (got 2, expected 3).'
        . "\n"
        . 'Binary data begins differing at byte 1.' . "\n"
        . '  Got:    01111000' . "\n"
        . '  Expect: 01111001' . "\n";

    _test_bits_is(
        'xx',
        [ map { ord($_) } qw( x y z ) ],
        'xy != xyz',
        0,
        $diag,
    );
}

like(
    exception { bits_is( ['foo'], [42] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed a ARRAY reference as the first argument at t/bits_is.t line \E\d+},
    'got error passing an arrayref as first argument to bits_is()'
);

like(
    exception { bits_is( undef, [42] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed an undef as the first argument at t/bits_is.t line \E\d+},
    'got error passing an undef as first argument to bits_is()'
);

like(
    exception { bits_is( "\x{2048}", [42] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed a string with UTF-8 data as the first argument at t/bits_is.t line \E\d+},
    'got error passing an arrayref as first argument to bits_is()'
);

like(
    exception { bits_is( 'foo', 'foo' ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed a plain scalar as the second argument at t/bits_is.t line \E\d+},
    'got error passing a scalar as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', {} ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed a HASH reference as the second argument at t/bits_is.t line \E\d+},
    'got error passing a hashref as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', undef ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. You passed an undef as the second argument at t/bits_is.t line \E\d+},
    'got error passing an undef as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', [ 1, 2, undef ] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. The second argument contains a value which isn't a number from 0-255 at t/bits_is.t line \E\d+},
    'got error passing an arrayref with an undef as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', [ 1, 2, {} ] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. The second argument contains a value which isn't a number from 0-255 at t/bits_is.t line \E\d+},
    'got error passing an arrayref with a hashref as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', [ 1, 2, 9000 ] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. The second argument contains a value which isn't a number from 0-255 at t/bits_is.t line \E\d+},
    'got error passing an arrayref with 9000 as second argument to bits_is()'
);

like(
    exception { bits_is( 'foo', [ 1, 2, -5 ] ) },
    qr{\Qbits_is() should be passed a scalar of binary data and an array reference of numbers. The second argument contains a value which isn't a number from 0-255 at t/bits_is.t line \E\d+},
    'got error passing an arrayref with -5 as second argument to bits_is()'
);

done_testing();

sub _test_bits_is {
    my $got    = shift;
    my $expect = shift;
    my $name   = shift;
    my $ok     = shift;
    my $diag   = shift;

    check_test(
        sub { bits_is( $got, $expect, $name ) },
        {
            ok   => $ok,
            name => $name,
            diag => ( $diag || q{} ),
        },
        $name
    );
}
