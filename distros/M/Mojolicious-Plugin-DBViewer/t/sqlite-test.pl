use Mojolicious::Lite;
use DBIx::Custom;
use FindBin;
use lib "lib";
use Mojolicious::Plugin::DBViewer;
use utf8;
use Encode qw/encode decode/;

my $connector;
plugin(
  'DBViewer',
  dsn => 'dbi:SQLite:dbname=:memory:',
  connector_get => \$connector,
  charset => 'euc-jp',
  join => {
    table1 => [
      'left join table2 on table1.key1 = table2.key1',
      'left join table3 on table2.key2 = table3.key1'
    ]
  }
);

my $dbi = DBIx::Custom->connect(connector => $connector);
eval {
  $dbi->execute('create table table1 (key1 integer primary key not null, key2 not null, key3, key4)');
  $dbi->insert({key1 => $_, key2 => $_ + 1, key3 => $_ + 2, key4 => encode('euc-jp', 'あ')}, table => 'table1') for (1 .. 2510);
  
  $dbi->execute('create table table2 (key1 integer primary key not null, key2 not null)');
  $dbi->insert({key1 => 1, key2 => 2}, table => 'table2');;

  $dbi->execute('create table table3 (key1 integer primary key not null, key2 not null)');
  $dbi->insert({key1 => 2, key2 => 3}, table => 'table3');;
};

get '/' => {text => 'a'};

app->start;

