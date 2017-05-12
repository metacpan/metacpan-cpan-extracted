use Test::More;
use Test::Moose;
eval "use Carp::Always"; # for those who don't have it

BEGIN {

  foreach my $class (qw(
      RDF::Core
  )) {
      plan skip_all => "Testing RDF semantic requires $class"
          unless not not eval "require $class";
  }

  plan tests => 9;

  use_ok('t::lib::EmbeddedRestRDFServer');
};

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

isa_ok( $server, 'EmbeddedRestRDFServer' );

does_ok( $server, 'RDF::Server::Protocol::Embedded' );
does_ok( $server, 'RDF::Server::Interface::REST' );
does_ok( $server, 'RDF::Server::Semantic::RDF' );

isa_ok( $server -> handler, 'RDF::Server::Semantic::RDF::Collection');

my @handlers = @{$server -> handler -> handlers -> ()};

is( scalar(@handlers), 2, 'Two handlers' );

my( $handler, $path_info) = $server -> handler -> handles_path('', '/foo/');

isa_ok( $handler, 'RDF::Server::Model::RDFCore' );

does_ok( $handler, 'RDF::Server::Role::Mutable' );
