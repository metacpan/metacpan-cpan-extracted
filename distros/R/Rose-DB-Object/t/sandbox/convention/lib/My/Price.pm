package My::Price;
use strict;
use base 'My::Object';
__PACKAGE__->meta->columns(qw(price_id product_id region price));
__PACKAGE__->meta->foreign_keys(qw(product));
__PACKAGE__->meta->initialize;
1;
