use strict;
use warnings;
use Test::More;

use RDF::Sesame;

plan tests => 7;

SKIP: {

    # do we have all that's needed to run this test?
    my $uri    = $ENV{SESAME_URI};
    my $r_name = $ENV{SESAME_REPO};
    skip 'SESAME_URI environment not set', 7  unless $uri;
    skip 'SESAME_REPO environment not set', 7 unless $r_name;
    eval "use Test::RDF";
    skip "Test::RDF needed for testing construct queries", 7
        if $@ || $ENV{MINIMAL_TEST};

    my $conn = RDF::Sesame->connect( uri => $uri );
    my $repo = $conn->open($r_name);
    $repo->clear();  # make sure it's empty
    $repo->upload_uri( 'file:t/dc.rdf' );

    my $query = qq(
        CONSTRUCT {a} <http://example.org/blurb> {b}
        FROM      {a} rdfs:label                 {b}
        USING NAMESPACE
            rdfs = <http://www.w3.org/2000/01/rdf-schema#>
    );

    # try a simple construction
    {
        my $rdf = $repo->construct(
            format => 'ntriples',
            query  => $query,
        );
        rdf_eq(
            ntriples => \$rdf,
            turtle   => 't/dc-construct.ttl',
            'construct to scalar return value',
        );
    }

    # try construction to a filehandle
    {
        my $rdf;
        open my $fh, '>', \$rdf;
        $repo->construct(
            format => 'turtle',
            query  => $query,
            output => $fh,
        );
        close $fh;
        rdf_eq(
            turtle => \$rdf,
            turtle => 't/dc-construct.ttl',
            'construct to a filehandle',
        );
    }

    # try construction to a named file
    SKIP: {
        eval "use File::Temp";
        skip "File::Temp needed for testing repository dump to file", 1
            if $@;

        my ($fh, $filename) = File::Temp::tempfile();
        close $fh;
        $repo->construct(
            format => 'rdfxml',
            query  => $query,
            output => $filename,
        );
        rdf_eq(
            rdfxml => $filename,
            turtle => 't/dc-construct.ttl',
            'construct to a filename',
        );
    }

    # try some error conditions
    eval { $repo->construct( query => $query ) };
    like( $@, qr/No serialization format specified/, 'no construct format' );

    eval { $repo->construct( format => 'turtle' ) };
    like( $@, qr/No query specified/, 'no construct query' );

    eval { $repo->construct( format => 'turtle', query => 'not valid' ) };
    like( $@, qr/MALFORMED_QUERY/, 'invalid construct query' );

    ok($repo->clear, 'clearing repository');
}
