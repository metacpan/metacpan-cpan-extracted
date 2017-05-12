use Mojolicious::Lite;

use DBIx::Custom;
use FindBin;
use lib "lib";

use Mojolicious::Plugin::SQLiteViewerLite;
my $dbi = DBIx::Custom->connect(
  dsn => 'dbi:SQLite:dbname=:memory:',
);
eval {
  $dbi->execute('create table table1 (key1 integer primary key not null, key2 not null, key3)');
  $dbi->insert({key1 => $_, key2 => $_ + 1, key3 => $_ + 2}, table => 'table1') for (1 .. 2510);
};

plugin 'SQLiteViewerLite', dbi => $dbi, prefix => 'sqliteviewer';

get '/' => {text => 'a'};

app->start;

