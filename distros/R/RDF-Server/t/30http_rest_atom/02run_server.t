use Test::More;

BEGIN {
  foreach my $class (qw(
      RDF::Core
      MooseX::Daemonize
      POE::Component::Server::HTTP
  )) {
      plan skip_all => "Testing HTTP protocol requires $class"
          unless not not eval "require $class";
  }

  plan tests => 4;
}

use t::lib::HTTPRestAtomServer;
eval "use Carp::Always"; # for those who don't have it

my $PORT = 2080;

my $UA = HTTPRestAtomServer -> fork_and_return_ua(
    port => $PORT,
    loglevel => 8, # test debugging levels
    default_renderer => 'Atom',
    handler => [
      collection => {
        path_prefix => '/',
        title => 'Example Collection',
        categories => [
            { term => 'foo', scheme => 'http://www.example.com/' },
            { term => 'bar', scheme => 'http://www.example.com/' },
        ],
        model => {
            class => 'RDFCore',
            namespace => 'http://www.example.com/',
        }
      }
    ]
);

ok( $UA, "We have a user agent");

my $req = HTTP::Request -> new(GET => "http://localhost:$PORT/");
my $resp = $UA -> request($req);

ok( $resp -> is_success );

$req = HTTP::Request -> new(GET => "http://localhost:$PORT/foo/");
$resp = $UA -> request($req);

ok( $resp -> is_success );
is( $resp -> header('Content-Type'), 'application/atom+xml' );
