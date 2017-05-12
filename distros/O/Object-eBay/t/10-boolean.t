use strict;
use warnings;
use Test::More tests => 9;

use Object::eBay::Boolean;

{
    my $b = Object::eBay::Boolean->new({ object_details => 'true' });
    is( "$b", 'true', 'true: string' );
    ok( $b, 'true: boolean' );
}

{
    my $b = Object::eBay::Boolean->new({ object_details => 'false' });
    is( "$b", 'false', 'false: string' );
    ok( !$b, 'false: boolean' );
}

# test the quick object creating methods
{
    my $b = Object::eBay::Boolean->true;
    is( "$b", 'true', 'true: string' );
    ok( $b, 'true: boolean' );
}

{
    my $b = Object::eBay::Boolean->false;
    is( "$b", 'false', 'false: string' );
    ok( !$b, 'false: boolean' );
}

eval {
    Object::eBay::Boolean->new({ object_details => 'bad value' });
};
like( $@, qr/Invalid boolean value 'bad value'/, 'invalid boolean value' );
