use Test::More tests => 11;
#use Carp::Always;

BEGIN {
  use_ok( 'RDF::Server::Formatter::Atom' );
}

use RDF::Server::Types qw( Exception );
use RDF::Server::Constants qw( RDF_NS DC_NS ATOM_NS );
use Iterator::Simple qw(iter);
eval "use Carp::Always"; # for those who don't have it

# this formatter does not want rdf
ok( RDF::Server::Formatter::Atom -> wants_rdf );

my($doc, $root) = RDF::Server::Formatter::Atom -> _new_xml_doc( ATOM_NS, 'entry' );

isa_ok( $doc, 'RDF::Server::XMLDoc' );

my %ns = ( 'http://www.example.com/blank/' => '' );

my $ns = \%ns;

is( $ns -> {'http://www.example.com/blank/'}, '' );

RDF::Server::Formatter::Atom -> _define_namespace($root, $ns, 'http://example.com/foo/', 'foo');

is( $ns -> {'http://example.com/foo/'}, 'foo' );

ok( defined($$ns{'http://example.com/foo/'}) && $$ns{'http://example.com/foo/'} eq 'foo', 'defined and not blank');

RDF::Server::Formatter::Atom -> _define_namespace($root, $ns, 'http://example.com/foo/', 'fooo');

is( $ns -> {'http://example.com/foo/'}, 'foo' );

ok( defined($ns -> {'http://www.example.com/blank/'}) && $ns -> {'http://www.example.com/blank/'} eq '', 'defined but blank');

RDF::Server::Formatter::Atom -> _define_namespace($root, $ns, 'http://www.example.com/blank/', 'blank');

is( $ns -> {'http://www.example.com/blank/'}, 'blank' );


# feed testing requires a model
SKIP: {
    skip 'RDF::Core not available', 2 unless not not eval 'require RDF::Core';

    Class::MOP::load_class( 'RDF::Server::Model::RDFCore' );

    my $model = RDF::Server::Model::RDFCore -> new(
        namespace => 'http://www.example.com/',
    );

    my $r = $model -> resource([ $model -> namespace, $model -> new_uuid ]);

    $r -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[RDF_NS]}"
         xmlns:dc="@{[DC_NS]}"
         xmlns:atom="@{[ATOM_NS]}"
         xmlns:x="http://www.example.com/ns/"
>
  <rdf:Description>
    <x:title>Foo</x:title>
    <dc:title>DC Foo</dc:title>
  </rdf:Description>
</rdf:RDF>
eoRDF

    my($type, $xml) = RDF::Server::Formatter::Atom -> feed(
       title => "Feed Title",
       id => "foo-id",
       link => '/some/url',
       entries => $model -> resources
    );

#    diag $r -> fetch;

#    diag $xml;

    isnt( $xml, '' );
    is($type, 'application/atom+xml' );
}
