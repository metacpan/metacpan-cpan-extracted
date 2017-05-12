use Test::More;
use strict;
use warnings;
use DBIx::Custom;
use Test::Mojo;
use utf8;
use Encode qw/encode decode/;

no warnings 'once';

my $database = $DBViewer::database;
my $dsn = $DBViewer::dsn;
my $user = $DBViewer::user;
my $password = $DBViewer::password;
my $create_table1 = $DBViewer::create_table1;
my $create_table2 = $DBViewer::create_table2;
my $create_table3 = $DBViewer::create_table3;
my $create_table4 = $DBViewer::create_table4;
my $create_table_paging = $DBViewer::create_table_paging;
my $test_skip_message = $DBViewer::test_skip_message;
$test_skip_message = 'common.t is always skipped'
  unless defined $test_skip_message;

plan skip_all => $test_skip_message unless $DBViewer::test_run;

plan 'no_plan';

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
my $dbi;
# Test1.pm
{
  package Test1;
  use Mojolicious::Lite;
  my $connector;
  plugin(
    'DBViewer',
    dsn => $dsn,
    user => $user,
    password => $password,
    connector_get => \$connector
  );

  $dbi = DBIx::Custom->connect(connector => $connector);

  # Prepare database
  eval { $dbi->execute('drop table table1') };
  eval { $dbi->execute('drop table table2') };
  eval { $dbi->execute('drop table table3') };

  $dbi->execute($create_table1);
  $dbi->execute($create_table2);
  $dbi->execute($create_table3);

  $dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
  $dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');
}

my $app = Test1->new;
my $t = Test::Mojo->new($app);

# Top page
$t->get_ok('/dbviewer')->content_like(qr/$database\s+\(current\)/);

# Tables page
$t->get_ok("/dbviewer/tables?database=$database")
  ->content_like(qr/table1/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/)
  ->content_like(qr/Primary keys/)
  ->content_like(qr/Null allowed columns/);
$t->link_ok("/dbviewer/tables?database=$database");

# Table page
$t->get_ok("/dbviewer/table?database=$database&table=table1")
  ->content_like(qr/Create table/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/);
$t->link_ok("/dbviewer/table?database=$database&table=table1");

# Select page
$t->get_ok("/dbviewer/select?database=$database&table=table1");
$t->content_like(qr/Select.*table1/s);
$t->content_like(qr#<option value="column1_1">column1_1</option>#);
$t->content_like(qr#<input name="h" type="checkbox" value="1"( /)?> column1_1#);

# Select page(JSON)
$t->get_ok("/dbviewer/select?database=$database&table=table1&output=json")
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/)
;

# Select page(JSON)
$t->get_ok("/dbviewer/select?database=$database&table=table1&c1=column1_2&v1=4&op1=like&output=json")
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_unlike(qr/\b2\b/)
  ->content_like(qr/\b3\b/)
  ->content_like(qr/\b4\b/);

# Create tables page
$t->get_ok("/dbviewer/create-tables?database=$database")
  ->content_like(qr/Create tables/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_like(qr/column2_1/)
  ->content_like(qr/column2_2/)
  ->content_like(qr/table3/);

# Select tables page
$t->get_ok("/dbviewer/select-statements?database=$database")
  ->content_like(qr/Select/)
  ->content_like(qr/table1/)
  ->content_like(qr#\Q/select?#)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Primary keys page
$t->get_ok("/dbviewer/primary-keys?database=$database")
  ->content_like(qr/Primary keys/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_1/)
  ->content_unlike(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Null allowed column page
$t->get_ok("/dbviewer/null-allowed-columns?database=$database")
  ->content_like(qr/Null allowed column/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_unlike(qr/\Q(column2_1)/)
  ->content_unlike(qr/\Q(column2_2)/)
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
  my $connector;
  plugin(
    'DBViewer',
    route => $b,
    prefix => 'other',
    dsn => $dsn,
    user => $user,
    password => $password,
    connector_get => \$connector
  );

  $dbi = DBIx::Custom->connect(connector => $connector);

  # Prepare database
  eval { $dbi->execute('drop table table1') };
  eval { $dbi->execute('drop table table2') };
  eval { $dbi->execute('drop table table3') };

  $dbi->execute($create_table1);
  $dbi->execute($create_table2);
  $dbi->execute($create_table3);

  $dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
  $dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');
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
  ->content_like(qr/Primary keys/)
  ->content_like(qr/Null allowed columns/);
$t->link_ok("/other/tables?database=$database");

# Table page
$t->get_ok("/other/table?database=$database&table=table1")
  ->content_like(qr/Create table/)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/);
$t->link_ok("/other/table?database=$database&table=table1");

# Select page
$t->get_ok("/other/select?database=$database&table=table1")
  ->content_like(qr/table1.*Select/s)
  ->content_like(qr/column1_1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/1/)
  ->content_like(qr/2/)
  ->content_like(qr/3/)
  ->content_like(qr/4/);

# Primary keys page
$t->get_ok("/other/primary-keys?database=$database")
  ->content_like(qr/Primary keys/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_1/)
  ->content_unlike(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/);

# Null allowed column page
$t->get_ok("/other/null-allowed-columns?database=$database")
  ->content_like(qr/Null allowed column/)
  ->content_like(qr/table1/)
  ->content_like(qr/column1_2/)
  ->content_like(qr/table2/)
  ->content_unlike(qr/column2_1/)
  ->content_unlike(qr/column2_2/)
  ->content_like(qr/table3/);

{
  package Test3;
  use Mojolicious::Lite;
  my $connector;
  plugin(
    'DBViewer',
    dsn => $dsn,
    user => $user,
    password => $password,
    connector_get => \$connector
  );

  $dbi = DBIx::Custom->connect(connector => $connector);

  # Prepare database
  eval { $dbi->execute('drop table table1') };
  eval { $dbi->execute('drop table table2') };
  eval { $dbi->execute('drop table table3') };

  $dbi->execute($create_table1);
  $dbi->execute($create_table2);
  $dbi->execute($create_table3);

  $dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
  $dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');
}

# Paging test
$app = Test3->new;
$t = Test::Mojo->new($app);

# Paging
eval { $dbi->execute("drop table table_page") };
$dbi->execute($create_table_paging);
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 3510);

$t->get_ok("/dbviewer/select?database=$database&table=table_page")
  ->content_like(qr#Select#)
  ->content_like(qr/1 to 100/)
  ->content_like(qr/3510/)
  ->content_like(qr/page=1/)
  ->content_like(qr/page=2/)
  ->content_like(qr/page=3/)
  ->content_like(qr/page=4/)
  ->content_like(qr/page=5/)
  ->content_like(qr/page=6/)
  ->content_like(qr/page=7/)
  ->content_like(qr/page=8/)
  ->content_like(qr/page=9/)
  ->content_like(qr/page=10/)
  ->content_like(qr/page=11/)
  ->content_like(qr/page=12/)
  ->content_like(qr/page=13/)
  ->content_like(qr/page=14/)
  ->content_like(qr/page=15/)
  ->content_like(qr/page=16/)
  ->content_like(qr/page=17/)
  ->content_like(qr/page=18/)
  ->content_like(qr/page=19/)
  ->content_like(qr/page=20/)
  ->content_unlike(qr/page=21/);

$t->get_ok("/dbviewer/select?database=$database&table=table_page&page=11")
  ->content_like(qr#Select#)
  ->content_like(qr/3510/)
  ->content_like(qr/page=1/)
  ->content_like(qr/page=2/)
  ->content_like(qr/page=3/)
  ->content_like(qr/page=4/)
  ->content_like(qr/page=5/)
  ->content_like(qr/page=6/)
  ->content_like(qr/page=7/)
  ->content_like(qr/page=8/)
  ->content_like(qr/page=9/)
  ->content_like(qr/page=10/)
  ->content_like(qr/page=11/)
  ->content_like(qr/page=12/)
  ->content_like(qr/page=13/)
  ->content_like(qr/page=14/)
  ->content_like(qr/page=15/)
  ->content_like(qr/page=16/)
  ->content_like(qr/page=17/)
  ->content_like(qr/page=18/)
  ->content_like(qr/page=19/)
  ->content_like(qr/page=20/)
  ->content_unlike(qr/page=21/);

$t->get_ok("/dbviewer/select?database=$database&table=table_page&page=12")
  ->content_like(qr#Select#)
  ->content_like(qr/3510/)
  ->content_like(qr/page=2/)
  ->content_like(qr/page=3/)
  ->content_like(qr/page=4/)
  ->content_like(qr/page=5/)
  ->content_like(qr/page=6/)
  ->content_like(qr/page=7/)
  ->content_like(qr/page=8/)
  ->content_like(qr/page=9/)
  ->content_like(qr/page=10/)
  ->content_like(qr/page=11/)
  ->content_like(qr/page=12/)
  ->content_like(qr/page=13/)
  ->content_like(qr/page=14/)
  ->content_like(qr/page=15/)
  ->content_like(qr/page=16/)
  ->content_like(qr/page=17/)
  ->content_like(qr/page=18/)
  ->content_like(qr/page=19/)
  ->content_like(qr/page=20/)
  ->content_like(qr/page=21/)
  ->content_unlike(qr/page=22/);

$t->get_ok("/dbviewer/select?database=$database&table=table_page&page=36")
  ->content_like(qr#Select#)
  ->content_like(qr/3501 to 3510/)
  ->content_like(qr/3510/)
  ->content_unlike(qr/page=16/)
  ->content_like(qr/page=17/)
  ->content_like(qr/page=18/)
  ->content_like(qr/page=19/)
  ->content_like(qr/page=20/)
  ->content_like(qr/page=21/)
  ->content_like(qr/page=22/)
  ->content_like(qr/page=23/)
  ->content_like(qr/page=24/)
  ->content_like(qr/page=25/)
  ->content_like(qr/page=26/)
  ->content_like(qr/page=27/)
  ->content_like(qr/page=28/)
  ->content_like(qr/page=29/)
  ->content_like(qr/page=30/)
  ->content_like(qr/page=31/)
  ->content_like(qr/page=32/)
  ->content_like(qr/page=33/)
  ->content_like(qr/page=34/)
  ->content_like(qr/page=35/)
  ->content_like(qr/page=36/);

$dbi->delete_all(table => 'table_page');
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 800);

$t->get_ok("/dbviewer/select?database=$database&table=table_page")
  ->content_like(qr#Select#)
  ->content_like(qr/800/)
  ->content_like(qr/page=1/)
  ->content_like(qr/page=2/)
  ->content_like(qr/page=3/)
  ->content_like(qr/page=4/)
  ->content_like(qr/page=5/)
  ->content_like(qr/page=6/)
  ->content_like(qr/page=7/)
  ->content_like(qr/page=8/)
  ->content_unlike(qr/page=9/);

$dbi->delete_all(table => 'table_page');
$dbi->insert({column_a => 'a', column_b => 'b'}, table => 'table_page') for (1 .. 801);

$t->get_ok("/dbviewer/select?database=$database&table=table_page")
  ->content_like(qr#Select#)
  ->content_like(qr/801/)
  ->content_like(qr/page=1/)
  ->content_like(qr/page=2/)
  ->content_like(qr/page=3/)
  ->content_like(qr/page=4/)
  ->content_like(qr/page=5/)
  ->content_like(qr/page=6/)
  ->content_like(qr/page=7/)
  ->content_like(qr/page=8/)
  ->content_like(qr/page=9/);

# Condition
{
  my $url = "/dbviewer/select?database=$database";
  my $opt = 'output=json&sk1=k1&so=asc';
  eval { $dbi->execute('drop table table4') };
  $dbi->execute($create_table4);
  my $model = $dbi->create_model(table => 'table4');
  
  # contains
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 21, k2 => 1});
  $model->insert({k1 => 121, k2 => 1});
  $model->insert({k1 => 3, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=2&op1=contains")
    ->json_is('/rows', [
      [2, 1], 
      [12, 1],
      [21, 1],
      [121, 1]
    ])
    ;

  # like
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 21, k2 => 1});
  $model->insert({k1 => 121, k2 => 1});
  $model->insert({k1 => 3, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=%2%&op1=contains")
    ->json_is('/rows', [
      [2, 1], 
      [12, 1],
      [21, 1],
      [121, 1]
    ])
    ;

  # like
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 21, k2 => 1});
  $model->insert({k1 => 121, k2 => 1});
  $model->insert({k1 => 3, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=%2%&op1=like")
    ->json_is('/rows', [
      [2, 1], 
      [12, 1],
      [21, 1],
      [121, 1]
    ])
    ;
    
  # in
  $model->delete_all;
  $model->insert({k1 => 1, k2 => 1});
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 3, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1= 1  2 &op1=in")
    ->json_is('/rows', [
      [1, 1], 
      [2, 1],
    ])
    ;
  
  # =
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=2&op1==")
    ->json_is('/rows', [
      [2, 1], 
    ])
    ;
  
  # <
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 22, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=12&op1=<")
    ->json_is('/rows', [
      [2, 1], 
    ])
    ;

  # <=
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 22, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=12&op1=<=")
    ->json_is('/rows', [
      [2, 1], 
      [12, 1], 
    ])
    ;

  # >
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 22, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=12&op1=>")
    ->json_is('/rows', [
      [22, 1], 
    ])
    ;
  
  # >=
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 12, k2 => 1});
  $model->insert({k1 => 22, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&v1=12&op1=>=")
    ->json_is('/rows', [
      [12, 1], 
      [22, 1], 
    ])
    ;

  # is null
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => undef, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&op1=is null")
    ->json_is('/rows', [
      [undef, 1], 
    ])
    ;

  # is not null
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => undef, k2 => 1});
  $t->get_ok("$url&$opt&table=table4&c1=k1&op1=is not null")
    ->json_is('/rows', [
      [2, 1], 
    ])
    ;

  # is space
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 2, k2 => ''});
  $t->get_ok("$url&$opt&table=table4&c1=k2&op1=is space")
    ->json_is('/rows', [
      [2, ''], 
    ])
    ;

  # is not space
  $model->delete_all;
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 2, k2 => ''});
  $t->get_ok("$url&$opt&table=table4&c1=k2&op1=is not space")
    ->json_is('/rows', [
      [2, 1], 
    ])
    ;
  
  # Multiple condtions(or)
  $model->delete_all;
  $model->insert({k1 => 1, k2 => 1});
  $model->insert({k1 => 2, k2 => 1});
  $model->insert({k1 => 3, k2 => 1});
  $model->insert({k1 => 4, k2 => 1});
  $model->insert({k1 => 5, k2 => 1});
  
  $t->get_ok("$url&$opt&table=table4&u=or&c1=k1&op1==&v1=1&c2=k1&op2=in&v2=2 3&c3=k1&op3==&v3=4")
    ->json_is('/rows', [
      [1, 1], 
      [2, 1], 
      [3, 1], 
      [4, 1], 
    ])
    ;

  # Multiple condtions(and)
  $model->delete_all;
  $model->insert({k1 => 1, k2 => 1});
  $model->insert({k1 => 2, k2 => 2});
  $model->insert({k1 => 3, k2 => 1});
  $model->insert({k1 => 4, k2 => 1});
  $model->insert({k1 => 5, k2 => 1});
  
  $t->get_ok("$url&$opt&table=table4&u=and&c1=k1&op1==&v1=2&c2=k2&op2=in&v2=2")
    ->json_is('/rows', [
      [2, 2], 
    ])
    ;
    
  # Multiple condtions(charset)
  $model->delete_all;
  $model->insert({k1 => 1, k2 => encode('UTF-8', 'あ')});
  $model->insert({k1 => 2, k2 => encode('UTF-8', 'い')});
  $model->insert({k1 => 3, k2 => encode('UTF-8', 'う')});
  $model->insert({k1 => 4, k2 => encode('UTF-8', 'え')});
  $model->insert({k1 => 5, k2 => encode('UTF-8', 'お')});

  $t->get_ok("$url&$opt&table=table4&u=or&c1=k2&op1=contains&v1=あ&c2=k2&op2=in&v2=い う&c3=k2&op3==&v3=え");
  $t->json_is('/rows', [
      [1, 'あ'], 
      [2, 'い'], 
      [3, 'う'], 
      [4, 'え'], 
    ])
    ;
}

# Order
{
  my $url = "/dbviewer/select?database=$database";
  my $opt = 'output=json';
  eval { $dbi->execute('drop table table4') };
  $dbi->execute($create_table4);
  my $model = $dbi->create_model(table => 'table4');
  
  # Two order
  $model->insert({k1 => 1, k2 => 3});
  $model->insert({k1 => 1, k2 => 4});
  $model->insert({k1 => 2, k2 => 3});
  $model->insert({k1 => 2, k2 => 4});
  $t->get_ok("$url&$opt&table=table4&sk1=k1&so1=desc&sk2=k2&so2=desc")
    ->json_is('/rows', [
      [2, 4], 
      [2, 3],
      [1, 4],
      [1, 3]
    ])
    ;
}

# Empty prefix
{
  my $route_test;
  {
    package Test4;
    use Mojolicious::Lite;
    my $connector;
    plugin(
      'DBViewer',
      prefix => '',
      dsn => $dsn,
      user => $user,
      password => $password,
      connector_get => \$connector,
      site_title => 'Web DB Viewer'
    );

    $dbi = DBIx::Custom->connect(connector => $connector);

    # Prepare database
    eval { $dbi->execute('drop table table1') };
    eval { $dbi->execute('drop table table2') };
    eval { $dbi->execute('drop table table3') };

    $dbi->execute($create_table1);
    $dbi->execute($create_table2);
    $dbi->execute($create_table3);

    $dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
    $dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');
  }

  $app = Test4->new;
  $t = Test::Mojo->new($app);

  # Top page
  $t->get_ok('/')->content_like(qr/$database\s+\(current\)/);
  
  # Site title
  $t->get_ok('/')->content_like(qr/Web DB Viewer/);
  
  # Tables page
  $t->get_ok("/tables?database=$database")
    ->content_like(qr/table1/)
    ->content_like(qr/table2/)
    ->content_like(qr/table3/)
    ->content_like(qr/Primary keys/)
    ->content_like(qr/Null allowed columns/);
  $t->link_ok("/tables?database=$database");

  # Table page
  $t->get_ok("/table?database=$database&table=table1")
    ->content_like(qr/Create table/)
    ->content_like(qr/column1_1/)
    ->content_like(qr/column1_2/);
  $t->link_ok("/table?database=$database&table=table1");

  # Select page
  $t->get_ok("/select?database=$database&table=table1")
    ->content_like(qr/Select.*table1/s)
    ->content_like(qr/column1_1/)
    ->content_like(qr/column1_2/)
    ->content_like(qr/1/)
    ->content_like(qr/2/)
    ->content_like(qr/3/)
    ->content_like(qr/4/);

  # Primary keys page
  $t->get_ok("/primary-keys?database=$database")
    ->content_like(qr/Primary keys/)
    ->content_like(qr/table1/)
    ->content_like(qr/column1_1/)
    ->content_unlike(qr/column1_2/)
    ->content_like(qr/table2/)
    ->content_like(qr/table3/);

  # Null allowed column page
  $t->get_ok("/null-allowed-columns?database=$database")
    ->content_like(qr/Null allowed column/)
    ->content_like(qr/table1/)
    ->content_like(qr/column1_2/)
    ->content_like(qr/table2/)
    ->content_unlike(qr/column2_1/)
    ->content_unlike(qr/column2_2/)
    ->content_like(qr/table3/);
}

# Join
{
  package Test5;
  use Mojolicious::Lite;
  my $connector;
  plugin(
    'DBViewer',
    dsn => $dsn,
    user => $user,
    password => $password,
    connector_get => \$connector,
    join => {
      table1 => [
        'left join table2 on table1.column1_2 = table2.column2_1',
        'left join table3 on table2.column2_2 = table3.column3_1'
      ]
    }
  );

  my $dbi = DBIx::Custom->connect(connector => $connector);

  my $app = Test5->new;
  my $t = Test::Mojo->new($app);

  # Prepare database
  eval { $dbi->execute('drop table table1') };
  eval { $dbi->execute('drop table table2') };
  eval { $dbi->execute('drop table table3') };

  $dbi->execute($create_table1);
  $dbi->execute($create_table2);
  $dbi->execute($create_table3);
  
  # Conditions
  my $url = "/dbviewer/select?database=$database&table=table1";
  $dbi->insert({column1_1 => 1, column1_2 => 3}, table => 'table1');
  $dbi->insert({column1_1 => 2, column1_2 => 3}, table => 'table1');
  $dbi->insert({column1_1 => 7, column1_2 => 1}, table => 'table1');
  $dbi->insert({column2_1 => 3, column2_2 => 4}, table => 'table2');
  $dbi->insert({column3_1 => 4, column3_2 => 5}, table => 'table3');
  $t->get_ok("$url&j=1&c1=table3.column3_2&op1==&v1=5&sk1=table1.column1_1&so1=desc");
  $t->content_like(qr#<option value="table1\.column1_1">table1\.column1_1</option>#);
  $t->content_like(qr#<input name="h" type="checkbox" value="1"( /)?> table1\.column1_1#);
  $t->get_ok("$url&output=json&j=1&c1=table3.column3_2&op1==&v1=5&sk1=table1.column1_1&so1=desc");
  $t->json_is('/rows', [
      [2, 3, 3, 4, 4, 5], 
      [1, 3, 3, 4, 4, 5]
    ])
    ;
}