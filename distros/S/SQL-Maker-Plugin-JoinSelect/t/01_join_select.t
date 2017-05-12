use strict;
use warnings;
use Test::More;
use SQL::Maker;

SQL::Maker->load_plugin('JoinSelect');

subtest 'sqlite' => sub {
    my $builder = SQL::Maker->new(driver => 'SQLite', new_line => ' ');

    subtest basic => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => 'user.id = item.user_id',
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM "user" INNER JOIN "item" ON user.id = item.user_id WHERE ("user"."id" = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => [
                    'left outer' => 'user.id = item.user_id'
                ],
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM "user" LEFT OUTER JOIN "item" ON user.id = item.user_id WHERE ("user"."id" = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user_item => [
                user      => ['user_id'],
                item      => ['left' => ['item_id']],
            ],
            ['*'],
            {
                'user_item.user_id' => 1,
            },
        );

        is $sql,
            'SELECT * FROM "user_item" INNER JOIN "user" USING ("user_id") LEFT JOIN "item" USING ("item_id") WHERE ("user_item"."user_id" = ?)';
        is $binds[0], 1;
    };
};

subtest 'mysql' => sub {
    my $builder = SQL::Maker->new(driver => 'mysql', new_line => ' ');

    subtest basic => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => 'user.id = item.user_id',
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM `user` INNER JOIN `item` ON user.id = item.user_id WHERE (`user`.`id` = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => [
                    'left outer' => 'user.id = item.user_id'
                ],
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM `user` LEFT OUTER JOIN `item` ON user.id = item.user_id WHERE (`user`.`id` = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => [
                    'left outer' => {'user.id' => 'item.user_id'}
                ],
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM `user` LEFT OUTER JOIN `item` ON `user`.`id` = `item`.`user_id` WHERE (`user`.`id` = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user => [
                item => {'user.id' => 'item.user_id'},
            ],
            ['*'],
            {
                'user.id' => 1,
            },
        );
        is $sql, 'SELECT * FROM `user` INNER JOIN `item` ON `user`.`id` = `item`.`user_id` WHERE (`user`.`id` = ?)';
        is $binds[0], 1;
    };

    subtest 'specifying join type' => sub {
        my ($sql, @binds) = $builder->join_select(
            user_item => [
                user      => ['user_id'],
                item      => ['left' => ['item_id']],
            ],
            ['*'],
            {
                'user_item.user_id' => 1,
            },
        );

        is $sql,
            'SELECT * FROM `user_item` INNER JOIN `user` USING (`user_id`) LEFT JOIN `item` USING (`item_id`) WHERE (`user_item`.`user_id` = ?)';
        is $binds[0], 1;
    };
};

done_testing;
