use Test::More;
use strict;
use warnings;
use DBIx::Custom;
use Test::Mojo;
use Mojo::HelloWorld;
use FindBin;

my $test_run = -f "$FindBin::Bin/run/mysql-only.run" ? 1 : 0;
my $test_skip_message = 'mysql private test';

plan skip_all => $test_skip_message unless $test_run;

plan 'no_plan';

my $database = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_DATABASE}
  // 'mojomysqlviewer';
my $dsn = "dbi:mysql:database=$database";
my $user = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_USER}
  // 'mojomysqlviewer';
my $password = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_PASSWORD}
  // 'mojomysqlviewer';

my $create_table1 = <<'EOS';
  create table table1 (
    column1_1 int,
    column1_2 int,
    primary key (column1_1)
  ) engine=MyIsam charset=ujis;
EOS

my $create_table2 = <<'EOS';
  create table table2 (
    column2_1 int not null,
    column2_2 int not null
  ) engine=InnoDB charset=utf8;
EOS

my $create_table3 = <<'EOS';
  create table table3 (
    column3_1 int not null,
    column3_2 int not null
  ) engine=InnoDB;
EOS

my $create_table_paging
  = 'create table table_page (column_a varchar(10), column_b varchar(10))';

{
  package Test::Mojo;
  sub link_ok {
    my ($self, $url) = @_;
    
    my $content = $self->get_ok($url)->tx->res->body;
    while ($content =~ /<a\s+href\s*=\s*"([^"]+?)"/smg) {
      my $link = $1;
      next if $link eq '#';
      next if $link =~ /^http/;
      $self->get_ok($link);
    }
  }
}

my $dbi = DBIx::Custom->connect(
  dsn => $dsn,
  user => $user,
  password => $password
);

# Prepare database
eval { $dbi->execute('drop table table1') };
eval { $dbi->execute('drop table table2') };
eval { $dbi->execute('drop table table3') };

$dbi->execute($create_table1);
$dbi->execute($create_table2);
$dbi->execute($create_table3);

$dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
$dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');

# Test1.pm
{
  package Test1;
  use Mojolicious::Lite;
  plugin(
    'DBViewer',
    dsn => $dsn,
    user => $user,
    password => $password
  );
}

my $app = Test1->new;
my $t = Test::Mojo->new($app);

# Tables page
$t->get_ok("/dbviewer/tables?database=$database")
  ->content_like(qr/Database engines/);

# Database engines page
$t->get_ok("/dbviewer/database-engines?database=$database")
  ->content_like(qr/Database engines/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(MyISAM)/)
  ->content_like(qr/table2/)
  ->content_like(qr/\Q(InnoDB)/)
  ->content_like(qr/table3/);

# Charsets
$t->get_ok("/dbviewer/charsets?database=$database")
  ->content_like(qr/Charsets/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(ujis)/)
  ->content_like(qr/table2/)
  ->content_like(qr/\Q(utf8)/)
  ->content_like(qr/table3/);

# Paging test
{
  package Test3;
  use Mojolicious::Lite;
  plugin(
    'DBViewer',
    dsn => $dsn,
    user => $user,
    password => $password
  );
}
