use strict;
use warnings;

use Test::More;

use SQL::Composer::Upsert;

subtest 'build upsert for SQLite' => sub {
    my $expr = SQL::Composer::Upsert->new(
        into => 'table',
        values => [ id => 1, name => 'foo' ],
        driver => 'SQLite'
    );

    my $sql = $expr->to_sql;
    is $sql, 'INSERT OR REPLACE INTO `table` (`id`,`name`) VALUES (?,?)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [1, 'foo'];
};

subtest 'build upsert for MySQL' => sub {
    my $expr = SQL::Composer::Upsert->new(
        into => 'table',
        values => [ id => 1, name => 'foo' ],
        driver => 'MySQL'
    );

    my $sql = $expr->to_sql;
    is $sql, 'INSERT INTO `table` (`id`,`name`) VALUES (?,?) ON DUPLICATE KEY UPDATE `id` = VALUES(`id`), `name` = VALUES(`name`)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [1, 'foo'];
};

subtest 'build upsert for Pg' => sub {
    my $expr = SQL::Composer::Upsert->new(
        into => 'table',
        values => [ id => 1, name => 'foo' ],
        driver => 'Pg'
    );

    my $sql = $expr->to_sql;
    is $sql, 'INSERT INTO "table" ("id","name") VALUES (?,?) ON CONFLICT DO UPDATE';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [1, 'foo'];
};

done_testing;
