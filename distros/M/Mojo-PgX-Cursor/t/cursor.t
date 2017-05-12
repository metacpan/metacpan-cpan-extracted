use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

require Mojo::Pg;
require Mojo::PgX::Cursor::Cursor;

my $pg = Mojo::Pg->new($ENV{TEST_ONLINE});
my $db = $pg->db;
$db->query('set client_min_messages=WARNING');
$db->query('drop table if exists cursor_test');
$db->query(
  'create table if not exists cursor_test (
     id   serial primary key,
     name text
  )'
);
$db->query('insert into cursor_test (name) values (?)', $_) for qw(foo bar);

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    query => 'select name from cursor_test',
  );
  is $cursor, undef, 'missing db returns empty';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
  );
  is $cursor, undef, 'no query returns empty';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
    query => '',
  );
  is $cursor, undef, 'empty query returns empty';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
    name => 'my_cursor',
    query => 'select name from cursor_test',
  );
  is $cursor->name, 'my_cursor', 'name can be specified';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
    name => 'my_cursor',
    query => 'select name from cursor_test',
  );
  my $results = $cursor->fetch;
  ok $results->rows, 'fetched some';
}

{
  my $closed;
  no warnings qw(once redefine);
  local *Mojo::PgX::Cursor::Cursor::close = sub { $closed++};
  {
    my $cursor = Mojo::PgX::Cursor::Cursor->new(
      db => $pg->db,
      name => 'my_cursor',
      query => 'select name from cursor_test',
    );
    $cursor->db->disconnect;
  }
  ok !$closed, 'close was not called when db was disconnected';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
    query => 'select name from cursor_test',
  );
  my $results = $cursor->fetch(3);
  is $results->rows, 2, 'got 2 rows even though we tried to fetch 3';
  is_deeply $results->arrays->flatten->sort->to_array, [sort qw(foo bar)], 'got both names';
  ok $cursor->close, 'closed cursor';
  ok !$cursor->close, 'second call to close fails';
  my $name = $cursor->name;
  eval { $db->query(qq(fetch all from "$name")) };
  like $@, qr/$name/, 'fetch from closed cursor failed';
}

{
  my $name;
  {
    my $cursor = Mojo::PgX::Cursor::Cursor->new(
      db => $db,
      query => 'select name from cursor_test',
    );
    $name = $cursor->name;
  }
  eval { $db->query(qq(fetch all from "$name")) };
  like $@, qr/$name/, 'fetch from destroyed cursor failed';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $db,
    name => 'my_cursor',
    query => 'select name from cursor_test',
  );
  my $results;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $cursor->fetch($delay->begin);
    },
    sub {
      $results = $_[2];
    },
  )->wait;
  ok $results->rows, 'fetched some';
}

{
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db => $pg->db,
    query => 'select name from cursor_test',
  );
  isnt $cursor->db, $db;
  $cursor->db(undef);
  is $cursor->db, undef;
}

$db->query('drop table cursor_test');

done_testing();
