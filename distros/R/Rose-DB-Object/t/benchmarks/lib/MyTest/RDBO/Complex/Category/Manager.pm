package MyTest::RDBO::Complex::Category::Manager;

use strict;

use MyTest::RDBO::Complex::Category;

use Rose::DB::Object::Manager;
our @ISA = qw(Rose::DB::Object::Manager);

__PACKAGE__->make_manager_methods(
  base_name    => 'categories',
  object_class => 'MyTest::RDBO::Complex::Category');

1;