package MyTest::CDBI::Sweet::Complex::Product;

use strict;

use Class::DBI::AbstractSearch;

use base 'MyTest::CDBI::Sweet::Base';

use MyTest::CDBI::Sweet::Complex::Code;
use MyTest::CDBI::Sweet::Complex::CodeName;
use MyTest::CDBI::Sweet::Complex::Category;

__PACKAGE__->table('rose_db_object_test_products');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw(category_id date_created fk1 fk2 fk3 id last_modified name published status));

__PACKAGE__->has_a(date_created => 'DateTime',
                   inflate => sub { $MyTest::CDBI::Base::DB->parse_datetime(shift) },
                   deflate => sub { $MyTest::CDBI::Base::DB->format_datetime(shift) });

__PACKAGE__->has_a(last_modified => 'DateTime',
                   inflate => sub { $MyTest::CDBI::Base::DB->parse_datetime(shift) },
                   deflate => sub { $MyTest::CDBI::Base::DB->format_datetime(shift) });

__PACKAGE__->has_a(published => 'DateTime',
                   inflate => sub { $MyTest::CDBI::Base::DB->parse_datetime(shift) },
                   deflate => sub { $MyTest::CDBI::Base::DB->format_datetime(shift) });

__PACKAGE__->has_a(category_id => 'MyTest::CDBI::Sweet::Complex::Category');

__PACKAGE__->has_many(code_names => 'MyTest::CDBI::Sweet::Complex::CodeName', { cascade => 'None' });

# Dunno why I have to do this, but it doesn't work without it...
my $meta = __PACKAGE__->meta_info(has_many => 'code_names');
$meta->args->{'foreign_key'} = 'product_id';

1;
