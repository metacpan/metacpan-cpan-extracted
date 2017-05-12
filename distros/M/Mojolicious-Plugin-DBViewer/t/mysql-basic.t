use strict;
use warnings;
use FindBin;
use File::Basename 'dirname';

{
  package DBViewer;
  our $database = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_DATABASE}
    // 'mojomysqlviewer';
  our $dsn = "dbi:mysql:database=$database";
  our $user = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_USER}
    // 'mojomysqlviewer';
  our $password = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_PASSWORD}
    // 'mojomysqlviewer';
  
  our $test_run = -f "$FindBin::Bin/run/mysql-basic.run" ? 1 : 0;
  our $test_skip_message = 'mysql private test';

  our $create_table1 = <<'EOS';
    create table table1 (
      column1_1 int,
      column1_2 int,
      primary key (column1_1)
    ) engine=MyIsam charset=ujis;
EOS

  our $create_table2 = <<'EOS';
    create table table2 (
      column2_1 int not null,
      column2_2 int not null
    ) engine=InnoDB charset=utf8;
EOS

  our $create_table3 = <<'EOS';
    create table table3 (
      column3_1 int not null,
      column3_2 int not null
    ) engine=InnoDB;
EOS

  our $create_table4 = <<'EOS';
    create table table4 (
      k1 int,
      k2 varchar(100)
    ) engine=InnoDB charset=utf8;
EOS
  our $create_table_paging
    = 'create table table_page (column_a varchar(10), column_b varchar(10))';
}

require "$FindBin::Bin/common-basic.t";
