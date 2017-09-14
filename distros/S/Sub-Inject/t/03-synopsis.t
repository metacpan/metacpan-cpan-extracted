
use 5.018;
use Test::More;

use Sub::Inject;

{

    BEGIN {
        Sub::Inject::sub_inject( 'one', sub {'One!'} );
    }
    is one(), 'One!', 'Subroutine in scope';
}

eval { one() };
my $err = $@;
ok( $err, 'Subroutine no longer in scope' );
like(
    $err,
    qr/^Undefined subroutine &main::one called/,
    'Expected error message'
);

done_testing;
