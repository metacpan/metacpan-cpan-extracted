package TDSCTSchema::Result::TDSCT;

use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('tdsct');
__PACKAGE__->add_columns(qw/id/);
__PACKAGE__->set_primary_key('id');

1;