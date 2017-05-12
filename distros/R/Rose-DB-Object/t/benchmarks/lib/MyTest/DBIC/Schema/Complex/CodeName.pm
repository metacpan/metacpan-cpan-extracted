package MyTest::DBIC::Schema::Complex::CodeName;

use strict;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw(Core)); 

__PACKAGE__->table('rose_db_object_test_code_names');
__PACKAGE__->add_columns(qw(id product_id name));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(name_key => [ 'name' ]);

__PACKAGE__->add_relationship('product_id', 'MyTest::DBIC::Schema::Complex::Product',
                            { 'foreign.id' => 'self.product_id' },
                            { accessor => 'filter' });

1;
