use Test::More;
use Test::Moose;
eval "use Carp::Always"; # for those who don't have it

BEGIN {

  foreach my $class (qw(
      RDF::Core
      FCGI
      MooseX::Daemonize
  )) {
      plan skip_all => "Testing FCGI protocol requires $class"
          unless not not eval "require $class";
  }

  plan tests => 6;

  use_ok('RDF::Server::Protocol::FCGI');

  use_ok('t::lib::FCGIRestAtomServer');
};

my $server = FCGIRestAtomServer -> new(
  socket => '/tmp/fcgi_rest_atom.socket',
  handler => [ collection => {
    title => 'Example Collection',
    model => {
        class => 'RDFCore',
        namespace => 'http://www.example.com/',
    }
  }]
);

isa_ok( $server, 'FCGIRestAtomServer' );

does_ok( $server, 'RDF::Server::Protocol::FCGI' );
does_ok( $server, 'RDF::Server::Interface::REST' );
does_ok( $server, 'RDF::Server::Semantic::Atom' );
