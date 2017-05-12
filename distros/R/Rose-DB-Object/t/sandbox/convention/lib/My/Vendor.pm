package My::Vendor;
use strict;
use base 'My::Object';
__PACKAGE__->meta->columns(qw(id name region_id));
__PACKAGE__->meta->foreign_keys(qw(region));
__PACKAGE__->meta->initialize;
1;
