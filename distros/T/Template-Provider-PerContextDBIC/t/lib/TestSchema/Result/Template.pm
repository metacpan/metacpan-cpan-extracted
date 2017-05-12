package TestSchema::Result::Template;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('Template');
__PACKAGE__->add_columns(
    qw/tmpl_name site content modified/
);

1;
