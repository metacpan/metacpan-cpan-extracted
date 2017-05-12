use constant TESTS => 11;

use Test::More;
use HTTP::Response;
use HTTP::Request;

use RDF::Server::Constants qw( :ns );
eval "use Carp::Always"; # for those who don't have it

BEGIN {
    if(not eval "require RDF::Core") {
        plan skip_all => 'RDF::Core required';
    }

    eval {
        use RDF::Server;
        use RDF::Server::Semantic::Atom;
        use RDF::Server::Types qw( Protocol Interface Semantic Container );
    };
    if($@) {
        plan skip_all => "Required modules don't compile";
    }
    else {
        plan tests => TESTS;
    }
}

my $e;

BEGIN {

eval {
    package My::Server;

    use RDF::Server;

    protocol 'Embedded';
    interface 'REST';
    semantic 'Atom';

    render xml => 'Atom';
    render [qw(rdf rss)] => 'RDF';
};

$e = $@;
is( $e, '', 'No error creating test package' );
}

my $server;

eval {
    $server = My::Server -> new(
        default_renderer => 'Atom',
        handler => [ service => {
            path_prefix => '/',
            workspaces => [
            {
                title => 'Workspace',
                collections => [
                  {
                      title => 'All of Foo',
                      path_prefix => 'foo/',
                      categories => [
                          {
                              term => 'digital',
                              scheme => 'http://example.org/categories/'
                          },
                          {
                              term => 'humanities',
                              scheme => 'http://example.org/categories/'
                          }
                      ],
                      model => {
                          namespace => 'http://www.example.org/foo/',
                          class => 'RDFCore'
                      }
                  }
                ]
            } 
            ]
        } ],
    );
};

$e = $@;

is( $e, '', 'No error creating server instance' ); 

# now we want to handle some requests

$request = HTTP::Request -> new( POST => '/foo/' );
$request -> content(<<eoATOM);
<?xml version="1.0"?>
<entry xmlns="@{[ ATOM_NS ]}"
       xmlns:rdf="@{[ RDF_NS ]}"
       xmlns:x="http://www.example.com/ns/x"
>
  <title>Atom-Powered Robots Run Amok</title>
  <content type="application/rdf+xml"><!-- becomes rdf:Description -->
    <x:title>Foo</x:title>
  </content>
</entry>
eoATOM

$response = new HTTP::Response;

eval {
    $server -> handle_request( $request, $response );
};

$e = $@;

is( $e, '', 'Request made');

isa_ok( $response, 'HTTP::Response' );

my $returned_content;
SKIP: {
   skip 'request not successful', 2 unless $response -> is_success;

   is( $response -> code, 201, 'HTTP CREATED status' );

   isnt( $response -> header('Location'), '', 'Location returned' );

   $returned_content = $response -> content;
}

$request = HTTP::Request -> new( GET => $response -> header('Location') );

$response = new HTTP::Response;

eval {
    $server -> handle_request( $request, $response );
};
    
$e = $@;
        
is( $e, '', 'Request made');   
            
isa_ok( $response, 'HTTP::Response' );
                
SKIP: {
   skip 'request not successful', 2 unless $response -> is_success;
                      
   is( $response -> code, 200, 'HTTP OK status' );

   is( $response -> content, $returned_content, 'Result the same as when created');
}

($location, $content) = $server -> create( '/foo/', <<eoATOM );
<?xml version="1.0"?>
<entry xmlns="@{[ ATOM_NS ]}"
       xmlns:rdf="@{[ RDF_NS ]}"
       xmlns:x="http://www.example.com/ns/x"
>
  <title>Atom-Powered Robots Run Amok</title>
  <content type="application/rdf+xml"><!-- becomes rdf:Description -->
    <x:title>Foo</x:title>
  </content>
</entry>
eoATOM

is( $content, $server -> fetch( $location ), "create returned proper content" );
