use strict;
use warnings;
package TestSchema::TestObject;
use parent 'DBIx::Class';

use Mixin::ExtraFields -fields => {
  driver => { class => 'DBIC', rs_moniker => 'TestObjectExtra' }
};

__PACKAGE__->load_components(qw/Core PK::Auto/);
__PACKAGE__->table('objects');

__PACKAGE__->add_columns(
  id => {
    data_type   => 'int',
    is_nullable => 0,
    is_auto_increment => 1,
  },

  object_name => {
    data_type   => 'varchar',
    size        => 32,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');

1;
