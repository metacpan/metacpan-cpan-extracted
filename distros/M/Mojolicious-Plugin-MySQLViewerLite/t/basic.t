use Test::More;
use strict;
use warnings;
use DBIx::Custom;
use Test::Mojo;
use Mojo::HelloWorld;

{
  package Test::Mojo;
  sub link_ok {
    my ($self, $url) = @_;
    
    my $content = $self->get_ok($url)->tx->res->body;
    while ($content =~ /<a\s+href\s*=\s*"([^"]+?)"/smg) {
      my $link = $1;
      $self->get_ok($link);
    }
  }
}

my $database = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_DATABASE}
  // 'mojomysqlviewer';
my $dsn = "dbi:mysql:database=$database";
my $user = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_USER}
  // 'mojomysqlviewer';
my $password = $ENV{MOJOLICIOUS_PLUGIN_MYSQLVIEWERLITE_TEST_PASSWORD}
  // 'mojomysqlviewer';

my $dbi;
eval {
  $dbi = DBIx::Custom->connect(
    dsn => $dsn,
    user => $user,
    password => $password
  );
};

plan skip_all => 'MySQL private test' if $@;

plan 'no_plan';

# Prepare database
eval { $dbi->execute('drop table table1') };
eval { $dbi->execute('drop table table2') };
eval { $dbi->execute('drop table table3') };

$dbi->execute(<<'EOS');
create table table1 (
  column1_1 int,
  column1_2 int,
  primary key (column1_1)
) engine=MyIsam charset=ujis;
EOS

$dbi->execute(<<'EOS');
create table table2 (
  column2_1 int not null,
  column2_2 int not null
) engine=InnoDB charset=utf8;
EOS

$dbi->execute(<<'EOS');
create table table3 (
  column3_1 int not null,
  column3_2 int not null
) engine=InnoDB;
EOS

$dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
$dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');

# Test1.pm
{
    package Test1;
    use Mojolicious::Lite;
    plugin 'MySQLViewerLite', dbh => $dbi->dbh;
}
my $app = Test1->new;
my $t = Test::Mojo->new($app);

# Top page
$t->get_ok('/mysqlviewerlite')->content_like(qr/$database\s+\(current\)/);

# Tables page
$t->get_ok("/mysqlviewerlite/tables?database=$database")
  ->content_like(qr/table1/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/)
  ->content_like(qr/Show primary keys/)
  ->content_like(qr/Show null allowed columns/)
  ->content_like(qr/Show database engines/);
$t->link_ok("/mysqlviewerlite/tables?database=$database");

# Table page
$t->get_ok("/mysqlviewerlite/table?database=$database&table=table1")
  ->content_like(qr/show create table/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/);
$t->link_ok("/mysqlviewerlite/table?database=$database&table=table1");

# Select page
$t->get_ok("/mysqlviewerlite/select?database=$database&table=table1")
  ->content_like(qr#\Qselect * from <i>table1</i>#)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table1&condition_column=column1_2&condition_value=4")
  ->content_like(qr#\Qselect * from <i>table1</i>#)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_unlike(qr/\b2\b/)
  ->content_like(qr/\b3\b/)
  ->content_like(qr/\b4\b/);

# Show create tables page
$t->get_ok("/mysqlviewerlite/showcreatetables?database=$database")
  ->content_like(qr/Create tables/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_like(qr/column2_1/)
  ->content_like(qr/column2_2/)
  ->content_like(qr/table3/);

# Show select tables page
$t->get_ok("/mysqlviewerlite/showselecttables?database=$database")
  ->content_like(qr/Select tables/)
  ->content_like(qr/table1/)
  ->content_like(qr#\Q/select?#)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Show Primary keys page
$t->get_ok("/mysqlviewerlite/showprimarykeys?database=$database")
  ->content_like(qr/Primary keys/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(`column1_1`)/)
  ->content_unlike(qr/\Q(`column1_2`)/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Show Null allowed column page
$t->get_ok("/mysqlviewerlite/shownullallowedcolumns?database=$database")
  ->content_like(qr/Null allowed column/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(`column1_2`)/)
  ->content_like(qr/table2/)
  ->content_unlike(qr/\Q(`column2_1`)/)
  ->content_unlike(qr/\Q(`column2_2`)/)
  ->content_like(qr/table3/);

# Show Database engines page
$t->get_ok("/mysqlviewerlite/showdatabaseengines?database=$database")
  ->content_like(qr/Database engines/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(MyISAM)/)
  ->content_like(qr/table2/)
  ->content_like(qr/\Q(InnoDB)/)
  ->content_like(qr/table3/);

# Show Charsets
$t->get_ok("/mysqlviewerlite/showcharsets?database=$database")
  ->content_like(qr/Charsets/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(ujis)/)
  ->content_like(qr/table2/)
  ->content_like(qr/\Q(utf8)/)
  ->content_like(qr/table3/);

# Other route and prefix
# Test2.pm
my $route_test;
{
    package Test2;
    use Mojolicious::Lite;
    my $r = app->routes;
    my $b = $r->under(sub {
      $route_test = 1;
      return 1;
    });
    plugin 'MySQLViewerLite', dbi => $dbi, route => $b, prefix => 'other';
}
$app = Test2->new;
$t = Test::Mojo->new($app);

# Top page
$t->get_ok('/other')->content_like(qr/$database\s+\(current\)/);
is($route_test, 1);

# Tables page
$t->get_ok("/other/tables?database=$database")
  ->content_like(qr/table1/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/)
  ->content_like(qr/Show primary keys/)
  ->content_like(qr/Show null allowed columns/)
  ->content_like(qr/Show database engines/);
$t->link_ok("/other/tables?database=$database");

# Table page
$t->get_ok("/other/table?database=$database&table=table1")
  ->content_like(qr/show create table/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/);
$t->link_ok("/other/table?database=$database&table=table1");

# Select page
$t->get_ok("/other/select?database=$database&table=table1")
  ->content_like(qr#\Qselect * from <i>table1</i>#)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/);

# Show Primary keys page
$t->get_ok("/other/showprimarykeys?database=$database")
  ->content_like(qr/Primary keys/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(`column1_1`)/)
  ->content_unlike(qr/\Q(`column1_2`)/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Show Null allowed column page
$t->get_ok("/other/shownullallowedcolumns?database=$database")
  ->content_like(qr/Null allowed column/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(`column1_2`)/)
  ->content_like(qr/table2/)
  ->content_unlike(qr/\Q(`column2_1`)/)
  ->content_unlike(qr/\Q(`column2_2`)/)
  ->content_like(qr/table3/);

# Show Database engines page
$t->get_ok("/other/showdatabaseengines?database=$database")
  ->content_like(qr/Database engines/)
  ->content_like(qr/table1/)
  ->content_like(qr/\Q(MyISAM)/)
  ->content_like(qr/table2/)
  ->content_like(qr/\Q(InnoDB)/)
  ->content_like(qr/table3/);

# Paging test
$app = Test1->new;
$t = Test::Mojo->new($app);
# Paging
eval { $dbi->execute('drop table table_page') };
$dbi->execute('create table table_page (column_a varchar(10), column_b varchar(10))');
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 3510);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/1 to 100/)
  ->content_like(qr/3510/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
  ->content_like(qr/5/)
  ->content_like(qr/6/)
  ->content_like(qr/7/)
  ->content_like(qr/8/)
  ->content_like(qr/9/)
  ->content_like(qr/10/)
  ->content_like(qr/11/)
  ->content_like(qr/12/)
  ->content_like(qr/13/)
  ->content_like(qr/14/)
  ->content_like(qr/15/)
  ->content_like(qr/16/)
  ->content_like(qr/17/)
  ->content_like(qr/18/)
  ->content_like(qr/19/)
  ->content_like(qr/20/)
  ->content_unlike(qr/21/);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page&page=11")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/3510/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
  ->content_like(qr/5/)
  ->content_like(qr/6/)
  ->content_like(qr/7/)
  ->content_like(qr/8/)
  ->content_like(qr/9/)
  ->content_like(qr/10/)
  ->content_like(qr/11/)
  ->content_like(qr/12/)
  ->content_like(qr/13/)
  ->content_like(qr/14/)
  ->content_like(qr/15/)
  ->content_like(qr/16/)
  ->content_like(qr/17/)
  ->content_like(qr/18/)
  ->content_like(qr/19/)
  ->content_like(qr/20/)
  ->content_unlike(qr/21/);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page&page=12")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/3510/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
  ->content_like(qr/5/)
  ->content_like(qr/6/)
  ->content_like(qr/7/)
  ->content_like(qr/8/)
  ->content_like(qr/9/)
  ->content_like(qr/10/)
  ->content_like(qr/11/)
  ->content_like(qr/12/)
  ->content_like(qr/13/)
  ->content_like(qr/14/)
  ->content_like(qr/15/)
  ->content_like(qr/16/)
  ->content_like(qr/17/)
  ->content_like(qr/18/)
  ->content_like(qr/19/)
  ->content_like(qr/20/)
  ->content_like(qr/21/)
  ->content_unlike(qr/22/);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page&page=36")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/3501 to 3510/)
  ->content_like(qr/3510/)
  ->content_unlike(qr/\b16\b/)
  ->content_like(qr/17/)
  ->content_like(qr/18/)
  ->content_like(qr/19/)
  ->content_like(qr/20/)
  ->content_like(qr/21/)
  ->content_like(qr/22/)
  ->content_like(qr/23/)
  ->content_like(qr/24/)
  ->content_like(qr/25/)
  ->content_like(qr/26/)
  ->content_like(qr/27/)
  ->content_like(qr/28/)
  ->content_like(qr/29/)
  ->content_like(qr/30/)
  ->content_like(qr/31/)
  ->content_like(qr/32/)
  ->content_like(qr/33/)
  ->content_like(qr/34/)
  ->content_like(qr/35/)
  ->content_like(qr/36/);

$dbi->delete_all(table => 'table_page');
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 800);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/800/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
  ->content_like(qr/5/)
  ->content_like(qr/6/)
  ->content_like(qr/7/)
  ->content_like(qr/\b8\b/)
  ->content_unlike(qr/ 9 /);

$dbi->delete_all(table => 'table_page');
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 801);

$t->get_ok("/mysqlviewerlite/select?database=$database&table=table_page")
  ->content_like(qr#\Qselect * from <i>table_page</i>#)
  ->content_like(qr/801/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
  ->content_like(qr/5/)
  ->content_like(qr/6/)
  ->content_like(qr/7/)
  ->content_like(qr/\b8\b/)
  ->content_like(qr/\b9\b/)

