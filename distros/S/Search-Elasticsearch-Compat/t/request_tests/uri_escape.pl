#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $es->index(
    index => 'es_test_1',
    type  => 'type/1',
    id    => '1/2',
    data  => { text => 'foo' }
    ),
    'Index with slashes';

ok $r = $es->get(
    index => 'es_test_1',
    type  => 'type/1',
    id    => '1/2'
    ),
    'Get with slashes';

is $r->{_type}, 'type/1', '- type ok';
is $r->{_id},   '1/2',    '- id ok';

1
