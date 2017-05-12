use strict;
use warnings;
use Test::More;
use SQL::Object qw/sql_obj sql_type/;

subtest 'basic' => sub {
    my $sql = sql_obj('foo.id=:id',+{id => 1});
    is $sql->as_sql, 'foo.id=?';
    is_deeply [$sql->bind], [qw/1/];

    $sql->and('bar.name=?','nekokak');
    is $sql->as_sql, 'foo.id=? AND bar.name=?';
    is_deeply [$sql->bind], [qw/1 nekokak/];

    $sql->or('bar.age=?', '33');
    is $sql->as_sql, '(foo.id=? AND bar.name=?) OR bar.age=?';
    is_deeply [$sql->bind], [qw/1 nekokak 33/];

    my $cond = sql_obj('foo.id=?', 2);
    $sql = $sql | $cond;
    is $sql->as_sql, '((foo.id=? AND bar.name=?) OR bar.age=?) OR (foo.id=?)';
    is_deeply [$sql->bind], [qw/1 nekokak 33 2/];

    $cond = sql_obj('bar.name=?','tokuhirom');
    $sql = $sql | $cond;
    is $sql->as_sql, '(((foo.id=? AND bar.name=?) OR bar.age=?) OR (foo.id=?)) OR (bar.name=?)';
    is_deeply [$sql->bind], [qw/1 nekokak 33 2 tokuhirom/];

    is $sql->as_sql , '(((foo.id=? AND bar.name=?) OR bar.age=?) OR (foo.id=?)) OR (bar.name=?)';

    $sql = sql_obj('SELECT * FROM user WHERE ') + $sql;

    is $sql->as_sql , 'SELECT * FROM user WHERE (((foo.id=? AND bar.name=?) OR bar.age=?) OR (foo.id=?)) OR (bar.name=?)';
};

subtest 'sql_type' => sub {
    my $var = 1;
    my $sql = sql_obj('foo.id=?',sql_type(\$var, 'SQL_INTEGER'));
    is $sql->as_sql, 'foo.id=?';
    my $bind = $sql->bind;
    is $bind->[0]->value_ref, \$var;
    is $bind->[0]->value    , 1;
    is $bind->[0]->type     , 'SQL_INTEGER';
};

done_testing;

