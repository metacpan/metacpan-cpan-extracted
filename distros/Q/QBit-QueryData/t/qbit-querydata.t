#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [
    {
        id      => undef,
        caption => 'caption 6',
    },
    {
        id      => 1,
        caption => 'caption 1',
    },
    {
        id      => 8,
        caption => 'caption',
    },
    {
        id      => 13,
        caption => 'Caption 13',
    },
    {
        id      => 2,
        caption => 'caption 2',
    },
    {
        id      => 5,
        caption => undef,
    },
    {
        id      => 7,
        caption => 'caption',
    },
    {
        id      => 7,
        caption => 'caption',
    },
];

my $q = QBit::QueryData->new(
    data       => $data,
    fields     => [qw(caption)],
    filter     => {caption => 'caption 1'},
    definition => {caption => {type => 'string'}}
);

cmp_deeply($q->get_fields, ['caption'], 'get_fields');

cmp_deeply($q->definition(), {caption => {type => 'string'}}, 'definition');

cmp_deeply($q->get_all(), [{'caption' => 'caption 1'}], 'default filter');

cmp_deeply($q->get_all(), [{'caption' => 'caption 1'}], 'filter is not changed');

$q->fields([qw(id caption)]);

cmp_deeply($q->get_fields, ['id', 'caption'], 'changed fields');

$q->fields([]);

cmp_deeply($q->get_fields, ['caption'], 'default fields');

$q->fields();

cmp_deeply($q->get_fields, ['caption', 'id'], 'all fields');

$q->filter(['OR', [['id' => '=' => \2], ['caption' => 'NOT LIKE' => \'caption']]]);

cmp_deeply($q->get_all(),
    [{'id' => 13, 'caption' => 'Caption 13'}, {'id' => 2, 'caption' => 'caption 2'}, {'id' => 5, 'caption' => undef}],
    'new filter');

$q->filter();

cmp_deeply($q->get_all(), $data, 'empty filter');

{
    no warnings;

    $q->order_by(qw(caption id));

    cmp_deeply($q->get_all(), [sort {$a->{'caption'} cmp $b->{'caption'} || $a->{'id'} cmp $b->{'id'}} @$data],
        'sorting');

    $q->definition({id => {type => 'number'}, caption => {type => 'string'}});

    my $err = FALSE;
    try {
        $q->filter({id => 'die("aaa")'});
    }
    catch {
        $err = TRUE;
        is(shift->message, gettext('%s - not number', 'die("aaa")'), 'corrected message');
    }
    finally {
        ok($err, 'catch error');
    };

    $q->order_by(['caption', 1], ['id', 0]);

    cmp_deeply(
        $q->get_all(),
        [sort {$b->{'caption'} cmp $a->{'caption'} || $a->{'id'} <=> $b->{'id'}} @$data],
        'sorting with order'
    );
}

$q->order_by();

cmp_deeply($q->get_all(), $data, 'empty order_by');

$q->filter({caption => ['caption', undef]});

cmp_deeply(
    $q->get_all(),
    [grep {!defined($_->{'caption'}) || $_->{'caption'} eq 'caption'} @$data],
    'filter as hash with undef'
);

$q->distinct();

cmp_deeply(
    $q->get_all(),
    [
        {
            'caption' => 'caption',
            'id'      => 8
        },
        {
            'id'      => 5,
            'caption' => undef
        },
        {
            'id'      => 7,
            'caption' => 'caption'
        }
    ],
    'distinct'
);

$q->filter(['id' => 'IN' => \[5, 8, undef]]);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'      => undef,
            'caption' => 'caption 6',
        },
        {
            'caption' => 'caption',
            'id'      => 8
        },
        {
            'id'      => 5,
            'caption' => undef
        },
    ],
    'filter as array with undef'
);

$q->limit(0, 1);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'      => undef,
            'caption' => 'caption 6',
        },
    ],
    'limit(0, 1)'
);

$q->limit(0, 2);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'      => undef,
            'caption' => 'caption 6',
        },
        {
            'caption' => 'caption',
            'id'      => 8
        },
    ],
    'limit(0, 2)'
);

$q->limit(1, 2);

cmp_deeply(
    $q->get_all(),
    [
        {
            'caption' => 'caption',
            'id'      => 8
        },
        {
            'id'      => 5,
            'caption' => undef
        },
    ],
    'limit(1, 2)'
);

$q->limit(4, 1);

cmp_deeply($q->get_all(), [], 'limit(4, 1)');

$q->limit(2, 3);

cmp_deeply(
    $q->get_all(),
    [
        {
            'id'      => 5,
            'caption' => undef
        },
    ],
    'limit(1, 3)'
);

done_testing();
