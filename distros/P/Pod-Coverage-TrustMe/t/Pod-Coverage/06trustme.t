use strict;
use warnings;
use Test::More;
use lib 't/Pod-Coverage/lib';

use Pod::Coverage::TrustMe;

my $obj = Pod::Coverage::TrustMe->new(package => 'Trustme');
isa_ok( $obj, 'Pod::Coverage::TrustMe' );
is($obj->coverage, 3/7, "without private or trustme it gets it right");

$obj = Pod::Coverage::TrustMe->new(package => 'Trustme', private => [qr/^private$/]);
isa_ok( $obj, 'Pod::Coverage::TrustMe' );
is($obj->coverage, 3/6, "with just private it gets it right");

$obj = Pod::Coverage::TrustMe->new(
    package => 'Trustme',
    private => [qr/^private$/],
    trustme => [qr/u/],
);
isa_ok( $obj, 'Pod::Coverage::TrustMe' );
is($obj->coverage, 5/6, "with private and trustme it gets it right");

$obj = Pod::Coverage::TrustMe->new(
    package => 'Trustme',
    trustme => [qr/u/],
);
isa_ok( $obj, 'Pod::Coverage::TrustMe' );
is($obj->coverage, 5/7, "with just trustme it gets it right");

done_testing;
