use Test::More;
eval "use Carp::Always"; # for those who don't have it

BEGIN {

  foreach my $class (qw(
      RDF::Core
      MooseX::Daemonize
      POE::Component::Server::HTTP
  )) {
      plan skip_all => "Testing HTTP protocol requires $class"
          unless not not eval "require $class";
  }

  plan tests => 3;

  use_ok('RDF::Server::Protocol::HTTP');

  use_ok('t::lib::HTTPRestAtomServer');
};

my $server = HTTPRestAtomServer -> new(
  handler => [ collection => {
    title => 'Example Collection',
    model => {
        class => 'RDFCore',
        namespace => 'http://www.example.com/',
    }
  }]
);

isa_ok( $server, 'HTTPRestAtomServer' );
