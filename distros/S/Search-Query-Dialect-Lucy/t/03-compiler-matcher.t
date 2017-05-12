#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw( dump );
use File::Temp qw( tempdir );
my $invindex = tempdir( CLEANUP => 1 );

use Lucy;    # gets everything, really
use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Search::IndexSearcher;

##########################################################################
#    custom query/compiler/matcher troika
##########################################################################
# delegation pattern suggested by Marvin at
# http://markmail.org/message/4y4titlbwd5slgmf
{

    package MyTermQuery;
    use base qw( Lucy::Search::Query );
    use Lucy::Search::TermQuery;

    my %child_query;

    sub new {
        my ( $class, %args ) = @_;
        my $child = Lucy::Search::TermQuery->new(%args);
        my $self  = $class->SUPER::new();
        $child_query{$$self} = $child;
        return $self;
    }

    sub make_compiler {
        my ( $self, %args ) = @_;
        my $child_compiler = $child_query{$$self}->make_compiler(%args);
        my $compiler       = MyCompiler->new(
            child    => $child_compiler,
            searcher => $args{searcher},
            parent   => $self,
        );
        $compiler->normalize unless $args{subordinate};
        return $compiler;
    }

    sub DESTROY {
        my $self = shift;
        delete $child_query{$$self};
        $self->SUPER::DESTROY;
    }

    sub AUTOLOAD {
        my $self   = shift;
        my $method = our $AUTOLOAD;
        $method =~ s/.*://;
        my $child = $child_query{$$self};
        if ( $child->can($method) ) {
            return $child->$method(@_);
        }

        Carp::croak("no such method $method for $child");
    }
}

{

    package MyCompiler;
    use base qw( Lucy::Search::Compiler );

    my %child_compiler;

    sub new {
        my ( $class, %args ) = @_;
        my $child = delete $args{child};
        my $self  = $class->SUPER::new(%args);
        $child_compiler{$$self} = $child;
        return $self;
    }

    sub make_matcher {
        my ( $self, %args ) = @_;
        my $child_matcher = $child_compiler{$$self}->make_matcher(%args);
        return unless $child_matcher;
        my $sort_reader = $args{reader}->obtain("Lucy::Index::SortReader");
        my $sort_cache  = $sort_reader->fetch_sort_cache('option');
        return MyMatcher->new(
            child      => $child_matcher,
            sort_cache => $sort_cache,
        );
    }

    sub DESTROY {
        my $self = shift;
        delete $child_compiler{$$self};
        $self->SUPER::DESTROY;
    }

    sub AUTOLOAD {
        my $self   = shift;
        my $method = our $AUTOLOAD;
        $method =~ s/.*://;
        my $child = $child_compiler{$$self};
        if ( $child->can($method) ) {
            return $child->$method(@_);
        }

        Carp::croak("no such method $method for $child");
    }
}

{

    package MyMatcher;
    use base qw( Lucy::Search::Matcher );

    my %child_matcher;
    my %sort_cache;

    sub new {
        my $class      = shift;
        my %args       = @_;
        my $child      = delete $args{child};
        my $sort_cache = delete $args{sort_cache};
        my $self       = $class->SUPER::new(%args);
        $child_matcher{$$self} = $child;
        $sort_cache{$$self}    = $sort_cache;

        return $self;
    }

    my %magic_scores = (
        a => 100,
        b => 200,
        c => 300,
        d => 400,
    );

    sub score {
        my $self = shift;

        # Try for special score.
        my $doc_id = $self->get_doc_id;
        if ( $sort_cache{$$self} ) {
            my $ord = $sort_cache{$$self}->ordinal($doc_id);
            my $value = $sort_cache{$$self}->value( 'ord' => $ord );
            if ($value) {
                my $magic_score = $magic_scores{$value};
                return $magic_score || 0;
            }
        }

        return 0;

        # Fall back to child Matcher's score.
        # in our case, unpredictable for tests.
        #return $child_matcher{$$self}->score;
    }

    sub DESTROY {
        my $self = shift;
        delete $child_matcher{$$self};
        delete $sort_cache{$$self};
        $self->SUPER::DESTROY;
    }

    # Delegate next() and get_doc_id() to the child Matcher explicitly,
    # rather than relying on AUTOLOAD,
    # since they are required abstract methods
    sub next       { $child_matcher{ ${ +shift } }->next }
    sub get_doc_id { $child_matcher{ ${ +shift } }->get_doc_id }

    sub AUTOLOAD {
        my $self   = shift;
        my $method = our $AUTOLOAD;
        $method =~ s/.*://;
        my $child = $child_matcher{$$self};
        if ( $child->can($method) ) {
            return $child->$method(@_);
        }

        Carp::croak("no such method $method for $child");
    }

}

#############################################################################
#     setup temp index
#############################################################################
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
$schema->spec_field( name => 'uri',    type => $fulltext );
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

#######################################################################
#   set up our parser tests
#######################################################################
use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields => {
            title => { analyzer => $analyzer },
            color => {
                analyzer         => $analyzer,
                term_query_class => 'MyTermQuery',
            },
            date   => { analyzer => $analyzer },
            option => {
                analyzer         => $analyzer,
                term_query_class => 'MyTermQuery',
            },
        },
        query_class_opts => { default_field => [qw( color )], },
        dialect          => 'Lucy',
        croak_on_error   => 1,
    ),
    "new parser"
);

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

# create the index
for my $doc ( keys %docs ) {
    $indexer->add_doc( { uri => $doc, %{ $docs{$doc} } } );
}

$indexer->commit;

########################################################################
#           run the tests
########################################################################

my $searcher = Lucy::Search::IndexSearcher->new( index => $invindex, );

# search
my %queries = (
    'option=a'                      => { uri => 'doc1', score => 100 },
    'option=b'                      => { uri => 'doc2', score => 200 },
    'option=c'                      => { uri => 'doc4', score => 300 },
    'option=d'                      => { uri => 'doc5', score => 400 },
    'option!=(a and b and c and d)' => { uri => 'doc3', score => 0 },
    'white'                         => [
        {   uri   => 'doc4',
            score => 300,
        },
        {   uri   => 'doc3',
            score => 0,
        },
    ]
);

my $expected_tests = 0;
for my $str ( sort keys %queries ) {
    my $query = $parser->parse($str);

    #$query->debug(1);

    my $expected = $queries{$str};
    if ( ref $expected ne 'ARRAY' ) {
        $expected = [$expected];
    }

    $expected_tests += scalar @$expected;

    #diag($query);
    my $lucy_query = $query->as_lucy_query();

    #diag( dump $lucy_query->dump );
    if ( !$lucy_query ) {
        diag("No lucy_query for $str");
        next;
    }
    my $hits = $searcher->hits(
        query      => $lucy_query,
        offset     => 0,
        num_wanted => 10,            # more than we have
    );

    my $i = 0;
    while ( my $result = $hits->next ) {
        is( $result->get_score,
            $expected->[$i]->{score},
            sprintf(
                "doc '%s' got expected score for '%s'",
                $result->{uri}, $str
            )
        );
        is( $result->{uri},
            $expected->[$i]->{uri},
            "got rank expected for $result->{uri}"
        );
        $i++;
    }
}

#diag("expected_tests=$expected_tests");

# allow for adding new queries without adjusting test count
done_testing( ( $expected_tests * 2 ) + 2 );
