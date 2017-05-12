use strict;
use warnings;
use utf8;
use MySQL::Explain::Parser qw/parse/;
use Test::More;
use Test::Deep;

subtest 'not contains multi-byte characters' => sub {
    my $explain = <<'...';
+----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
|  1 | PRIMARY     | t1    | index | NULL          | PRIMARY | 4       | NULL | 4    | 100.00   |             |
|  2 | SUBQUERY    | t2    | index | a             | a       | 5       | NULL | 3    | 100.00   | Using index |
+----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
...

    my $expected = [
        {
            id            => 1,
            select_type   => 'PRIMARY',
            table         => 't1',
            type          => 'index',
            possible_keys => undef,
            key           => 'PRIMARY',
            key_len       => 4,
            ref           => undef,
            rows          => 4,
            filtered      => "100.00",
            Extra         => '',
        },
        {
            id            => 2,
            select_type   => 'SUBQUERY',
            table         => 't2',
            type          => 'index',
            possible_keys => 'a',
            key           => 'a',
            key_len       => 5,
            ref           => undef,
            rows          => 3,
            filtered      => "100.00",
            Extra         => 'Using index',
        }
    ];

    subtest 'basic' => sub {
        my $parsed = parse($explain);
        cmp_deeply($parsed, $expected);
    };

    subtest 'should pass if tail of description exists' => sub {
        my $parsed = parse($explain . "2 rows in set, 1 warning (0.00 sec)");
        cmp_deeply($parsed, $expected);
    };

    subtest 'should pass if blank lines are on both ends' => sub {
        my $parsed = parse("\n" . $explain . "\n");
        cmp_deeply($parsed, $expected);
    };
};

subtest 'should pass when explain contains multi-byte characters' => sub {
    my $explain = <<'...';
+----+-------------+-----------+-------+---------------+--------+---------+------+------+-------------+
| id | select_type | table     | type  | possible_keys | key    | key_len | ref  | rows | Extra       |
+----+-------------+-----------+-------+---------------+--------+---------+------+------+-------------+
|  1 | SIMPLE      | てすつ    | index | NULL          | ほげ   | 4       | NULL |    5 | Using index |
+----+-------------+-----------+-------+---------------+--------+---------+------+------+-------------+
...

    my $expected = [
        {
            id            => 1,
            select_type   => 'SIMPLE',
            table         => 'てすつ',
            type          => 'index',
            possible_keys => undef,
            key           => 'ほげ',
            key_len       => 4,
            ref           => undef,
            rows          => 5,
            Extra         => 'Using index',
        },
    ];

    my $parsed = parse($explain);
    cmp_deeply($parsed, $expected);
};

done_testing;

