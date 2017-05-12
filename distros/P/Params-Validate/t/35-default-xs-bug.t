use strict;
use warnings;

use Test::More 0.88;

use Params::Validate qw( :all );

default_test();

done_testing();

sub default_test {
    my ( $first, $second ) = validate_pos(
        @_,
        { type => SCALAR, optional => 1 },
        { type => SCALAR, optional => 1, default => 'must be second one' },
    );

    is( $first, undef, 'no default for first parameter' );
    is( $second, 'must be second one',
        'default for second parameter is applied' );
}
