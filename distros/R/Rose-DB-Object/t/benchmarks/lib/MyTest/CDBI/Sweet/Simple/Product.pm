package MyTest::CDBI::Sweet::Simple::Product;

use strict;

use Class::DBI::AbstractSearch;

use base 'MyTest::CDBI::Sweet::Base';

use MyTest::CDBI::Sweet::Simple::Code;
use MyTest::CDBI::Sweet::Simple::CodeName;
use MyTest::CDBI::Sweet::Simple::Category;

__PACKAGE__->table('rose_db_object_test_products');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw(category_id date_created fk1 fk2 fk3 id last_modified name published status));

__PACKAGE__->has_a(category_id => 'MyTest::CDBI::Sweet::Simple::Category');

__PACKAGE__->has_many(code_names => 'MyTest::CDBI::Sweet::Simple::CodeName', { cascade => 'None' });

# Dunno why I have to do this, but it doesn't work without it...
my $meta = __PACKAGE__->meta_info(has_many => 'code_names');
$meta->args->{'foreign_key'} = 'product_id';

1;