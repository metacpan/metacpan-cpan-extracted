use strict;
use warnings;

use FindBin qw($Bin);
use File::Slurp;
use File::Temp;
use Test::More;

eval 'use DBD::Sqlite';
plan skip_all => 'DBD::Sqlite not installed' if $@; 

use_ok( 'Sql::Textify' );

my $test_ref = [
  {
    name => 'SQLite create table',
    sql_file => "$Bin/sqlite.tests/create.sql",
    results => [
      {
        format => ['markdown', 'table'],
        text_file => "$Bin/sqlite.tests/create.markdown-table",
      },
      {
        format => ['markdown', 'record'],
        text_file => "$Bin/sqlite.tests/create.markdown-record",
      },
      {
        format => ['html', 'table'],
        text_file => "$Bin/sqlite.tests/create.html-table",
      },
      {
        format => ['html', 'record'],
        text_file => "$Bin/sqlite.tests/create.html-record",
      },
    ]
  },
  {
    name => 'SQLite select from table',
    sql_file => "$Bin/sqlite.tests/select.sql",
    results => [
      {
        format => ['markdown', 'table'],
        text_file => "$Bin/sqlite.tests/select.markdown-table",
      },
      {
        format => ['markdown', 'record'],
        text_file => "$Bin/sqlite.tests/select.markdown-record",
      },
      {
        format => ['html', 'table'],
        text_file => "$Bin/sqlite.tests/select.html-table",
      },
      {
        format => ['html', 'record'],
        text_file => "$Bin/sqlite.tests/select.html-record",
      },
    ]
  },
];


my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $t = Sql::Textify->new;

foreach my $test (@{ $test_ref }) {

    foreach my $result (@{ $test->{results} }) {
        $t->{format} = $result->{format}[0];
        $t->{layout} = $result->{format}[1];

        my $sql = read_file($test->{sql_file});
        $sql =~ s/\btmp\b/$dir/;

        my $text = read_file($result->{text_file});

        is( $t->textify($sql), $text, "Test name=$test->{name}, format=$result->{format}[0], layout=$result->{format}[1]" );
    }
}

done_testing;