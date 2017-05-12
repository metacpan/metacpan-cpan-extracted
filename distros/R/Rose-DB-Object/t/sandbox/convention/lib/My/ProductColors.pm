package My::ProductColors;
use strict;
use base 'My::Object';
__PACKAGE__->meta->columns(qw(id product_id color_code));
__PACKAGE__->meta->foreign_keys(qw(product color));
__PACKAGE__->meta->initialize;
1;
