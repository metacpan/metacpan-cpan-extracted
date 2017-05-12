use Test::More;
use strict;
use warnings;
no warnings 'once';  # because of $RDF::Sesame::errstr

# do we have info about the testing server?
my $uri    = $ENV{SESAME_URI};
my $r_name = $ENV{SESAME_REPO};
plan skip_all => 'SESAME_URI environment not set'   if !$uri;
plan skip_all => 'SESAME_REPO environment not set'  if !$r_name;

# do we have the necessary testing modules?
eval q{ use Test::Output; 1 };
plan skip_all => "Test::Output required to test debugging output"
    if $@ || $ENV{MINIMAL_TEST};
my $conn = RDF::Sesame->connect( uri => $uri )
    or plan skip_all => "Connection failure for $uri: $RDF::Sesame::errstr";

# we can finally set our plan
plan tests => 7;
$ENV{RDFSESAME_DEBUG} = 1;

# None of these should generate output
my $repo;
output_is(
    sub { $repo = $conn->open($r_name) },
    q{},  # STDOUT
    q{},  # STDERR
    'no output when opening'
);
output_is(
    sub { $repo->query_language('RQL') },
    q{},  # STDOUT
    q{},  # STDERR
    'no output when changing query language'
);

# These ones should generate output
output_like(
    sub {
        $repo->upload_data(
            '<http://example.com> <http://example.com/prop> "testing".'
        );
    },
    qr{ \A \z }xms,
    qr{\ACommand 0 : Ran uploadData in \d+ ms},
    'uploading data from NTriples',
);
output_like(
    sub {
        $repo->upload_uri(
            uri    => 'http://www.ndrix.com/rdf-sesame.rdf', 
            format => 'rdfxml'
        );
    },
    qr{ \A \z }xms,
    qr{\ACommand 1 : Ran uploadURL in \d+ ms},
    'uploading data from URL',
);
output_like(
    sub {
        $repo->select(
            query    => 'SELECT x, p, y FROM {x} p {y}',
            language => 'SeRQL',
        );
    },
    qr{ \A \z }xms,
    qr{\ACommand 2 : Ran evaluateTableQuery in \d+ ms},
    'uploading data from URL',
);
output_like(
    sub { $repo->remove('<http://purl.org/dc/elements/1.1/title>') },
    qr{ \A \z }xms,
    qr{\ACommand 3 : Ran removeStatements in \d+ ms},
    'removing triples',
);
output_like(
    sub { $repo->clear() },
    qr{ \A \z }xms,
    qr{\ACommand 4 : Ran clearRepository in \d+ ms},
    'clearing repository',
);

# try turning off debugging
$ENV{RDFSESAME_DEBUG} = 0;
output_is(
    sub { $repo->clear() },
    q{},
    q{},
    'no more debugging',
);

