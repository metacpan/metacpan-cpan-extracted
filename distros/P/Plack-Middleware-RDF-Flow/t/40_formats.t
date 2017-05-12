use strict;
use warnings;

use lib 't';
use TestPlackApp;

use Test::More;
use Plack::Middleware::RDF::Flow;
use RDF::Flow::Dummy;

my $app = Plack::Middleware::RDF::Flow->new(
    source => RDF::Flow::Dummy->new
);

test_app
    app   => $app,
    tests => [{
        name    => 'request format=ttl',
        request => [ GET => '/example?format=ttl' ],
        content => qr{example> a <http://www.w3.org/2000/01/rdf-schema#Resource>},
        headers => { 'Content-Type' => 'application/turtle' },
    }];

$app = Plack::Middleware::RDF::Flow->new(
    source  => RDF::Flow::Dummy->new,
    formats => { rdf => 'rdfxml' }
);

test_app
    name  => 'selected formats',
    app   => $app,
    tests => [{
        request => [ GET => '/example?format=rdf' ], code => 200
    },{
        request => [ GET => '/example?format=ttl' ], code => 404
    }];

$app = Plack::Middleware::RDF::Flow->new(
    source        => RDF::Flow::Dummy->new,
    via_param     => 0,
    via_extension => 1
);

test_app
    name => 'format_extension',
    app  => $app,
    tests => [{
        request => [ GET => '/example?format=ttl' ], code => 404
    },{
        request => [ GET => '/example.ttl' ], code => 200,
        content => qr{example> a <http://www.w3.org/2000/01/rdf-schema#Resource>},
    },{
        request => [ GET => '/example.ttl.ttl' ], code => 200,
        content => qr{example.ttl> a <http://www.w3.org/2000/01/rdf-schema#Resource>},
    },{
        request => [ GET => '/example.ttl?format=rdf' ], code => 200,
        content => qr{example> a <http://www.w3.org/2000/01/rdf-schema#Resource>},
    }];

$app = Plack::Middleware::RDF::Flow->new(
    source        => RDF::Flow::Dummy->new,
    via_param     => 1,
    via_extension => 1
);

test_app
    name => 'format_extension',
    app  => $app,
    tests => [{
        request => [ GET => '/example?format=ttl' ], code => 200,
        headers => { 'Content-Type' => 'application/turtle' },
    },{
        request => [ GET => '/example.rdfxml' ], code => 200,
        headers => { 'Content-Type' => 'application/rdf+xml' },
    },{
        request => [ GET => '/example.ttl?format=rdf' ], code => 200,
        headers => { 'Content-Type' => 'application/rdf+xml' },
    }];


done_testing;
