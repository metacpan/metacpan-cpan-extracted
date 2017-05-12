package TestSchema::Result::Template4;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('Template4');
__PACKAGE__->add_columns(
    qw/gopher hamster dog cat/
);

1;
