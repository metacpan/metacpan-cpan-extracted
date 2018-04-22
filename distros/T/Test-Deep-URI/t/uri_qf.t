# vim: set ft=perl
use strict;
use warnings;

use Test::More tests => 5;
use Test::Warnings;
use Test::Deep;
use Test::Deep::URI;

cmp_deeply(
    'http://rightaboutnow/?token=hola&random=whatever',
    uri_qf('http://rightaboutnow/', ignore()),
    'You can ignore the query_form entirely');

cmp_deeply(
    'http://rightaboutnow/test2?token=hola&random=whatever2',
    uri_qf('//rightaboutnow/test2', superhashof({ token => 'hola' })),
    'You can check specific query parameters');

cmp_deeply(
    'http://rightaboutnow/test2?token=hola&random=whatever2',
    uri_qf('//rightaboutnow/test2', { token => 'hola', random => ignore() }),
    'You can ignore specific query parameters');

cmp_deeply(
    'http://rightaboutnow/zug?foo=1&foo=2&foo=3',
    uri_qf('/zug', { foo => [1,2,3] }),
    'Repeated parameters are in list format');

note 'DONE!';
