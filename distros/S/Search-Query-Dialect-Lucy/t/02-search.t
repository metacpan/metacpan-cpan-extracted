#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw( dump );
use File::Temp qw( tempdir );
my $invindex = tempdir( CLEANUP => 1 );

use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Search::IndexSearcher;

my $schema     = Lucy::Plan::Schema->new;
my $stopfilter = Lucy::Analysis::SnowballStopFilter->new( language => 'en', );
my $stemmer    = Lucy::Analysis::SnowballStemmer->new( language => 'en' );
my $case_folder = Lucy::Analysis::CaseFolder->new;
my $tokenizer   = Lucy::Analysis::RegexTokenizer->new;
my $analyzer    = Lucy::Analysis::PolyAnalyzer->new(
    analyzers => [
        $case_folder,
        $tokenizer,

        # our existing tests have too many stopwords to refactor
        # but this is helpful when debugging related code in Dialect::Lucy

        #$stopfilter,

        $stemmer,
    ]
);
my $fulltext = Lucy::Plan::FullTextType->new(
    analyzer => $analyzer,
    sortable => 1,
);
$schema->spec_field( name => 'title',  type => $fulltext );
$schema->spec_field( name => 'color',  type => $fulltext );
$schema->spec_field( name => 'date',   type => $fulltext );
$schema->spec_field( name => 'option', type => $fulltext );

my $indexer = Lucy::Index::Indexer->new(
    index    => $invindex,
    schema   => $schema,
    create   => 1,
    truncate => 1,
);

use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields => {
            title  => { analyzer => $analyzer },
            color  => { analyzer => $analyzer },
            date   => { analyzer => $analyzer },
            option => { analyzer => $analyzer },
        },
        query_class_opts =>
            { default_field => [qw( title color date option )], },
        dialect        => 'Lucy',
        croak_on_error => 1,
        null_term      => 'NULL',
    ),
    "new parser"
);

ok( my $tree_able = $parser->parse("foo OR bar"), "parse for tree_able" );
ok( my $tree      = $tree_able->tree(),           "->tree" );
ok( my $native_tree = $tree_able->translate_to('Native'),
    "translate to Native dialect" );

my %docs = (
    'doc1' => {
        title  => 'i am doc1',
        color  => 'red blue orange',
        date   => '20100329',
        option => 'a',
    },
    'doc2' => {
        title  => 'i am doc2',
        color  => 'green yellow purple',
        date   => '20100301',
        option => 'b',
    },
    'doc3' => {
        title  => 'i am doc3',
        color  => 'brown black white',
        date   => '19720329',
        option => '',
    },
    'doc4' => {
        title  => 'i am doc4',
        color  => 'white',
        date   => '20100510',
        option => 'c',
    },
    'doc5' => {
        title  => 'unlike the others',
        color  => 'teal',
        date   => '19000101',
        option => 'd',
    },
);

# set up the index
for my $doc ( keys %docs ) {
    $indexer->add_doc( $docs{$doc} );
}

$indexer->commit;

my $searcher = Lucy::Search::IndexSearcher->new( index => $invindex, );

# search
my %queries = (
    'title:(i am)'                                       => 4,
    'title:("i am")'                                     => 4,
    'color:red'                                          => 1,
    'brown'                                              => 1,
    'date=(20100301..20100331)'                          => 2,
    'date!=(20100301..20100331)'                         => 3,
    '-date:(20100301..20100331)'                         => 3,
    'am AND (-date=(20100301..20100331))'                => 2,
    'am AND (date=(20100301..20100331))'                 => 2,
    'color:re*'                                          => 1,
    'color:re?'                                          => 1,
    'color:br?wn'                                        => 1,
    'color:*n'                                           => 2,
    'color!=red'                                         => 4,
    'not color=red and not title=doc2'                   => 3,
    '"i doc1"~2'                                         => 1,
    'option!=?*'                                         => 1,
    'NOT option:?*'                                      => 1,
    'option=NULL'                                        => 1,
    'NOT option!:NULL'                                   => 1,
    'option!=NULL'                                       => 4,
    'NOT option:NULL'                                    => 4,
    '(title=am) and (date!=20100301 and date!=20100329)' => 2,   # doc3 & doc4
    '(re* OR gree*) AND title=am'                        => 2,
    '(re* OR gree*)'                                     => 2,
    'not green'                                          => 4,
    'not green and title=doc3'                           => 1,
    '*oc*'                                               => 4,
    'green and not title=doc3'                           => 1,
    '((title=doc*) (NOT color=teal)) and (NOT option=c) and (date=(20100301..20100331))'
        => 2,
);

for my $str ( sort keys %queries ) {
    my $query = $parser->parse($str);

    #$query->debug(1);

    my $hits_expected = $queries{$str};
    if ( ref $hits_expected ) {
        $query->debug(1);
        $hits_expected = $hits_expected->[0];
    }

    #diag($query);
    my $lucy_query = $query->as_lucy_query();
    if ( !$lucy_query ) {
        diag("No lucy_query for $str");
        next;
    }
    my $hits = $searcher->hits(
        query      => $lucy_query,
        offset     => 0,
        num_wanted => 10,            # more than we have
    );

    is( $hits->total_hits, $hits_expected, "$str = $hits_expected" );

    if ( $hits->total_hits != $hits_expected or $query->debug ) {

        $query->debug(1);
        diag( 'str:' . $str );
        diag( 'query:' . $query );
        diag( dump($query) );

        diag( dump( $query->as_lucy_query ) );
        if ( $query->as_lucy_query->isa('Lucy::Search::NOTQuery') ) {
            diag( "negated_query: "
                    . dump( $query->as_lucy_query->get_negated_query ) );
        }
        diag( dump $query->as_lucy_query->dump );

    }
}

# exercise some as_lucy_query options
my $query = $parser->parse(qq/"orange red"~3/);
$query->ignore_order_in_proximity(1);

#$query->debug(1);
my $ks_query = $query->as_lucy_query();
my $hits
    = $searcher->hits( query => $ks_query, offset => 0, num_wanted => 5 );
is( $hits->total_hits, 1, "proximity order ignored" );
$query->ignore_order_in_proximity(0);
$ks_query = $query->as_lucy_query();
$hits = $searcher->hits( query => $ks_query, offset => 0, num_wanted => 5 );
is( $hits->total_hits, 0, "proximity order respected" );

# alternate way of doing wildcard searches: expand initial query
# from lexicon like Xapian does.
$parser->term_expander(
    sub {
        my ($term) = @_;
        return ($term) unless $term =~ m/[\*\?]/;

        # Assume here we have a cached list of terms,
        # either from a Lexicon or a db, etc.
        # In this case, we just return a hardcoded array
        # since we know what $term is

        return qw( doc1 doc2 doc3 doc4 );

    },
);

ok( my $wild_query = $parser->parse(qq/title=doc*/), "parse query" );
$ks_query = $wild_query->as_lucy_query();

#diag($wild_query);
#diag(dump $ks_query->dump);
#diag($ks_query->to_string);
$hits = $searcher->hits( query => $ks_query, offset => 0, num_wanted => 5 );
is( $hits->total_hits, 4, "alternate wildcard works" );

# allow for adding new queries without adjusting test count
done_testing( scalar( keys %queries ) + 9 );
