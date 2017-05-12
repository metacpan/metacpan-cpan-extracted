use strict;
use warnings;
use Test::More;
use SQL::Object::Interp qw/isql_obj/;

subtest 'basic' => sub {
    my $sql = isql_obj('foo.id =', \1, 'AND', 'bar.name =', \'nekokak');
    is $sql->as_sql, 'foo.id = ? AND bar.name = ?';
    is_deeply [$sql->bind], [qw/1 nekokak/];

    my $class = 5;
    $sql->and('baz.class =', \$class);
    is $sql->as_sql, 'foo.id = ? AND bar.name = ? AND baz.class = ?';
    is_deeply [$sql->bind], [qw/1 nekokak 5/];

    my $bar_age = 33;
    $sql->or('bar.age =', \$bar_age);
    is $sql->as_sql, '(foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?';
    is_deeply [$sql->bind], [qw/1 nekokak 5 33/];

    my $cond = isql_obj('foo.id =', \2);
    $sql = $sql | $cond;
    is $sql->as_sql, '((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?)';
    is_deeply [$sql->bind], [qw/1 nekokak 5 33 2/];

    $cond = isql_obj('bar.name =',\'tokuhirom');
    $sql = $sql & $cond;
    is $sql->as_sql, '((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?) AND bar.name = ?';
    is_deeply [$sql->bind], [qw/1 nekokak 5 33 2 tokuhirom/];

    $sql = isql_obj('SELECT * FROM user WHERE ') + $sql;

    is $sql->as_sql, 'SELECT * FROM user WHERE ((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?) AND bar.name = ?';

    my $sql_no = isql_obj;
    $sql_no->and('foo.id =', \2);
    is $sql_no->as_sql, 'foo.id = ?';
    is_deeply [$sql_no->bind], [2];
};

done_testing;

