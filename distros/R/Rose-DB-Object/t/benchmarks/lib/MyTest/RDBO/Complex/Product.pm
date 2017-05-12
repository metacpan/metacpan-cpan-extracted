package MyTest::RDBO::Complex::Product;

use strict;

use MyTest::RDBO::Complex::Code;
use MyTest::RDBO::Complex::Category;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

__PACKAGE__->meta->table('rose_db_object_test_products');

__PACKAGE__->meta->columns
(
  id            => { type => 'serial', primary_key => 1 },
  name          => { type => 'varchar' },
  category_id   => { type => 'integer' },
  status        => { type => 'varchar' },
  fk1           => { type => 'integer' },
  fk2           => { type => 'integer' },
  fk3           => { type => 'integer' },
  published     => { type => 'datetime' },
  last_modified => { type => 'datetime' },
  date_created  => { type => 'datetime' },
);

__PACKAGE__->meta->foreign_keys
(
  category =>
  {
    class => 'MyTest::RDBO::Complex::Category',
    key_columns =>
    {
      category_id => 'id',
    }
  },

  code =>
  {
    class => 'MyTest::RDBO::Complex::Code',
    key_columns =>
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    }
  }
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