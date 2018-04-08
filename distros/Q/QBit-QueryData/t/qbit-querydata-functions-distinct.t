#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [
    {id => 1, label => 'label 1', num => 1,},
    {id => 2, label => 'label 1', num => 1,},
    {id => 3, label => 'label 1', num => 2,},
    {id => 4, label => 'label 2', num => 3,},
    {id => 5, label => 'label 3', num => 4,},
    {id => 5, label => 'label 3', num => 4,},
];

my $q = QBit::QueryData->new(data => $data);

$q->fields({label => {DISTINCT => ['label']}});
$q->filter(['num', '=', \[2, 4]]);

cmp_deeply($q->get_all(), [{'label' => 'label 1'}, {'label' => 'label 3'}], 'distinct as function');

$q->fields([qw(label)]);

cmp_deeply(
    $q->get_all(),
    [{'label' => 'label 1'}, {'label' => 'label 3'}, {'label' => 'label 3'}],
    'after fields changed distinct reset'
);

$q->fields({id => '', label => {DISTINCT => ['label']}});
$q->filter();

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'    => 1,
            'label' => 'label 1'
        },
        {
            'label' => 'label 1',
            'id'    => 2
        },
        {
            'id'    => 3,
            'label' => 'label 1'
        },
        {
            'label' => 'label 2',
            'id'    => 4
        },
        {
            'label' => 'label 3',
            'id'    => 5
        }
    ],
    'distinct as function with other fields'
);

$q->fields({label => {DISTINCT => ['label']}, sum_num => {SUM => ['num']}});

cmp_deeply(
    $q->get_all(),
    [{label => 'label 1', sum_num => 15}],
    'distinct without groupping but has aggregation function'
);

done_testing();
