use strict;
use warnings;
use Test::More tests => 18;
use RDF::Sesame;
my $debug = $ENV{DEBUG};

SKIP: {
    my $uri    = $ENV{SESAME_URI};
    my $r_name = $ENV{SESAME_REPO};
    skip 'SESAME_URI environment not set', 18  unless $uri;
    skip 'SESAME_REPO environment not set', 18 unless $r_name;

    my $conn = RDF::Sesame->connect( uri => $uri );

    die "No connection: $RDF::Sesame::errstr\n" unless defined($conn);

    my $repo = $conn->open($ENV{SESAME_REPO});

    # make sure there's no old data in there
    $repo->clear;

    $repo->upload_uri( 'file:t/dc.rdf' );

    # run a query with no results
    my $t = $repo->select(q(
        SELECT x FROM {x} <http://example.com> {x}
    ));
    isa_ok($t, 'RDF::Sesame::TableResult', 'query result');
    ok( !$t->has_rows(), 'result has no rows' );

    # run a simple query
    $t = $repo->select('
        select x
        from {x} rdf:type {<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>}
    ');
    isa_ok($t, 'RDF::Sesame::TableResult', 'query result');

    # validate has_rows

    ok( $t->has_rows(), 'result has rows' );

    ################### each() #####################
    my @first = $t->each;
    cmp_ok(@first, '==', 1, 'right number of attributes');

    # try iterating
    my $count = 1;
    my @row;
    while (@row = $t->each) {
        print join("\t", @row), "\n" if $debug;
        $count++;
    }
    cmp_ok($count, '==', 15, 'right number of tuples');

    # try going back to the first row
    @row = $t->each;
    ok(eq_array(\@first, \@row), 'return to first row');

    # make sure the next each gets something different
    @row = $t->each;
    isnt(join('', @first), join('',@row), 'not the first row');

    ################### reset() #####################
    $t->reset;
    @row = $t->each;
    ok(eq_array(\@first, \@row), 'reset() works');


    ############# check return values ###############

    my @header = qw(x);
    my @vals   = map { ["<http://purl.org/dc/elements/1.1/$_>"] } qw(
        title
        creator
        subject
        description
        publisher
        contributor
        date
        type
        format
        identifier
        source
        language
        relation
        coverage
        rights
    );
    @vals = sort {$a->[0] cmp $b->[0]} @vals;

    my @rows = @{$t->rowRefs};
    @rows = sort {$a->[0] cmp $b->[0] } @rows;
    is_deeply(\@vals, \@rows, 'rowRefs');

    ################### sort() #####################
    $t->sort('x', 1, 0);
    is_deeply(\@vals, $t->rowRefs, 'sort alpha ascending (numeric params)' );
    $t->sort('x', 'non-numeric', 'asc');
    is_deeply(\@vals, $t->rowRefs, 'sort alpha ascending (named params)' );

    $t->replace('x', [10 .. 15, 5 .. 9, 1 .. 4] );
    @vals = map { [$_] } reverse (1 .. 15);
    $t->sort('x', 0, 1);
    is_deeply($t->rowRefs, \@vals, 'sort num descending (numeric params)' );
    $t->sort('x', 'numeric', 'desc');
    is_deeply($t->rowRefs, \@vals, 'sort num descending (named params)' );

    # behavior is undefined, so just don't die
    eval{ $t->sort('x', undef, undef); };
    ok(!$@, 'sort(, undefs)');

    ################# NULL values ###################

    $t = $repo->select('
        select l, n
        from
          {dc:title} rdfs:label {l};
                    [rdfs:subClassOf {n}]
          using namespace dc = <http://purl.org/dc/elements/1.1/>
    ');

    @header = qw/l n/;
    @vals = (
        [ '"Title"@en-us', undef ]
    );
    is_deeply($t->rowRefs(), \@vals, 'rowRefs with NULL' );

    ################# empty result ###################

    $t = $repo->select('
        select x
        from {x} rdf:type {<http://example.org/not/a/uri/>}
    ');

    ok(!$t->has_rows, 'result has no rows');

    ################# result with datatype ###################
    $t = $repo->select('
        select i
        from {<http://purl.org/dc/elements/1.1/creator>}
             dcterms:issued
             {i}
        using namespace
            dcterms = <http://purl.org/dc/terms/>
    ');
    @vals = (
        [ '"1999-07-02"^^<http://www.w3.org/2001/XMLSchema#date>' ]
    );
    is_deeply($t->rowRefs, \@vals, 'rowRefs with datatype' );

    # don't leave our junk lying around
    $repo->clear;

}

