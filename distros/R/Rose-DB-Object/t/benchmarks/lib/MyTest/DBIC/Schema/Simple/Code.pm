package MyTest::DBIC::Schema::Simple::Code;

use strict;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw(Core)); 

__PACKAGE__->table('rose_db_object_test_codes');
__PACKAGE__->add_columns(qw(code k1 k2 k3));
__PACKAGE__->set_primary_key('k1', 'k2', 'k3');

1;
