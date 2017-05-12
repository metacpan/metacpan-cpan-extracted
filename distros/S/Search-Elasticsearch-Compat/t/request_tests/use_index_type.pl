#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

is $es->use_index('es_test_3'), 'es_test_3', 'use index';
is $es->use_type('type_3'),     'type_3',    'use type';

ok $r = $es->index( id => 1, data => { text => 'foo' } ),
    'index with defaults';
is $r->{_index}, 'es_test_3', ' - index ok';
is $r->{_type},  'type_3',    ' - type ok';

ok $r= $es->bulk_index( [ { id => 2, data => { text => 'foo' } } ] )
    ->{results}[0]{index}, 'bulk with defaults';
is $r->{_index}, 'es_test_3', ' - index ok';
is $r->{_type},  'type_3',    ' - type ok';

wait_for_es();

is $es->count( match_all => {} )->{count}, 2, ' - count ok';

$es->delete_index();

$es->use_index(undef);
$es->use_type(undef);

wait_for_es();

