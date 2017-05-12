use strict;
use warnings;
use Test::More tests => 3;
use Object::eBay::Condition;

{
    my $c = Object::eBay::Condition->new({
        id   => 1999,
        name => 'Testing',
    });
    is( "$c", 'Testing', 'string context' );
    cmp_ok( $c, '==', 1999, 'numeric context' );
}

eval {
    Object::eBay::Condition->new({ nothing => 123 });
};
like( $@, qr{Missing ConditionID}, 'invalid construction' );
