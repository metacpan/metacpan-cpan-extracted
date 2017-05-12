# This is an empty test file that should be used
# as a template for creating more tests

use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok('RDF::Sesame'); }

SKIP: {
    skip 'SESAME_URI environment not set', 6  unless $ENV{SESAME_URI};
    skip 'SESAME_REPO environment not set', 6 unless $ENV{SESAME_REPO};

    my $conn = RDF::Sesame->connect( uri => $ENV{SESAME_URI} );

    die "No connection: $RDF::Sesame::errstr\n" unless defined($conn);
    isa_ok($conn, 'RDF::Sesame::Connection', 'connection');

    my $repo = $conn->open($ENV{SESAME_REPO});
    isa_ok($repo, 'RDF::Sesame::Repository', 'repository');


    # try to manually clear the repository so that
    # we can see the insides of the Response object
    my $r = $conn->command(
        $repo->{id},
        'clearRepository',
        { resultFormat=>'xml' },
    );

    isa_ok($r->http_response, 'HTTP::Response', 'response after command');

    # I'm not sure how to actually test the validity of the XML response
    # I don't want the tests to needlessly fail when the XML changes in
    # a minor way.  If the XML changes dramatically, other tests will fail
    # to indicate the problem.
    ok($r->xml, '$r->xml works');

    # create an empty RDF::Sesame::Response
    $r = RDF::Sesame::Response->new;
    isa_ok($r, 'RDF::Sesame::Response', 'empty Response');
    ok(!defined($r->{http}), 'empty Response is empty');
}

