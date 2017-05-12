package TestSchema::Result::Template3;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('Template3');
__PACKAGE__->add_columns(
    qw/site_id tmpl_name content modified/
);

__PACKAGE__->has_one(site => 'TestSchema::Result::TemplateSite', {
    'foreign.id' => 'self.site_id',
});

1;
