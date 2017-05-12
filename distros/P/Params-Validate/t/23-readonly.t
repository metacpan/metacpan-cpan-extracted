use strict;
use warnings;

use Test::Requires {
    Readonly       => '1.03',
    'Scalar::Util' => '1.20',
};

use Params::Validate qw(validate validate_pos SCALAR);
use Test::More;

plan skip_all => 'These tests fail with Readonly 1.50 for some reason'
    if Readonly::->VERSION() =~ /^v?1.5/;

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

{
    Readonly my %spec => ( foo => { type => SCALAR } );
    my @p = ( foo => 'hello' );

    eval { validate( @p, \%spec ) };
    is( $@, q{}, 'validate() call succeeded with Readonly spec hash' );
}

done_testing();
