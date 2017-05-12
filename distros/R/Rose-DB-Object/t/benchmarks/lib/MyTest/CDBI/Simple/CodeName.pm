package MyTest::CDBI::Simple::CodeName;

use strict;

use base 'MyTest::CDBI::Base';

__PACKAGE__->table('rose_db_object_test_code_names');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw(id product_id name));

__PACKAGE__->has_a(product_id => 'MyTest::CDBI::Simple::Product');

1;