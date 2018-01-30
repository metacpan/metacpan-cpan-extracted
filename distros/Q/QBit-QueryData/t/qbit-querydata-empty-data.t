#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $q = QBit::QueryData->new();

cmp_deeply($q->get_all(), [], 'get_all');

$q = QBit::QueryData->new(data => undef);

cmp_deeply($q->get_all(), [], 'get_all');

my $data = [];

$q = QBit::QueryData->new(data => $data);

$q->fields([qw(id field)]);

$q->filter(['AND', [['id', 'IN', \[1, 2]], ['field', 'LIKE', \'a']]]);

$q->order_by(qw(id field));

cmp_deeply($q->get_fields(), {'id' => '', 'field' => ''}, 'get_fields');

ok($q->{'__FILTER__'}, '__FILTER__');

ok($q->{'__ORDER_BY__'}, '__ORDER_BY__');

cmp_deeply($q->get_all(), [], 'get_all');

$data = [{id => 2, field => 'bca'}, {id => 1, field => 'acb'}, {id => 2, field => 'abc'},];

$q->data($data);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'    => 1,
            'field' => 'acb'
        },
        {
            'field' => 'abc',
            'id'    => 2
        },
        {
            'field' => 'bca',
            'id'    => 2
        }
    ],
    'get_all'
);

done_testing();
