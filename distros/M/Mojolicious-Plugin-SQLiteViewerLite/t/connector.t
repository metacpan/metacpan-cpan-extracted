use Test::More;
use strict;
use warnings;
use DBIx::Custom;
use Test::Mojo;
use Mojo::HelloWorld;

plan skip_all => "required DBIx::Connector"
  unless eval { require DBIx::Connector; 1};

plan 'no_plan';

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

my $database = 'main';
my $dbi = DBIx::Custom->connect(
  dsn => 'dbi:SQLite:dbname=:memory:',
  connector => 1
);

# Prepare database
eval { $dbi->execute('drop table table1') };
eval { $dbi->execute('drop table table2') };
eval { $dbi->execute('drop table table3') };

$dbi->execute(<<'EOS');
create table table1 (
  column1_1 integer primary key not null,
  column1_2
);
EOS

$dbi->execute(<<'EOS');
create table table2 (
  column2_1 not null,
  column2_2 not null
);
EOS

$dbi->execute(<<'EOS');
create table table3 (
  column3_1 not null,
  column3_2 not null
);
EOS

$dbi->insert({column1_1 => 1, column1_2 => 2}, table => 'table1');
$dbi->insert({column1_1 => 3, column1_2 => 4}, table => 'table1');

# Test1.pm
{
    package Test1;
    use Mojolicious::Lite;
    plugin 'SQLiteViewerLite', connector => $dbi->connector;
}
my $app = Test1->new;
my $t = Test::Mojo->new($app);

# Top page
$t->get_ok('/sqliteviewerlite')->content_like(qr/$database\s+\(current\)/);

# Tables page
$t->get_ok("/sqliteviewerlite/tables?database=$database")
  ->content_like(qr/table1/)
  ->content_like(qr/table2/)
  ->content_like(qr/table3/)
  ->content_like(qr/Show primary keys/)
  ->content_like(qr/Show null allowed columns/);
$t->link_ok("/sqliteviewerlite/tables?database=$database");
