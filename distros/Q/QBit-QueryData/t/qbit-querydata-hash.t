#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [
    {
        id   => 1,
        data => {
            k1 => 1.1,
            k2 => 'd1_2',
        },
    },
    {
        id   => 2,
        data => {
            k1 => 2.1,
            k2 => 'd2_2',
        },
    },
    {
        id   => 1,
        data => {
            k1 => 1.1,
            k2 => 'd1_3',
        },
    },
    {
        id   => 1,
        data => {
            k1 => 1,
            k2 => 'd1_2',
        },
    },
];

my $q = QBit::QueryData->new(
    data       => $data,
    fields     => [qw(id data)],
    definition => {
        'id'      => {type => 'number'},
        'data.k1' => {type => 'number'},
        'data.k2' => {type => 'string'},
    }
);

$q->order_by(['data.k2', 1], ['data.k1', 0]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 2,
            'data' => {
                'k2' => 'd2_2',
                'k1' => '2.1',
            },
        },
        {
            'data' => {
                'k2' => 'd1_3',
                'k1' => '1.1',
            },
            'id' => 1,
        },
        {
            'id'   => 1,
            'data' => {
                'k2' => 'd1_2',
                'k1' => 1,
            },
        },
        {
            'data' => {
                'k2' => 'd1_2',
                'k1' => '1.1',
            },
            'id' => 1,
        },
    ],
    'data.k2 desc, data.k1 asc'
);

$q->order_by(['data.k1', 1], ['data.k2', 0]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 2,
            'data' => {
                'k2' => 'd2_2',
                'k1' => '2.1',
            },
        },
        {
            'data' => {
                'k2' => 'd1_2',
                'k1' => '1.1',
            },
            'id' => 1,
        },
        {
            'data' => {
                'k2' => 'd1_3',
                'k1' => '1.1',
            },
            'id' => 1,
        },
        {
            'id'   => 1,
            'data' => {
                'k2' => 'd1_2',
                'k1' => 1,
            },
        },
    ],
    'data.k1 desc, data.k2 asc'
);

$q->order_by(['id', 0], ['data.k1', 1], ['data.k2', 1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => {
                'k2' => 'd1_3',
                'k1' => '1.1',
            },
        },
        {
            'id'   => 1,
            'data' => {
                'k2' => 'd1_2',
                'k1' => '1.1',
            },
        },
        {
            'data' => {
                'k1' => 1,
                'k2' => 'd1_2',
            },
            'id' => 1,
        },
        {
            'data' => {
                'k2' => 'd2_2',
                'k1' => '2.1',
            },
            'id' => 2,
        },
    ],
    'id asc, data.k1 desc, data.k2 desc'
);

$q->order_by(['id', 0], ['data.k2', 1], ['data.k1', 1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => {
                'k1' => '1.1',
                'k2' => 'd1_3',
            },
        },
        {
            'id'   => 1,
            'data' => {
                'k1' => '1.1',
                'k2' => 'd1_2',
            },
        },
        {
            'data' => {
                'k2' => 'd1_2',
                'k1' => 1,
            },
            'id' => 1,
        },
        {
            'data' => {
                'k1' => '2.1',
                'k2' => 'd2_2',
            },
            'id' => 2,
        },
    ],
    'id asc, data.k1 desc, data.k2 desc'
);

$q->group_by(qw(id data.k1));

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'   => 1,
            'data' => {
                'k1' => '1.1',
                'k2' => 'd1_2',
            },
        },
        {
            'data' => {
                'k2' => 'd1_2',
                'k1' => 1,
            },
            'id' => 1,
        },
        {
            'data' => {
                'k1' => '2.1',
                'k2' => 'd2_2',
            },
            'id' => 2,
        },
    ],
    'group by id, data.k1'
);

$q->group_by();
$q->filter(['data.k1' => '=' => \1]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'data' => {
                'k2' => 'd1_2',
                'k1' => 1
            },
            'id' => 1
        },
    ],
    'filter data.k1 = 1'
);

$q->fields([qw(data.k2)]);

cmp_deeply($q->get_all(), [{'data.k2' => 'd1_2'}]);

done_testing();
