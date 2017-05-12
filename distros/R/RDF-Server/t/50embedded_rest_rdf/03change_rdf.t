use Test::More;
eval "use Carp::Always"; # for those who don't have it

if( not eval 'require RDF::Core' ) {
    plan skip_all => 'RDF::Core required to run tests';
}

plan tests => 6;

use t::lib::EmbeddedRestRDFServer;
use RDF::Server::Constants qw( RDF_NS ATOM_NS );
use Path::Class::File;

my $server = EmbeddedRestRDFServer -> new(
  handler => [
  {
    path_prefix => '/foo/',
    model => [{
        class => 'RDFCore',
        namespace => 'http://www.example.com/foo/',
    }]
  },
  {
    path_prefix => '/bar/',
    model => {
        class => 'RDFCore',
        namespace => 'http://www.example.com/bar/',
    }
  }]
);

my($empty_json, $loaded_json);

SKIP: {
    skip "JSON::Any required for JSON tests", 2 
        unless not not eval "require JSON::Any";

    $empty_json = $server -> fetch( "/foo/.json" );

    isnt( $empty_json, '' );

    is( $empty_json, '{}' );
}

    $loaded_doc = $server -> update( "/foo/", join("\n", Path::Class::File->new('t/data/AirportCodes.daml') -> slurp( chomp => 1 )));

SKIP: {
    skip "JSON::Any required for JSON tests", 1 
        unless not not eval "require JSON::Any";

    $loaded_json = $server -> fetch( "/foo/.json" );

    isnt( $loaded_json, $empty_json );
}

like( $loaded_doc, qr{Albuquerque International Airport}, 'Document references Albuquerque' );

$server -> delete( "/foo/", <<eoRDF);
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xmlns:daml="http://www.daml.org/2001/03/daml+oil#"
         xmlns="http://www.daml.ri.cmu.edu/ont/AirportCodes.daml#">
  <AirportCode rdf:ID="ABQ">
    <city>Albuquerque</city>
    <state>NM</state>
    <country>USA</country>
    <airport>Albuquerque International Airport </airport>
  </AirportCode>
</rdf:RDF>
eoRDF

my $no_abq = $server -> fetch( "/foo/" );

unlike( $no_abq, qr{Albuquerque International Airport}, "Document no longer references Albuquerque" );

my($loc, $created_doc) = $server -> create('/foo/', join("\n", Path::Class::File->new('t/data/AirportCodes.daml') -> slurp( chomp => 1 )));

$loaded_doc = $server -> fetch( "/foo/" );

like( $loaded_doc, qr{Albuquerque International Airport}, 'Document references Albuquerque again' );

