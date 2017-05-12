use Test::More tests => 18;

BEGIN {
  use_ok( 'RDF::Server::Formatter::RDF' );
}

use RDF::Server::Constants qw( RDF_NS );
eval "use Carp::Always"; # for those who don't have it

# this formatter wants rdf
ok( RDF::Server::Formatter::RDF -> wants_rdf );

# to_rdf should be the identity function
is( 'foo', RDF::Server::Formatter::RDF -> to_rdf( 'foo' ) );

my($doc, $root) = RDF::Server::Formatter::RDF -> _new_xml_doc( RDF_NS, 'RDF' );

isa_ok( $doc, 'RDF::Server::XMLDoc' );

my($doc2, $root2) = RDF::Server::Formatter::RDF -> _new_xml_doc( 'RDF' );

isa_ok( $doc2, 'RDF::Server::XMLDoc' );

($doc, $root) = RDF::Server::Formatter::RDF -> _new_xml_doc( 'http://example.com/ns/', 'RDF' );

isa_ok( $doc, 'RDF::Server::XMLDoc' );

$root -> setNamespace( 'http://www.example.com/blank/', '' );

my %ns = ( 'http://www.example.com/blank/' => '' );

my $ns = \%ns;

is( $ns -> {'http://www.example.com/blank/'}, '' );

RDF::Server::Formatter::RDF -> _define_namespace($root, $ns, 'http://example.com/foo/', 'foo');

is( $ns -> {'http://example.com/foo/'}, 'foo' );

ok( defined($$ns{'http://example.com/foo/'}) && $$ns{'http://example.com/foo/'} eq 'foo', 'defined and not blank');

RDF::Server::Formatter::RDF -> _define_namespace($root, $ns, 'http://example.com/foo/', 'fooo');

is( $ns -> {'http://example.com/foo/'}, 'foo' );

ok( defined($ns -> {'http://www.example.com/blank/'}) && $ns -> {'http://www.example.com/blank/'} eq '', 'defined but blank');

RDF::Server::Formatter::RDF -> _define_namespace($root, $ns, 'http://www.example.com/blank/', 'blank');

is( $ns -> {'http://www.example.com/blank/'}, 'blank' );

RDF::Server::Formatter::RDF -> _import_as_child_of(
    RDF::Server::XMLDoc -> new( $doc ),
    $root,
    RDF::Server::XMLDoc -> new( $doc2 )
);

ok( $root -> isSameNode( $root2 -> getOwner ) );

eval { RDF::Server::Formatter::RDF -> feed( ); };
ok( $@, 'feed not yet implemented' );

eval { RDF::Server::Formatter::RDF -> category( ); };
ok( $@, 'category not yet implemented' );

eval { RDF::Server::Formatter::RDF -> collection( ); };
ok( $@, 'collection not yet implemented' );

eval { RDF::Server::Formatter::RDF -> workspace( ); };
ok( $@, 'workspace not yet implemented' );

eval { RDF::Server::Formatter::RDF -> service( ); };
ok( $@, 'service not yet implemented' );
