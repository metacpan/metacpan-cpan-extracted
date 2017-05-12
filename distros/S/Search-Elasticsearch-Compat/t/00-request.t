#!perl

use Test::More 0.96;
use Test::Exception;
use lib 't/request_tests';

our $instances = 3;
our $es_version;

BEGIN {
    unless ( $ENV{ES_HOME} ) {
        plan 'skip_all' => 'ES_HOME not set';
        exit;
    }

    use_ok 'Search::Elasticsearch::Compat'     || print "Bail out!";
    use_ok 'Search::Elasticsearch::TestServer' || print "Bail out!";
}

my $test_server = Search::Elasticsearch::TestServer->new(
    instances => 3,
    es_home   => $ENV{ES_HOME}
);
my $nodes = $test_server->start;

our $es = Search::Elasticsearch::Compat->new(
    servers => $nodes,

    #[ 'localhost:9200', 'localhost:9201', 'localhost:9202' ],
    trace_calls => 'log'
);

$es_version = $es->current_server_version;

run_test_suite();

note "Shutting down servers";

$test_server->shutdown();

done_testing;

#===================================
sub run_test_suite {
#===================================

    ok $es, 'Connected to an ES cluster';

    wait_for_es();

    create_indices();
    run_tests( qw(
            version
            cluster_state
            cluster_health
            cluster_reroute
            cluster_settings
            nodes
            module_options
            )
    );

    drop_indices();
    run_tests( qw(
            create_index
            index_status
            index_segments
            update_settings
            index_admin
            analyze
            index_alias
            open_close_index
            delete_index
            )
    );

    drop_indices();
    run_tests( qw(
            index_templates
            rivers
            )
    );

    create_indices();
    run_tests( qw(
            index_and_create
            get
            exists
            delete
            update
            uri_escape
            )
    );

    drop_indices();
    run_tests('mapping');

    drop_indices();
    create_indices();
    run_tests( qw(
            type_exists
            warmers
            )
    );

    drop_indices();
    run_tests( qw(
            bulk
            bulk_errors
            as_json
            use_index_type
            )
    );

    create_indices();
    index_test_docs();

    run_tests( qw(
            mget
            search_query
            search_from_size
            search_types
            search_facets
            search_explain
            search_sort
            search_fields
            search_partial_fields
            search_script_fields
            search_highlight
            search_scroll
            search_indices_boost
            search_custom_score
            searchqs
            msearch
            count
            more_like_this
            search_highlight
            delete_by_query
            validate_query
            explain
            )
    );

    run_tests('search_builder');

    create_indices();
    index_test_docs();
    run_tests('reindex');

}

#===================================
sub run_tests {
#===================================
    while ( my $module = shift ) {
        my $str = "Testing: $module";
        note '';
        note $str;
        note '-' x length $str;
        do "$module.pl" or die $!;

    }
}

#===================================
sub create_indices {
#===================================

    note("Creating indices");

    drop_indices();

    my %properties = (
        properties => {
            text => { type => 'string' },
            num  => { type => 'integer', store => 'yes' },
            date => { type => 'date', format => 'yyyy-MM-dd HH:mm:ss' }
        }
    );

    for ( 1 .. 2 ) {
        $es->create_index(
            index    => 'es_test_' . $_,
            mappings => {
                type_1 => \%properties,
                type_2 => \%properties,

            }
        );
    }

    wait_for_es();
}

#===================================
sub index_test_docs {
#===================================

    note("Loading test docs");

    my @rows = map {
        {
            index    => "es_test_" . $_->[0],
                type => "type_" . $_->[1],
                id   => $_->[2],
                data => {
                text => $_->[3],
                num  => $_->[2] + 1,
                date => $_->[4] . ' 00:00:00'
                }
        }
        } (
        [ 1, 1, 1,  'foo',         '2010-04-02' ],
        [ 1, 2, 2,  'foo',         '2010-04-03' ],
        [ 2, 1, 3,  'foo',         '2010-04-04' ],
        [ 2, 2, 4,  'foo',         '2010-04-05' ],
        [ 1, 1, 5,  'foo bar',     '2010-04-06' ],
        [ 1, 2, 6,  'foo bar',     '2010-04-07' ],
        [ 2, 1, 7,  'foo bar',     '2010-04-08' ],
        [ 2, 2, 8,  'foo bar',     '2010-04-09' ],
        [ 1, 1, 9,  'foo bar baz', '2010-04-10' ],
        [ 1, 2, 10, 'foo bar baz', '2010-04-11' ],
        [ 2, 1, 11, 'foo bar baz', '2010-04-12' ],
        [ 2, 2, 12, 'foo bar baz', '2010-04-13' ],
        [ 1, 1, 13, 'bar baz',     '2010-04-14' ],
        [ 1, 2, 14, 'bar baz',     '2010-04-15' ],
        [ 2, 1, 15, 'bar baz',     '2010-04-16' ],
        [ 2, 2, 16, 'bar baz',     '2010-04-17' ],
        [ 1, 1, 17, 'baz',         '2010-04-18' ],
        [ 1, 2, 18, 'baz',         '2010-04-19' ],
        [ 2, 1, 19, 'baz',         '2010-04-20' ],
        [ 2, 2, 20, 'baz',         '2010-04-21' ],
        [ 1, 1, 21, 'bar',         '2010-04-22' ],
        [ 1, 2, 22, 'bar',         '2010-04-23' ],
        [ 2, 1, 23, 'bar',         '2010-04-24' ],
        [ 2, 2, 24, 'bar',         '2010-04-25' ],
        [ 1, 1, 25, 'foo baz',     '2010-04-26' ],
        [ 1, 2, 26, 'foo baz',     '2010-04-27' ],
        [ 2, 1, 27, 'foo baz',     '2010-04-28' ],
        [ 2, 2, 28, 'foo baz',     '2010-04-29' ],
        [ 1, 1, 30, 'foo',         '2010-05-01' ],

        );

    $es->bulk_index( docs => \@rows, refresh => 1 );

}

#===================================
sub parent_child_docs {
#===================================
    note("Preparing indices for parent/child tests");

    drop_indices();

    $es->create_index(
        index    => 'es_test_1',
        mappings => {
            myparent => { properties => { text => { type => 'string' } } },
            mychild  => {
                _parent    => { type => 'myparent' },
                properties => { text => { type => 'string' } }

            }
        }
    );

    wait_for_es();

    $es->bulk_index(
        {   index => 'es_test_1',
            type  => 'myparent',
            id    => 1,
            data  => { text => 'john smith' }
        },
        {   index => 'es_test_1',
            type  => 'myparent',
            id    => 2,
            data  => { text => 'mary smith' }
        },
        {   index   => 'es_test_1',
            type    => 'mychild',
            id      => 3,
            _parent => 1,
            data    => { text => 'abigail' }
        },
        {   index   => 'es_test_1',
            type    => 'mychild',
            id      => 4,
            _parent => 1,
            data    => { text => 'percival' }
        },
        {   index   => 'es_test_1',
            type    => 'mychild',
            id      => 5,
            _parent => 2,
            data    => { text => 'abigail' }
        },
        {   index   => 'es_test_1',
            type    => 'mychild',
            id      => 6,
            _parent => 2,
            data    => { text => 'oscar' }
        },
    );
    wait_for_es();
}

#===================================
sub drop_indices {
#===================================
    eval {
        $es->delete_index( index => 'es_test_1' );
        $es->delete_index( index => 'es_test_2' );
        wait_for_es();
    };

}

#===================================
sub wait_for_es {
#===================================
    sleep $_[0] if $_[0];
    $es->cluster_health(
        wait_for_status => 'green',
        timeout         => '30s'
    );
    $es->refresh_index();
}

