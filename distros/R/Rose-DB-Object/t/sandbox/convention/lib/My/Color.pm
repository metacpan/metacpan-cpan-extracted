package My::Color;
use strict;
use base 'My::Object';
__PACKAGE__->meta->columns(qw(code name));
__PACKAGE__->meta->primary_key_columns('code');
__PACKAGE__->meta->initialize;
1;
