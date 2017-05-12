BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;

use Params::Validate qw(validate);
use Test::More;

{
    my @p = ( foo => 1 );

    eval { validate( @p, { foo => { type => 'SCALAR' } }, ); };

    like(
        $@,
        qr/\QThe 'foo' parameter ("1") has a type specification which is not a number. It is a string - SCALAR/
    );
}

{
    my @p = ( foo => 1 );

    eval { validate( @p, { foo => { type => undef } }, ); };

    like(
        $@,
        qr/\QThe 'foo' parameter ("1") has a type specification which is not a number. It is undef/
    );

}

done_testing();

