package MyTest::CDBI::Complex::Product;

use strict;

use Class::DBI::AbstractSearch;

use MyTest::CDBI::Complex::Code;
use MyTest::CDBI::Complex::CodeName;
use MyTest::CDBI::Complex::Category;

use base 'MyTest::CDBI::Base';

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

__PACKAGE__->has_a(category_id => 'MyTest::CDBI::Complex::Category');

__PACKAGE__->has_many(code_names => 'MyTest::CDBI::Complex::CodeName', { cascade => 'None' });

1;