package MyTest::DBIC::Schema::Simple::Product;

use strict;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw(Core)); 

use MyTest::DBIC::Schema::Simple::Code;
use MyTest::DBIC::Schema::Complex::CodeName;
use MyTest::DBIC::Schema::Simple::Category;

__PACKAGE__->table('rose_db_object_test_products');
__PACKAGE__->add_columns(qw(category_id date_created fk1 fk2 fk3 id last_modified name published status));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_relationship('category_id', 'MyTest::DBIC::Schema::Simple::Category',
                              { 'foreign.id' => 'self.category_id' },
                              { accessor => 'filter' });

__PACKAGE__->add_relationship('code_names', 'MyTest::DBIC::Schema::Simple::CodeName',
                              { 'foreign.product_id' => 'self.id' },
                              { accessor => 'multi', join_type => 'LEFT OUTER' });

1;
