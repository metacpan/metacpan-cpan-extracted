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

  plan tests => 12;
}

use t::lib::HTTPRestAtomServer;
eval "use Carp::Always"; # for those who don't have it

use RDF::Server::Constants qw( ATOM_NS );

my $PORT = 2080;

my $UA = HTTPRestAtomServer -> fork_and_return_ua(
    port => $PORT,
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

my $req = HTTP::Request -> new(POST => "http://localhost:$PORT/");
$req -> content(<<eoATOM);
<?xml version="1.0" ?>
<atom:entry xmlns:atom="@{[ATOM_NS]}">
  <atom:title>First Item</atom:title>
  <atom:content type="application/rdf+xml">
  </atom:content>
</atom:entry>
eoATOM
my $resp = $UA -> request($req);

ok( $resp -> is_success );
is( $resp -> code, 201 );

my $loc = $resp -> header('Location');

$loc =~ s{www.example.com}{localhost:$PORT};

SKIP: {
    skip "JSON::Any required for JSON tests", 2
        unless not not eval "require JSON::Any";

    $req = HTTP::Request -> new(GET => "$loc.json");
    my $jresp = $UA -> request( $req );

    is( $jresp -> code, 200 );
    is( $jresp -> header('Content-Type'), 'application/json' );
}

$req = HTTP::Request -> new(GET => "$loc.rdf");
my $rresp = $UA -> request( $req );

is( $rresp -> code, 200 );
is( $rresp -> header('Content-Type'), 'application/rdf+xml' );

$req = HTTP::Request -> new(PUT => "http://localhost:$PORT/");
$req -> content(<<eoATOM);
<?xml version="1.0" ?>
<atom:entry xmlns:atom="@{[ATOM_NS]}">
  <atom:title>First Item</atom:title>
  <atom:content type="application/rdf+xml">
  </atom:content>
</atom:entry>
eoATOM
$resp = $UA -> request($req);

ok( !$resp -> is_success );

is( $resp -> code, 405 );

$req = HTTP::Request -> new(POST => "http://localhost:$PORT/foo/");
$req -> content(<<eoATOM);
<?xml version="1.0" ?>
<atom:entry xmlns:atom="@{[ATOM_NS]}">
  <atom:title>First Item</atom:title>
  <atom:content type="application/rdf+xml">
  </atom:content>
</atom:entry>
eoATOM
$resp = $UA -> request($req);

ok( $resp -> is_success );

is( $resp -> code, 201 );

$loc = $resp -> header('Location');

my $loc2 = $loc;

$loc =~ s{www.example.com}{localhost:$PORT/foo};
$loc2 =~ s{www.example.com}{localhost:$PORT};

$req = HTTP::Request -> new(GET => $loc2);
$resp = $UA -> request( $req );

is( $resp -> code, 200 );

#diag $resp -> content;

$req = HTTP::Request -> new(GET => $loc);
$resp = $UA -> request( $req );

is( $resp -> code, 200 );
