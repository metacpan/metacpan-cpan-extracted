#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

### INDEX TEMPLATES ###
ok $es->create_index_template(
    name     => 'mytemplate',
    template => 'test*',
    settings => { number_of_shards => 1 },
    order    => 2,
    warmers  => {
        warmer_1 => {
            types  => [ 'type_1', 'type_2' ],
            source => {
                queryb  => { foo => 1 },
                filterb => { foo => 1 },
                facets  => {
                    bar => {
                        filterb       => { bar => 1 },
                        facet_filterb => { bar => 2 }
                    }
                },

            },
        }
    }
    ),
    'index template - create';

$es->create_index( index => 'test1' );
$es->create_index( index => 'std1' );

$r = $es->cluster_state->{metadata}{indices};

is $r->{test1}{settings}{'index.number_of_shards'}, 1,
    ' - index 1 has 1 shard';
is $r->{std1}{settings}{'index.number_of_shards'}, 5,
    ' - index 2 has 5 shards';

SKIP: {
    skip "Warmers only supported in 0.20", 1
        if $es_version lt '0.20';

    is_deeply $es->warmer,
        {
        "test1" => {
            "warmers" => {
                "warmer_1" => {
                    "source" => {
                        "filter" => { "term"  => { "foo" => 1 } },
                        "query"  => { "match" => { "foo" => 1 } },
                        "facets" => {
                            "bar" => {
                                "filter" => { "term" => { "bar" => 1 } },
                                "facet_filter" => { "term" => { "bar" => 2 } }
                            }
                        }
                    },
                    "types" => [ "type_1", "type_2" ],
                }
            }
        }
        },
        ' - warmer created';
}

$es->delete_index( index => 'test1' );
$es->delete_index( index => 'std1' );

is $es->index_template( name => 'mytemplate' )
    ->{mytemplate}{settings}{'index.number_of_shards'}, 1,
    ' - template retrieved';

ok $es->delete_index_template( name => 'mytemplate' )->{ok},
    'Delete template';

throws_ok { $es->index_template( name => 'mytemplate' ) } qr/Missing/,
    ' - template deleted';

throws_ok { $es->delete_index_template( name => 'mytemplate' ) } qr/Missing/,
    ' - template missing';
ok !$es->delete_index_template( name => 'mytemplate', ignore_missing => 1 ),
    ' - ignore missing';
1
