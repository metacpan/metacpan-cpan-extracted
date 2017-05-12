package MyTest::CDBI::Simple::Product;

use strict;

use Class::DBI::AbstractSearch;

use MyTest::CDBI::Simple::Code;
use MyTest::CDBI::Simple::CodeName;
use MyTest::CDBI::Simple::Category;

use base 'MyTest::CDBI::Base';

__PACKAGE__->table('rose_db_object_test_products');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw(category_id date_created fk1 fk2 fk3 id last_modified name published status));

__PACKAGE__->has_a(category_id => 'MyTest::CDBI::Simple::Category');

__PACKAGE__->has_many(code_names => 'MyTest::CDBI::Simple::CodeName', { cascade => 'None' });

1;