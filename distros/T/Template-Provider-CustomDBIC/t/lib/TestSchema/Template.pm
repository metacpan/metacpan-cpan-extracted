package # hide from PAUSE
    TestSchema::Template;

use strict;
use warnings;

use base qw/ DBIx::Class /;


__PACKAGE__->load_components( 'PK::Auto', 'Core' );

__PACKAGE__->table('template');
__PACKAGE__->add_columns(
    'name',     { data_type => 'VARCHAR',  size => 4 },
    'modified', { data_type => 'DATETIME'            },
    'content',  { data_type => 'TEXT'                }
);

__PACKAGE__->set_primary_key('name');
__PACKAGE__->add_unique_constraint( 'name', ['name'] );



1;
