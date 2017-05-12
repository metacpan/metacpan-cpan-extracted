use strict;
use warnings;

use Params::Validate qw(validate);
use Test::More;

{
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };

    my @p = ( foo => undef );
    eval { validate( @p, { foo => { regex => qr/^bar/ } } ) };
    ok( $@,  'validation failed' );
    ok( !@w, 'no warnings' );
}

done_testing();
