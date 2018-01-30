#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $q = QBit::QueryData->new(
    data => [
        {id => 1, caption => 'caption 1', message => 'message 1',},
        {id => 2, caption => 'caption 2', message => 'message 2',},
    ]
);

$q->fields({key => 'id', title => 'caption', message => ''});

cmp_deeply($q->get_fields(), {'key' => 'id', 'title' => 'caption', 'message' => ''}, 'get_fields');

cmp_deeply(
    $q->get_all(),
    [
        {'key' => 1, 'title' => 'caption 1', 'message' => 'message 1',},
        {'key' => 2, 'title' => 'caption 2', 'message' => 'message 2',},
    ],
    'get_all'
);

done_testing();
