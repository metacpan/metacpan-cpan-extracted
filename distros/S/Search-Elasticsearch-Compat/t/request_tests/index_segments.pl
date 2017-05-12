#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### INDEX SEGMENTS ###

ok $r= $es->index_segments()->{indices}, 'Index segments - all';
ok $r->{es_test_1}, ' - index 1';
ok $r->{es_test_2}, ' - index 2';

ok $r= $es->index_segments( index => 'es_test_1' )->{indices},
    'Index segments - index 1';
ok $r->{es_test_1}, ' - index 1';
ok !$r->{es_test_2}, ' - index 2';

ok $r
    = $es->index_segments( index => [ 'es_test_1', 'es_test_2' ] )->{indices},
    'Index segments - index 1 & 2';
ok $r->{es_test_1}, ' - index 1';
ok $r->{es_test_2}, ' - index 2';

throws_ok { $es->index_segments( index => 'foo' ) } qr/Missing/,
    ' - index missing';

1;
