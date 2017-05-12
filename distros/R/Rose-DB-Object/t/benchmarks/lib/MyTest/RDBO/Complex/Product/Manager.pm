package MyTest::RDBO::Complex::Product::Manager;

use strict;

use MyTest::RDBO::Complex::Product;

use Rose::DB::Object::Manager;
our @ISA = qw(Rose::DB::Object::Manager);

__PACKAGE__->make_manager_methods(
  base_name    => 'products',
  object_class => 'MyTest::RDBO::Complex::Product');

1;
