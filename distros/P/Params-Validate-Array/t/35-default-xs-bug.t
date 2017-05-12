use strict;
use warnings;

use Test::More 0.88;

use Params::Validate::Array qw( :all );

default_test();

done_testing();

sub default_test {
    my ( $first, $second ) = validate_pos(
        @_,
        { type => SCALAR, optional => 1 },
        { type => SCALAR, optional => 1, default => 'must be second one' },
    );

    is( $first, undef, '01 no default for first' );
    is( $second, 'must be second one', '01 default for second' );
}
