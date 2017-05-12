package ComponentUI::Model::TestDB;

use lib 't/lib';
use base qw/Catalyst::Model::DBIC::Schema/;

__PACKAGE__->config(
  schema_class => 'RTest::TestDB',
  connect_info => [ 'dbi:SQLite:t/var/reaction_test_withdb.db' ]
);

1;
