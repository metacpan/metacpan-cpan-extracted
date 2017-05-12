#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

### CREATE INDEX ###
ok $es->create_index( index => 'es_test_1' )->{ok}, 'Created index';
throws_ok { $es->create_index( index => 'es_test_1' ) } qr/[Aa]lready exists/,
    ' - second create fails';

throws_ok { $es->create_index( index => [ 'es_test_1', 'es_test_2' ] ) }
qr/single value/,
    ' - multiple indices fails';

ok $r = $es->create_index(
    index => 'es_test_2',

    settings => {

        number_of_shards   => 3,
        number_of_replicas => 1,

        analysis => {
            filter => {
                my_filter => {
                    type      => 'stop',
                    stopwords => [ 'foo', 'bar' ]
                },
            },
            tokenizer => {
                my_tokenizer => {
                    type             => 'standard',
                    max_token_length => 900,
                }
            },
            analyzer => {
                my_analyzer => {
                    tokenizer => 'my_tokenizer',
                    filter    => [ 'standard', 'my_filter' ]
                }
            }
        }
    },

    mappings => {
        type_1 => {
            _source    => { enabled => 0 },
            properties => {
                match => { type => 'string', analyzer => 'my_analyzer' },
                num   => { type => 'integer' }
            }
        }
    },
    warmers => {
        warmer_1 => {
            source => {
                queryb  => { foo => 1 },
                filterb => { foo => 1 },
                facets  => {
                    bar => {
                        filterb       => { bar => 1 },
                        facet_filterb => { foo => 2 }
                    }
                }
            },
            types => ['type_1'],
        }
    },
)->{ok}, ' - with settings, mappings and warmers';

wait_for_es();

$r = $es->cluster_state->{metadata}{indices}{es_test_2};

is $r->{settings}{'index.number_of_shards'}, 3, ' - number of shards stored';
is $r->{settings}{'index.analysis.filter.my_filter.stopwords.0'}, 'foo',
    ' - analyzer stored';
is $r->{mappings}{type_1}{_source}{enabled}, 0, ' - mappings stored';
is $r->{mappings}{type_1}{properties}{match}{analyzer}, 'my_analyzer',
    ' - analyzer mapped';

SKIP: {
    skip "Warmers only supported in 0.20", 2
        if $es_version lt '0.20';
    ok $r= $es->warmer( index => 'es_test_2' )->{es_test_2},
        ' - warmer created';
    is_deeply $r,
        {
        "warmers" => {
            "warmer_1" => {
                "source" => {
                    "filter" => { "term"  => { "foo" => 1 } },
                    "query"  => { "match" => { "foo" => 1 } },
                    "facets" => {
                        "bar" => {
                            "filter"       => { "term" => { "bar" => 1 } },
                            "facet_filter" => { "term" => { "foo" => 2 } }
                        }
                    }
                },
                "types" => ["type_1"]
            },
        },
        },
        ' - warmer passed through searchbuilder';

}
1
