package MyTest::DBIC::Schema::Complex::Product;

use strict;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw(Core)); 

use MyTest::DBIC::Schema::Complex::Code;
use MyTest::DBIC::Schema::Complex::CodeName;
use MyTest::DBIC::Schema::Complex::Category;

__PACKAGE__->table('rose_db_object_test_products');
__PACKAGE__->add_columns(qw(category_id date_created fk1 fk2 fk3 id last_modified name published status));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->inflate_column(date_created => {
                   inflate => sub 
                   {
                     $MyTest::DBIC::Schema::DB->parse_datetime($_[0]) 
                   },
                   deflate => sub 
                   { 
                     my $arg = shift;
                     if(ref $arg eq 'SCALAR')
                     {
                       $arg = $MyTest::DBIC::Schema::DB->parse_datetime($$arg);
                     }
                     $MyTest::DBIC::Schema::DB->format_datetime($arg) 
                   } });

__PACKAGE__->inflate_column(last_modified => {
                   inflate => sub 
                   {
                     $MyTest::DBIC::Schema::DB->parse_datetime($_[0]) 
                   },
                   deflate => sub 
                   { 
                     my $arg = shift;
                     if(ref $arg eq 'SCALAR')
                     {
                       $arg = $MyTest::DBIC::Schema::DB->parse_datetime($$arg);
                     }
                     $MyTest::DBIC::Schema::DB->format_datetime($arg) 
                   } });

__PACKAGE__->inflate_column(published => {
                   inflate => sub 
                   {
                     $MyTest::DBIC::Schema::DB->parse_datetime($_[0]) 
                   },
                   deflate => sub 
                   { 
                     my $arg = shift;
                     if(ref $arg eq 'SCALAR')
                     {
                       $arg = $MyTest::DBIC::Schema::DB->parse_datetime($$arg);
                     }
                     $MyTest::DBIC::Schema::DB->format_datetime($arg) 
                   } });

__PACKAGE__->add_relationship('category_id', 'MyTest::DBIC::Schema::Complex::Category',
                              { 'foreign.id' => 'self.category_id' },
                              { accessor => 'filter' });

__PACKAGE__->add_relationship('code_names', 'MyTest::DBIC::Schema::Complex::CodeName',
                              { 'foreign.product_id' => 'self.id' },
                              { accessor => 'multi' });
1;
