package TestSchema::Result::TemplateOwner;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('TemplateOwner');
__PACKAGE__->add_columns(
    qw/id name/
);

__PACKAGE__->set_primary_key('id');

1;
