use Test::More;
eval "use Carp::Always"; # for those who don't have it

if( not eval 'require RDF::Core' ) {
    plan skip_all => 'RDF::Core required to run tests';
}

plan tests => 2;

use t::lib::EmbeddedRestRDFServer;
use RDF::Server::Constants qw( RDF_NS ATOM_NS );
use Path::Class::File;

my $server = EmbeddedRestRDFServer -> new(
  handler => [
  {
    path_prefix => '/foo/',
    model => {
        class => 'RDFCore',
        namespace => 'http://www.example.com/foo/',
    }
  },
  {
    path_prefix => '/bar/',
    model => {
        class => 'RDFCore',
        namespace => 'http://www.example.com/bar/',
    }
  }]
);

my $empty_doc = $server -> fetch('/foo/');
my $loaded_doc = $server -> update( "/foo/", join("\n", Path::Class::File->new('t/data/AirportCodes.daml') -> slurp( chomp => 1 )));

my $new_doc = $server -> fetch('/foo/');

isnt( $new_doc, $empty_doc, "Loaded doc isn't empty" );
is($new_doc, $loaded_doc, "Loaded doc and new fetch are the same" );
