package MyTest::RDBO::Simple::CodeName;

use strict;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

__PACKAGE__->meta->table('rose_db_object_test_code_names');
__PACKAGE__->meta->columns(qw(id product_id name));
__PACKAGE__->meta->primary_key_columns('id');

__PACKAGE__->meta->foreign_keys
(
  product =>
  {
    class => 'MyTest::RDBO::Simple::Product',
    key_columns => { product_id => 'id' },
  },
);

__PACKAGE__->meta->initialize;

1;