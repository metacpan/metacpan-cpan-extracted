use Test::More tests => 57;

my $debug = $ENV{DEBUG};

BEGIN { use_ok('RDF::Sesame'); }

SKIP: {
    my $uri    = $ENV{SESAME_URI};
    my $r_name = $ENV{SESAME_REPO};
    skip 'SESAME_URI environment not set', 56  unless $uri;
    skip 'SESAME_REPO environment not set', 56 unless $r_name;

    my $conn = RDF::Sesame->connect( uri => $uri );

    die "No connection: $RDF::Sesame::errstr\n" unless defined($conn);

    # try two failing calls
    my $repo = $conn->open;
    is($repo, '', 'open() gives empty string');
    $repo = $conn->open( blahblahblah=>'foo' );
    is($repo, '', 'open(junk) gives empty string');

    # try the single scalar version
    $repo = $conn->open($r_name);
    isa_ok($repo, 'RDF::Sesame::Repository', 'repository');

    # try the named parameter version
    $repo = $conn->open(id => $r_name, query_language=>'RDQL');
    isa_ok($repo, 'RDF::Sesame::Repository', 'repository');
    $repo = $conn->open(id => $r_name);
    isa_ok($repo, 'RDF::Sesame::Repository', 'repository');

    ############## query_language ##################

    # check the default query language
    my $prev = $repo->query_language;
    is($prev, 'SeRQL', 'default query language');
    is($repo->errstr, '', '  no error message');


    # set all acceptable query languages
    foreach ( qw/RQL RDQL SeRQL/ ) {
        is($repo->query_language($_), $prev, "setting query language ($_)");
        $prev = $_;
    }
    is($repo->query_language, $prev, "check last set ($prev)");
    is($repo->errstr, '', '  no error message');

    # set a bad query language
    is($repo->query_language("WRONG"), $prev, "set bad query language");
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;
    is($repo->query_language, $prev, "  language didn't set");

    ############## upload_data ##################
    # upload N-Triples without specifying format
    my $c = $repo->upload_data(
        '<http://example.com> <http://example.com/prop> "testing".'
    );
    cmp_ok($c, '==', 1, 'single N-Triple');
    is($repo->errstr, '', '  no error message');

    # use a bad format
    $c = $repo->upload_data(
        data => '',
        format => 'this is not a format',
    );
    cmp_ok($c, '==', 0, 'invalid format');
    ok($repo->errstr, '  got error message');

    # don't verify data and specify the base
    $c = $repo->upload_data(
        data=>'<http://example.com> <http://example.com/prop> "testing".',
        verify => 0,
        base => 'http://example.com/',
    );
    cmp_ok($c, '==', 1, 'with base and no verify');
    is($repo->errstr, '', '  no error message');

    # simulate server problems
    my $fake_repo = RDF::Sesame->connect(host=>'example.org:8080',timeout=>1)
                               ->open('fake');
    $c = $fake_repo->upload_data('blah');
    cmp_ok($c, '==', 0, 'non-existent server');
    ok($fake_repo->errstr, '  got error message');

    ############## upload_uri ##################

    # don't verify data and specify the base
    $c = $repo->upload_uri(
        uri=>'http://www.ndrix.com/small.rdf',
        verify => 0,
        base => 'http://example.com/',
    );
    cmp_ok($c, '==', 1, 'with base and no verify');
    is($repo->errstr, '', '  no error message');

    # simulate server problems
    $fake_repo = RDF::Sesame->connect(host=>'example.org:8080',timeout=>1)
                            ->open('fake');
    $c = $fake_repo->upload_uri('http://example.net/index.rdf');
    cmp_ok($c, '==', 0, 'non-existent server');
    ok($fake_repo->errstr, '  got error message');

    # server problems with clear
    $c = $fake_repo->clear;
    is($c, '', 'network error with clear');

    # try a large (more than 1,000 triples), local upload
    require_ok('LWP::Simple');
    $repo->clear;
    $c = $repo->upload_uri(
        uri    => 'file:t/random-large.ttl', 
        format => 'turtle'
    );
    cmp_ok($c, '==', 1234, 'uploaded local random-large.ttl');
    is($repo->errstr, '', '  no error message');

    # try a large (more than 1,000 triples), remote upload
    $repo->clear;
    $c = $repo->upload_uri(
        uri    => 'http://www.ndrix.com/random-large.ttl', 
        format => 'turtle'
    );
    cmp_ok($c, '==', 1234, 'uploaded remote random-large.ttl');
    is($repo->errstr, '', '  no error message');


    # try a real, remote upload
    $repo->clear;
    $c = $repo->upload_uri(
        uri    => 'http://www.ndrix.com/rdf-sesame.rdf', 
        format => 'rdfxml'
    );
    cmp_ok($c, '==', 48, 'uploaded remote foaf.rdf');
    is($repo->errstr, '', '  no error message');

    $c = $repo->upload_uri(
        uri    => 'http://www.ndrix.com/rdf-sesame.rdf', 
        format => 'A BAD FORMAT'
    );
    cmp_ok($c, '==', 0, 'upload with a bad type');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;

    $c = $repo->upload_uri( 'http://this is a bad URI' );
    cmp_ok($c, '==', 0, 'upload with a bad URI');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;

    $c = $repo->upload_uri( 'http://google.com/index.html' );
    cmp_ok($c, '==', 0, 'upload bad RDF from URI');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;

    $c = $repo->upload_uri(
        uri         => 'file:fooishness-testing.rdf',
        server_file => 1,
    );
    cmp_ok($c, '==', 0, 'upload bad RDF from server-side URI');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;

    $c = $repo->upload_uri( 'file:t/dc.rdf' );
    cmp_ok($c, '==', 146, 'uploading with file: scheme');
    is($repo->errstr, '', '  no error message');

    $c = $repo->upload_uri('file:error.rdf');
    cmp_ok($c, '==', 0, 'upload bad RDF from file');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;


    ############## select ##################

    my $t = $repo->select(
        query => '
            SELECT x, p, y
            FROM {x} p {y}
        ',
        language => 'SeRQL',
    );
    isa_ok($t, 'RDF::Sesame::TableResult', 'query result');
    is($repo->errstr, '', '  no error message');

    $t = $repo->select('BAD QUERY.');
    is($t, '', 'failed query');
    isnt($repo->errstr, '', '  got error message');
    diag($repo->errstr) if $debug;

    ############## remove ##################

    $c = $repo->remove('<http://purl.org/dc/elements/1.1/title>');
    cmp_ok($c, '==', 9, 'removing dc:title subjects');

    $c = $repo->remove(undef, '<http://purl.org/dc/elements/1.1/title>');
    cmp_ok($c, '==', 1, 'removing dc:title predicates');

    $c = $repo->remove(
        undef,
        undef,
        '<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>'
    );
    cmp_ok($c, '==', 14, 'removing rdfs:Property objects');

    # simulate server problems
    $fake_repo = RDF::Sesame->connect(host=>'example.org:8080',timeout=>1)
                            ->open('fake');
    $c = $fake_repo->remove;
    cmp_ok($c, '==', 0, 'remove from non-existent server');

    ############## clear ##################

    ok($repo->clear, 'clearing repository');

}
