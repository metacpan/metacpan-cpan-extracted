#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [
    {
        id   => 1,
        data => [1.1, 'd1_2'],
    },
    {
        id   => 2,
        data => [2.1, 'd2_2'],
    },
    {
        id   => 1,
        data => [1.1, 'd1_3'],
    },
    {
        id   => 1,
        data => [1, 'd1_2'],
    },
];

my $q = QBit::QueryData->new(
    data       => $data,
    fields     => [qw(id data)],
    definition => {
        'id'       => {type => 'number'},
        'data.[0]' => {type => 'number'},
        'data.[1]' => {type => 'string'},
    }
);

$q->order_by(['data.[1]', 1], ['data.[0]', 0]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 2,
            'data' => ['2.1', 'd2_2'],
        },
        {
            'data' => ['1.1', 'd1_3'],
            'id'   => 1,
        },
        {
            'id'   => 1,
            'data' => ['1', 'd1_2'],
        },
        {
            'data' => ['1.1', 'd1_2'],
            'id'   => 1,
        },
    ],
    'data.[1] desc, data.[0] asc'
);

$q->order_by(['data.[0]', 1], ['data.[1]', 0]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 2,
            'data' => ['2.1', 'd2_2'],
        },
        {
            'data' => ['1.1', 'd1_2'],
            'id'   => 1,
        },
        {
            'data' => ['1.1', 'd1_3'],
            'id'   => 1,
        },
        {
            'id'   => 1,
            'data' => ['1', 'd1_2'],
        },
    ],
    'data.k1 desc, data.k2 asc'
);

$q->order_by(['id', 0], ['data.[0]', 1], ['data.[1]', 1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => ['1.1', 'd1_3'],
        },
        {
            'id'   => 1,
            'data' => ['1.1', 'd1_2'],
        },
        {
            'data' => ['1', 'd1_2'],
            'id'   => 1,
        },
        {
            'data' => ['2.1', 'd2_2'],
            'id'   => 2,
        },
    ],
    'id asc, data.[0] desc, data.[1] desc'
);

$q->order_by(['id', 0], ['data.[1]', 1], ['data.[0]', 1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => ['1.1', 'd1_3'],
        },
        {
            'id'   => 1,
            'data' => ['1.1', 'd1_2'],
        },
        {
            'data' => ['1', 'd1_2'],
            'id'   => 1,
        },
        {
            'data' => ['2.1', 'd2_2'],
            'id'   => 2,
        },
    ],
    'id asc, data.[0] desc, data.[1] desc'
);

$q->group_by(qw(id data.[0]));

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => ['1.1', 'd1_2'],
        },
        {
            'data' => ['1', 'd1_2'],
            'id'   => 1,
        },
        {
            'data' => ['2.1', 'd2_2'],
            'id'   => 2,
        },
    ],
    'group by id, data.[0]'
);

$q->group_by();
$q->filter(['data.[0]' => '=' => \1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'data' => ['1', 'd1_2'],
            'id'   => 1,
        },
    ],
    'filter data.[0] = 1'
);

$q->fields([qw(data.[1])]);

cmp_deeply($q->get_all(), [{'data.[1]' => 'd1_2'}]);

done_testing();
