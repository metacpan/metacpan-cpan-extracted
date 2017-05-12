use strict;
use warnings;
use FindBin;
use File::Basename 'dirname';

{
  package DBViewer;
  our $database = 'main';
  our $dsn = 'dbi:SQLite:dbname=:memory:';
  our $user;
  our $password;
  our $test_run = 1;
  our $test_skip_message = '';

  our $create_table1 = <<'EOS';
    create table table1 (
      column1_1 integer primary key not null,
      column1_2
    );
EOS

  our $create_table2 = <<'EOS';
    create table table2 (
      column2_1 not null,
      column2_2 not null
    );
EOS

  our $create_table3 = <<'EOS';
    create table table3 (
      column3_1 not null,
      column3_2 not null
    );
EOS

  our $create_table4 = <<'EOS';
    create table table4 (
      k1 integer,
      k2
    );
EOS

  our $create_table_paging = 'create table table_page (column_a, column_b)';
}

require "$FindBin::Bin/common-basic.t";
