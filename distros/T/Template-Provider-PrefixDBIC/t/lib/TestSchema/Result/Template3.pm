package TestSchema::Result::Template3;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('Template3');
__PACKAGE__->add_columns(
    qw/owner_id name prefix content modified/
);

__PACKAGE__->has_one(owner => 'TestSchema::Result::TemplateOwner', {
    'foreign.id' => 'self.owner_id',
});

1;
