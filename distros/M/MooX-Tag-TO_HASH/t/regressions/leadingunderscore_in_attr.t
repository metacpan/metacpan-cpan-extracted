#! perl

use Test2::V0;

{
    package My::Test;
    use Moo;

    with 'MooX::Tag::TO_HASH';

    has _cow => ( is => 'ro', to_hash => ',if_exists' );
    has cow  => ( is => 'ro', to_hash => ',if_exists' );
}

my $t = My::Test->new( _cow => 'frank', cow => 'daisy' );

is( $t->TO_HASH, { _cow => 'frank', cow => 'daisy' } );

done_testing
