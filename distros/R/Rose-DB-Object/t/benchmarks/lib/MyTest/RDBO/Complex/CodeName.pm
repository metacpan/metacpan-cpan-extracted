package MyTest::RDBO::Complex::CodeName;

use strict;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

use Rose::DB::Object::Helpers
{
  insert_or_update => 'insert_or_update_std',
  insert_or_update_on_duplicate_key => 'insert_or_update',
};

__PACKAGE__->meta->table('rose_db_object_test_code_names');
__PACKAGE__->meta->columns(qw(id product_id name));
__PACKAGE__->meta->primary_key_columns('id');

__PACKAGE__->meta->unique_key('name');

__PACKAGE__->meta->foreign_keys
(
  product =>
  {
    class => 'MyTest::RDBO::Complex::Product',
    key_columns => { product_id => 'id' },
  },
);

__PACKAGE__->meta->initialize;

1;