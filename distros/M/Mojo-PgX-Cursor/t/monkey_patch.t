use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

require Mojo::Pg;
require Mojo::PgX::Cursor;
use Mojo::Util 'monkey_patch';
monkey_patch 'Mojo::Pg::Database', 'cursor', \&Mojo::PgX::Cursor::Database::cursor;

my $pg = Mojo::Pg->new($ENV{TEST_ONLINE});
my $db = $pg->db;
$db->query('set client_min_messages=WARNING');
$db->query('drop table if exists import_test');
$db->query(
  'create table if not exists import_test (
     id   serial primary key,
     name text
  )'
);
$db->query('insert into import_test (name) values (?)', $_) for qw(foo bar);

ok !!Mojo::Pg::Database->can('cursor'), 'Mojo::Pg::Database can cursor';

{
  my $results = $pg->db->cursor('select name from import_test');
  my @names;
  while (my $row = $results->hash) {
    ok $results->rows, 'got rows';
    push @names, $row->{name};
  }
  is_deeply [sort @names], [sort qw(foo bar)], 'got both names';
}

{
  my $results = $pg->db->cursor('select name from import_test where name = (?)', 'foo');
  my @names;
  while (my $row = $results->hash) {
    ok $results->rows, 'got rows';
    push @names, $row->{name};
  }
  is_deeply [@names], ['foo'], 'got only one name';
}

$db->query('drop table import_test');

done_testing();
