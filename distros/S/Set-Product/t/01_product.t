use strict;
use warnings;
use Test::More;

if (eval { require Set::Product::XS; 1 }) {
    eval { BEGIN { $ENV{SET_PRODUCT_PP} = 1 } };
}
use Set::Product qw(product);

ok defined &product, 'product() is exported';
ok \&Set::Product::product == \&Set::Product::PP::product,
    'product uses PP implementation';

done_testing;
