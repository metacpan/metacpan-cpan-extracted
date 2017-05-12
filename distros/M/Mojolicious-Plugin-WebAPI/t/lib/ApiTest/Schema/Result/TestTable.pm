package
    ApiTest::Schema::Result::TestTable;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('testtable');
__PACKAGE__->add_columns(qw/ id title description ticket_id /);
__PACKAGE__->set_primary_key('id');

1;
