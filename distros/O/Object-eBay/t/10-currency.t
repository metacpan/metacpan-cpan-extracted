use strict;
use warnings;
use Test::More tests => 7;
use Object::eBay::Currency;

{
    my $c = Object::eBay::Currency->new({
        object_details => {
            content => 123,
            currencyID => 'USD',
        }
    });
    is( "$c", 'USD123.00', 'string context' );
    cmp_ok( $c, '==', 123, 'numeric context' );
    ok( !(!$c), 'boolean context' );
}

{
    my $c = Object::eBay::Currency->new({
        object_details => {
            content => '0.0',
            currencyID => 'USD',
        }
    });
    is( "$c", 'USD0.00', '0 string context' );
    cmp_ok( $c, '==', 0, '0 numeric context' );
    ok( !$c, '0 boolean context' );

}

eval {
    Object::eBay::Currency->new({ nothing => 123 });
};
like( $@, qr{Missing 'content' and/or 'currencyID'}, 'invalid construction' );
