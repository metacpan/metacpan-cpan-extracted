package TestSchema::Result::Template2;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('Template2');
__PACKAGE__->add_columns(
    qw/owner name prefix content modified/
);

1;
