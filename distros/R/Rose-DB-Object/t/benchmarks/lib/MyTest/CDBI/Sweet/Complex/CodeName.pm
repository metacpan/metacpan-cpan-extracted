package MyTest::CDBI::Sweet::Complex::CodeName;

use strict;

use base 'MyTest::CDBI::Sweet::Base';

__PACKAGE__->table('rose_db_object_test_code_names');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw(id product_id name));

__PACKAGE__->has_a(product_id => 'MyTest::CDBI::Complex::Product');

1;