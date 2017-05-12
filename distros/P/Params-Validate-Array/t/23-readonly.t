use strict;
use warnings;

use Params::Validate::Array qw(validate validate_pos SCALAR);
use Test::More;

BEGIN {
    eval "use Readonly";
    if ( $@ || !defined $Readonly::XS::VERSION ) {
        plan skip_all => 'Need Readonly::XS and Readonly for this test';
    }
}

{
    Readonly my $spec => { foo => 1 };
    my @p = ( foo => 'hello' );

    eval { validate( @p, $spec ) };
    is( $@, q{}, 'validate() call succeeded with Readonly spec hashref' );
}

{
    Readonly my $spec => { type => SCALAR };
    my @p = 'hello';

    eval { validate_pos( @p, $spec ) };
    is( $@, q{}, 'validate_pos() call succeeded with Readonly spec hashref' );
}

done_testing();
