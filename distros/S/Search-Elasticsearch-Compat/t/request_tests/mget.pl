#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $r= $es->mget(
    index => 'es_test_1',
    type  => 'type_1',
    ids   => [ 1, 2, 3, 4, 5 ]
    ),
    'mget';
is scalar @$r, 5, ' - 5 results';
is $r->[0]{_id},    1, ' - first id ok';
is $r->[3]{exists}, 0, "id 3 doesn't exist";

ok $r= $es->mget(
    index          => 'es_test_1',
    type           => 'type_1',
    ids            => [ 1, 2, 3, 4, 5 ],
    filter_missing => 1
    ),
    ' - filter missing';
is scalar @$r, 2, ' - missing filtered';

ok $r= $es->mget(
    docs => [
        { _index => 'es_test_1', _type => 'type_1', _id => 1 },
        { _index => 'es_test_1', _type => 'type_1', _id => 5 }
    ]
    ),
    ' - docs';

ok $r= $es->mget(
    fields => [ 'num', 'date' ],
    docs   => [
        { _index => 'es_test_1', _type => 'type_1', _id => 1 },
        {   _index => 'es_test_1',
            _type  => 'type_1',
            _id    => 5,
            fields => ['text']
        }
    ]
    ),
    ' - fields';

ok keys %{ $r->[0]{fields} } == 2
    && $r->[0]{fields}{num}
    && $r->[0]{fields}{date}, ' - default';

ok keys %{ $r->[1]{fields} } == 1 && $r->[1]{fields}{text}, ' - specific';

is_deeply $r = $es->mget( docs => [] ), [], ' - no docs';
is $r = $es->mget( docs => [], as_json => 1 ), "[]", ' - no docs json';

throws_ok { $es->mget( type => 'foo' ) } qr/Cannot specify a type for mget/,
    ' - type without index';
throws_ok { $es->mget( ids => [] ) } qr/Use of the ids param with mget/,
    ' - ids no index';
throws_ok { $es->mget( index => 'es_type_1', ids => [], docs => [] ) }
qr/Cannot specify both ids and docs/, ' - ids and docs';

1
