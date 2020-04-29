use strict;
use warnings;
use lib 'lib';
use Test::More;
use SQL::Bind qw(sql);

subtest 'no placeholder' => sub {
    my ($sql, @bind) = sql 'SELECT foo FROM bar';

    is $sql, 'SELECT foo FROM bar';
    is_deeply \@bind, [];
};

subtest 'scalars' => sub {
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id AND status=:status',
      id     => 1,
      status => 'active';

    is $sql, 'SELECT foo FROM bar WHERE id=? AND status=?';
    is_deeply \@bind, [1, 'active'];
};

subtest 'raw scalars' => sub {
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id!',
      id => 'parent_id';

    is $sql, 'SELECT foo FROM bar WHERE id=parent_id';
    is_deeply \@bind, [];
};

subtest 'arrays' => sub {
    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id)', id => [1, 2, 3];

    is $sql, 'SELECT foo FROM bar WHERE id IN (?, ?, ?)';
    is_deeply \@bind, [1, 2, 3];
};

subtest 'raw arrays' => sub {
    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id!)', id => [qw/one two three/];

    is $sql, 'SELECT foo FROM bar WHERE id IN (one, two, three)';
    is_deeply \@bind, [];
};

subtest 'keys and values' => sub {
    my ($sql, @bind) = sql 'INSERT INTO bar (:keys!) VALUES (:values)',
      keys   => [qw/foo/],
      values => [qw/bar/];

    is $sql, 'INSERT INTO bar (foo) VALUES (?)';
    is_deeply \@bind, ['bar'];
};

subtest 'hashes' => sub {
    my ($sql, @bind) = sql 'UPDATE bar SET :columns', columns => {foo => 'bar'};

    is $sql, 'UPDATE bar SET foo=?';
    is_deeply \@bind, ['bar'];
};

subtest 'raw hashes' => sub {
    my ($sql, @bind) = sql 'UPDATE bar SET :columns!', columns => {foo => 'bar'};

    is $sql, 'UPDATE bar SET foo=bar';
    is_deeply \@bind, [];
};

subtest 'names' => sub {
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:CamelCase AND status=:alpha_123',
      CamelCase => 1,
      alpha_123 => 'active';

    is $sql, 'SELECT foo FROM bar WHERE id=? AND status=?';
    is_deeply \@bind, [1, 'active'];
};

done_testing;
