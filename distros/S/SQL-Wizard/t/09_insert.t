use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# simple insert
{
  my ($sql, @bind) = $q->insert(
    -into   => 'users',
    -values => { name => 'Alice', email => 'alice@example.com' },
  )->to_sql;
  is $sql, 'INSERT INTO users (email, name) VALUES (?, ?)', 'simple insert';
  is_deeply \@bind, ['alice@example.com', 'Alice'], 'insert binds';
}

# multi-row insert
{
  my ($sql, @bind) = $q->insert(
    -into    => 'users',
    -columns => [qw/name email/],
    -values  => [
      ['Alice', 'alice@example.com'],
      ['Bob', 'bob@example.com'],
    ],
  )->to_sql;
  is $sql, 'INSERT INTO users (name, email) VALUES (?, ?), (?, ?)', 'multi-row insert';
  is_deeply \@bind, ['Alice', 'alice@example.com', 'Bob', 'bob@example.com'], 'multi-row binds';
}

# insert from SELECT
{
  my ($sql, @bind) = $q->insert(
    -into    => 'archive_users',
    -columns => [qw/id name/],
    -select  => $q->select(
      -columns => [qw/id name/],
      -from    => 'users',
      -where   => { status => 'deleted' },
    ),
  )->to_sql;
  is $sql, 'INSERT INTO archive_users (id, name) SELECT id, name FROM users WHERE status = ?', 'insert select';
  is_deeply \@bind, ['deleted'], 'insert select binds';
}

# upsert with ON CONFLICT (PostgreSQL)
{
  my ($sql, @bind) = $q->insert(
    -into   => 'counters',
    -values => { key => 'hits', value => 1 },
    -on_conflict => {
      '-target' => 'key',
      '-update' => { value => $q->raw('counters.value + EXCLUDED.value') },
    },
  )->to_sql;
  like $sql, qr/INSERT INTO counters/, 'upsert insert';
  like $sql, qr/ON CONFLICT \(key\) DO UPDATE SET value = counters\.value \+ EXCLUDED\.value/, 'on conflict';
  is_deeply \@bind, ['hits', 1], 'upsert binds';
}

# upsert with ON DUPLICATE KEY (MySQL)
{
  my ($sql, @bind) = $q->insert(
    -into   => 'counters',
    -values => { key => 'hits', value => 1 },
    -on_duplicate => {
      value => $q->raw('value + VALUES(value)'),
    },
  )->to_sql;
  like $sql, qr/ON DUPLICATE KEY UPDATE value = value \+ VALUES\(value\)/, 'on duplicate key';
}

# INSERT with RETURNING
{
  my ($sql, @bind) = $q->insert(
    -into      => 'users',
    -values    => { name => 'Alice' },
    -returning => ['id', 'created_at'],
  )->to_sql;
  like $sql, qr/RETURNING id, created_at$/, 'insert returning';
}

# insert with raw value
{
  my ($sql, @bind) = $q->insert(
    -into   => 'events',
    -values => { name => 'login', created_at => $q->raw('NOW()') },
  )->to_sql;
  like $sql, qr/VALUES \(/, 'insert with raw';
  like $sql, qr/NOW\(\)/, 'raw in insert value';
}

done_testing;
