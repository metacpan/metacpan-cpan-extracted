#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [];

my $q = QBit::QueryData->new(data => []);

$q->order_by(qw(id field));

is($q->get_fields(), undef, 'get_fields');

cmp_deeply($q->get_all(), [], 'get_all');

done_testing();
