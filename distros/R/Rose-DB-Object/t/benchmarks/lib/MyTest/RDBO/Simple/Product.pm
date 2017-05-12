package MyTest::RDBO::Simple::Product;

use strict;

use MyTest::RDBO::Simple::Code;
use MyTest::RDBO::Simple::Category;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

__PACKAGE__->meta->table('rose_db_object_test_products');

__PACKAGE__->meta->columns
(
  qw(category_id date_created fk1 fk2 fk3 id last_modified name published status)
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys
(
  category => 
  {
    class => 'MyTest::RDBO::Simple::Category',
    key_columns => 
    {
      category_id => 'id',
    },
  },

  code => 
  {
    class => 'MyTest::RDBO::Simple::Code',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);

__PACKAGE__->meta->relationships
(
  code_names =>
  {
    type  => 'one to many',
    class => 'MyTest::RDBO::Simple::CodeName',
    column_map => { id => 'product_id' },
  }
);

__PACKAGE__->meta->initialize;

1;