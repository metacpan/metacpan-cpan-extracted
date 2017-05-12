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

use RDF::Server::Constants qw( ATOM_NS );

my $PORT = 2090;

my $UA = FCGIRestAtomServer -> fork_and_return_ua(
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

# if socket doesn't exist at this point, we bail
plan skip_all => 'Unable to create fastcgi server' unless $UA;

plan tests => 12;


#diag "Pid: $$";
my $req = HTTP::Request -> new(POST => "http://localhost:$PORT/");
$req -> content(<<eoATOM);
<?xml version="1.0" ?>
<atom:entry xmlns:atom="@{[ATOM_NS]}">
  <atom:title>First Item</atom:title>
  <atom:content type="application/rdf+xml">
  </atom:content>
</atom:entry>
eoATOM
$req -> header('Content-Type' => 'application/atom+xml');
#diag $req -> as_string;
my $resp = $UA -> request($req);

#diag $resp -> as_string;

ok( $resp -> is_success, 'POST /' );
is( $resp -> code, 201, 'POST /' );

my $loc = $resp -> header('Location');

$loc =~ s{www.example.com}{localhost:$PORT};

SKIP: {
    skip "JSON::Any required for JSON tests", 2 
        unless not not eval "require JSON::Any";

    $req = HTTP::Request -> new(GET => "$loc.json");
    my $jresp = $UA -> request( $req );

    is( $jresp -> code, 200, "GET $loc.json");
    is( $jresp -> header('Content-Type'), 'application/json' );
}

$req = HTTP::Request -> new(GET => "$loc.rdf");
my $rresp = $UA -> request( $req );

is( $rresp -> code, 200, "GET $loc.rdf" );
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

ok( !$resp -> is_success, "PUT / (shouldn't work)" );

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

ok( $resp -> is_success, "POST /foo/" );

is( $resp -> code, 201 );

$loc = $resp -> header('Location');

my $loc2 = $loc;

$loc =~ s{www.example.com}{localhost:$PORT/foo};
$loc2 =~ s{www.example.com}{localhost:$PORT};

$req = HTTP::Request -> new(GET => $loc2);
$resp = $UA -> request( $req );

is( $resp -> code, 200, "GET $loc2" );

#diag $resp -> content;

$req = HTTP::Request -> new(GET => $loc);
$resp = $UA -> request( $req );

is( $resp -> code, 200, "GET $loc" );
