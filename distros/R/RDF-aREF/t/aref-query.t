use strict;
use warnings;
use Test::More;
use RDF::aREF qw(aref_query aref_query_map);
use RDF::aREF::Query;
use Scalar::Util qw(reftype);

BEGIN {
    eval { require JSON; 1; } 
    or plan skip_all => "test requires JSON";
}

my $rdf = JSON::from_json(do { local (@ARGV, $/) = "t/doi-example.json"; <> });
my $uri = "http://dx.doi.org/10.2474/trol.7.147";

my @res = aref_query($rdf, $uri, '.');
is reftype $res[0], 'HASH';

# FIXME:
# is_deeply [ aref_query($rdf, $uri, '@') ], [ ], 'empty query (@)';
is_deeply [ aref_query($rdf, $uri, '') ], [ $uri ], 'empty query';

is_deeply [ aref_query($rdf, $uri, 'dct_title') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title';
is_deeply [ aref_query($rdf, $uri, 'dct_title@') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title@';
is_deeply [ aref_query($rdf, $uri, 'dct_title^xsd_string') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title^xsd_string';
is_deeply [ aref_query($rdf, $uri, 'dct_title@en') ], 
    [ ], 'dct_title@';

is_deeply [ sort(aref_query($rdf->{$uri}, 'dct_publisher')) ], [
    'Japanese Society of Tribologists',
    'http://d-nb.info/gnd/5027072-2',
], 'dct_publisher';

is_deeply [ aref_query($rdf->{$uri}, 'dct_publisher.') ], [
    'http://d-nb.info/gnd/5027072-2',
], 'dct_publisher.';

is_deeply [ aref_query($rdf->{$uri}, 'dct_date') ], ["2012"], 'dct_date';
is_deeply [ aref_query($rdf->{$uri}, 'dct_date^xsd_gYear') ], ["2012"], 'dct_date^xsd_gYear';
is_deeply [ aref_query($rdf->{$uri}, 'dct_date^xsd_foo') ], [], 'dct_date^xsd_foo';

is_deeply [ aref_query($rdf, $uri, 'dct_creator.a') ], 
          [ map { 'http://xmlns.com/foaf/0.1/Person' } 1..4 ], 'a is a valid property';

foreach my $query (qw(dct_creator dct_creator.)) {
    is_deeply [ sort (aref_query($rdf, $uri, $query)) ], [
        "http://id.crossref.org/contributor/daichi-uchijima-y2ol1uygjx72",
        "http://id.crossref.org/contributor/kensei-tanaka-y2ol1uygjx72",
        "http://id.crossref.org/contributor/kiyoshi-mabuchi-y2ol1uygjx72",
        "http://id.crossref.org/contributor/rina-sakai-y2ol1uygjx72",
    ], $query;
}

is join(' ',sort(aref_query($rdf,$uri,'dct_creator.foaf_familyName'))),
    "Mabuchi Sakai Tanaka Uchijima", 'dct_creator.foaf_familyName';

my %names = (
    'dct_creator.foaf_name'  => 4,
    'dct_creator.foaf_name@' => 4,
    'dct_creator.foaf_name@en' => 4,
    'dct_creator.foaf_name@ja' => 0,
);
while ( my ($query, $count) = each %names ) {
    my @names = aref_query( $rdf, $uri, $query );
    is scalar @names, $count, $query;
}

is scalar @{[ aref_query( $rdf, $uri, 
    qw(dct_creator. schema_author. dct_publisher.)) ]}, 5, 'multiple queries';

is_deeply [
        aref_query( $rdf, $uri, 'bibo_pageStart|bibo_unknown|bibo_pageEnd' ) 
    ], [qw(147 151)], 'multiple items';

foreach my $query ( "dct_title@#", "dct_date^_" ) {
    eval { RDF::Query->new($query) };
    ok $@, 'error in aREF query';
}

{
    my $rdf = {
        'http://example.org/book' => {
            dct_creator => [
                'http://example.org/alice', 
                "Bob"
            ]
        },
        'http://example.org/alice' => {
            foaf_name => "Alice"
        },
    };
    my $uri = 'http://example.org/book';

    is_deeply [ sort(aref_query($rdf, $uri, 'dct_creator')) ], 
        [qw(Bob http://example.org/alice)], 'literal and URI';

    my $record = aref_query_map( $rdf, $uri, {
        'dct_creator@' => 'creator',
        'dct_creator.foaf_name' => 'creator',
    });
    is_deeply [ sort @{$record->{creator}} ], [qw(Alice Bob)], 'aref_query_map';
}

{
    my $url = "http://example.org/";
    my $aref = {
        dct_title => "Hello@",
        _id       => $url,
    };
    is_deeply [ aref_query($aref, $url, 'dct_title@de','dct_title@') ],
        ["Hello"], "query from property map";
    is_deeply [ aref_query($aref, undef, 'dct_title@de','dct_title@') ],
        ["Hello"], "query from property map";
}

done_testing;
