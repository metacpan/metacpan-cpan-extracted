package MyTest::DBIC::Schema::Complex::Category;

use strict;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw(Core)); 

__PACKAGE__->table('rose_db_object_test_categories');
__PACKAGE__->add_columns(qw(id name));
__PACKAGE__->set_primary_key('id');

1;

