use Test::More;
#use lib 't/lib';

use t::lib::utils;
eval "use Carp::Always"; # for those who don't have it

my $lighttpd;
BEGIN {
    $lighttpd = utils::find_lighttpd();

    plan skip_all => "A lighttpd binary must be available for this test"   
        unless $lighttpd;
}


BEGIN {
  foreach my $class (qw(
      RDF::Core
      FCGI
      MooseX::Daemonize
  )) {
      plan skip_all => "Testing FCGI protocol requires $class"
          unless not not eval "require $class";
  }
}

use t::lib::FCGIRestAtomServer;

my $PORT = 2090;

my $UA = FCGIRestAtomServer -> fork_and_return_ua(
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

# if socket doesn't exist at this point, we bail
plan skip_all => 'Unable to create fastcgi server' unless $UA;

plan tests => 4;

ok( $UA, 'we have a user agent' );

my $req = HTTP::Request -> new(GET => "http://localhost:$PORT/");
my $resp = $UA -> request($req);

ok( $resp -> is_success );

$req = HTTP::Request -> new(GET => "http://localhost:$PORT/foo/");
$resp = $UA -> request($req);

ok( $resp -> is_success );
is( $resp -> header('Content-Type'), 'application/atom+xml' );
