#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

no warnings 'redefine';

$es->create_index( index => 'es_test_1' );
wait_for_es();

ok $es->put_mapping(
    index   => 'es_test_1',
    type    => 'type_1',
    mapping => {
        _all      => { enabled  => 0 },
        _analyzer => { path     => 'my_analyzer' },
        _boost    => { name     => 'my_boost', null_value => 1 },
        _id       => { store    => 'yes' },
        _index    => { store    => 'yes' },
        _meta     => { foo      => 'bar' },
        _source   => { compress => 1 },
        dynamic    => 0,
        properties => {
            text => { type => 'string' },
            num  => { type => 'integer' },
        }
    }
    ),
    'Put mapping';

throws_ok {
    $es->put_mapping(
        index   => 'es_test_1',
        type    => 'type_1',
        mapping => {
            properties =>
                { num => { type => 'string' }, date => { type => 'date' } }

        }
    );
}
qr /MergeMappingException/, ' - conflicted mapping';

ok !$es->mapping( index => 'es_test_1', type => 'type_1' )
    ->{type_1}{properties}{date}, ' - valid field not merged';

ok $es->put_mapping(
    index            => 'es_test_1',
    type             => 'type_1',
    ignore_conflicts => 1,
    mapping          => {
        properties =>
            { num => { type => 'string' }, date => { type => 'date' } }
    }
    ),
    ' - ignore conflict';

ok $es->mapping( index => 'es_test_1', type => 'type_1' )
    ->{type_1}{properties}{date}, ' - valid field merged';

is test_dynamic(1), 1, 'Dynamic mapping enabled';
is test_dynamic(0), 0, ' - disabled';
throws_ok { test_dynamic('strict') } qr/StrictDynamicMappingException/,
    ' - strict';

ok $es->delete_mapping( index => 'es_test_1', type => 'type_1' )->{ok},
    'Delete mapping';

ok !$es->delete_mapping(
    index          => 'es_test_1',
    type           => 'type_1',
    ignore_missing => 1
    ),
    ' - ignores missing';

ok $es->put_mapping(
    index     => 'es_test_1',
    type      => 'type_1',
    _all      => { enabled => 0 },
    _analyzer => { path => 'my_analyzer' },
    _boost    => { name => 'my_boost', null_value => 1 },
    _id        => { store    => 'yes' },
    _index     => { store    => 'yes' },
    _meta      => { foo      => 'bar' },
    _source    => { compress => 1 },
    dynamic    => 0,
    properties => {
        text => { type => 'string' },
        num  => { type => 'integer' },
    }
    ),
    'Put mapping (depr)';

throws_ok {
    $es->put_mapping(
        index => 'es_test_1',
        type  => 'type_1',
        properties =>
            { num => { type => 'string' }, date => { type => 'date' } }
    );
}
qr /MergeMappingException/, ' - conflicted mapping (depr)';

ok !$es->mapping( index => 'es_test_1', type => 'type_1' )
    ->{type_1}{properties}{date}, ' - valid field not merged (depr)';

ok $es->put_mapping(
    index            => 'es_test_1',
    type             => 'type_1',
    ignore_conflicts => 1,
    properties => { num => { type => 'string' }, date => { type => 'date' } }
    ),
    ' - ignore conflict (depr)';

ok $es->mapping( index => 'es_test_1', type => 'type_1' )
    ->{type_1}{properties}{date}, ' - valid field merged (depr)';

is test_dynamic_depr(1), 1, 'Dynamic mapping enabled (depr)';
is test_dynamic_depr(0), 0, ' - disabled (depr)';
throws_ok { test_dynamic('strict') } qr/StrictDynamicMappingException/,
    ' - strict (depr)';

ok $es->delete_mapping( index => 'es_test_1', type => 'type_1' )->{ok},
    'Delete mapping (depr)';

ok !$es->delete_mapping(
    index          => 'es_test_1',
    type           => 'type_1',
    ignore_missing => 1
    ),
    ' - ignores missing (depr)';

#===================================
sub test_dynamic {
#===================================
    my $dynamic = shift;
    $es->delete_mapping( index => 'es_test_1', type => 'type_1' );
    $es->put_mapping(
        index   => 'es_test_1',
        type    => 'type_1',
        mapping => {
            dynamic    => $dynamic,
            properties => { text => { type => 'string' } },
        }
    );
    $es->index(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        data    => { text => 'foo', num => 123 },
        refresh => 1
    );
    return $es->search(
        index => 'es_test_1',
        query => { field => { num => 123 } }
    )->{hits}{total};

}

#===================================
sub test_dynamic_depr {
#===================================
    my $dynamic = shift;
    $es->delete_mapping( index => 'es_test_1', type => 'type_1' );
    $es->put_mapping(
        index      => 'es_test_1',
        type       => 'type_1',
        dynamic    => $dynamic,
        properties => { text => { type => 'string' } },
    );
    $es->index(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        data    => { text => 'foo', num => 123 },
        refresh => 1
    );
    return $es->search(
        index => 'es_test_1',
        query => { field => { num => 123 } }
    )->{hits}{total};

}

1
