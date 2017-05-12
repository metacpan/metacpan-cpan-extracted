use Test::More 'no_plan';
use strict;
use warnings;
use DBIx::Custom;
use Test::Mojo;
use utf8;
use Encode qw/encode decode/;

# Charset test (UTF-8 default)
{
  my $dsn = 'dbi:SQLite:dbname=:memory:';

  my $connector;
  {
    package Test1;
    use Mojolicious::Lite;
    plugin('DBViewer', dsn => $dsn, connector_get => \$connector);
  }
  
  my $dbi = DBIx::Custom->connect(connector => $connector);
  $dbi->execute('create table t1 (k1)');
  $dbi->insert({k1 => encode('UTF-8', 'あ')}, table => 't1');

  my $app = Test1->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok("/dbviewer/select?database=main&table=t1&v1=あ")
    ->content_like(qr/あ/);
}

# Charset test (euc-jp)
{
  my $dsn = 'dbi:SQLite:dbname=:memory:';

  my $connector;
  {
    package Test2;
    use Mojolicious::Lite;
    plugin(
      'DBViewer',
      dsn => $dsn,
      connector_get => \$connector,
      charset => 'euc-jp'
    );
  }
  
  my $dbi = DBIx::Custom->connect(connector => $connector);
  $dbi->execute('create table t1 (k1)');
  $dbi->insert({k1 => encode('euc-jp', 'あ')}, table => 't1');

  my $app = Test2->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok("/dbviewer/select?database=main&table=t1&v1=あ")
    ->content_like(qr/あ/);
}

# footer_text and footer_link option
{
  my $dsn = 'dbi:SQLite:dbname=:memory:';

  my $connector;
  {
    package Test3;
    use Mojolicious::Lite;
    plugin(
      'DBViewer',
      dsn => $dsn,
      footer_text => 'Web DB Viewer',
      footer_link => 'http://some.com'
    );
  }
  
  my $app = Test3->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok("/dbviewer")
    ->content_like(qr/Web DB Viewer/)
    ->content_like(qr#\Qhttp://some.com#);
}
