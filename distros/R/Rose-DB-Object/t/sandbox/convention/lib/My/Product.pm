package My::Product;
use strict;
use base 'My::Object';
__PACKAGE__->meta->columns(qw(id name vendor_id));
__PACKAGE__->meta->foreign_keys(qw(vendor));
__PACKAGE__->meta->relationships
(
  prices => { type => 'one to many' },
  colors => { type => 'many to many' },
);
__PACKAGE__->meta->initialize;
1;
