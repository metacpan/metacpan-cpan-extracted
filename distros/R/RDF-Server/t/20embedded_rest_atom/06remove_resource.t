use constant TESTS => 10;

use Test::More;
use HTTP::Response;
use HTTP::Request;

use RDF::Server::Constants qw( :ns );
eval "use Carp::Always"; # for those who don't have it

my $has_xml_xpath;

BEGIN {
    if(not eval "require RDF::Core") {
        plan skip_all => 'RDF::Core required';
    }

    $has_xml_xpath = not not eval { require XML::XPath; };

    %path_tests = (
        '/atom:entry/atom:content/x:foo' => 'Bar',
    );
        
    eval {
        use RDF::Server;
        use RDF::Server::Semantic::Atom;
        use RDF::Server::Types qw( Protocol Interface Semantic Container );
    };
    if($@) {
        plan skip_all => "Required modules don't compile";
    }
    else {
        plan tests => TESTS + 
             ( $has_xml_xpath ? ( 2* keys(%path_tests) ) : 0 )
        ;
    }
}

my $e;

eval {
    package My::Server;

    use RDF::Server;

    protocol 'Embedded';
    interface 'REST';
    semantic 'Atom';

    render xml => 'Atom';
};

$e = $@;
is( $e, '', 'No error creating test package' );

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
       xmlns:x="http://www.example.com/ns/x#"
>
  <title>Atom-Powered Robots Run Amok</title>
  <content type="application/rdf+xml"><!-- becomes rdf:Description -->
    <x:title>Foo</x:title>
    <x:foo>Bar</x:foo>
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
unless( $response -> is_success ) {
    diag $response -> content;
}

SKIP: {
    skip 'request not successful', 1 + ($has_xml_xpath ? 0+keys(%path_tests) : 0) unless $response -> is_success;

    is( $response -> code, 201, 'HTTP CREATED status' );

    isnt( $response -> header('Location'), '', 'Location returned' );

    if( $has_xml_xpath ) {
        do_xpath_tests(
            $response -> content,
            \%path_tests,
            { }
        );
    }
}

my $location = $response -> header('Location');

$request = HTTP::Request -> new( DELETE => $location );
$request -> content(<<eoATOM);
<?xml version="1.0"?>
<entry xmlns="@{[ ATOM_NS ]}"
       xmlns:rdf="@{[ RDF_NS ]}"
       xmlns:x="http://www.example.com/ns/x#"
>
  <content type="application/rdf+xml">
    <x:foo>Bar</x:foo>
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
                
unless( $response -> is_success ) {
    diag $response -> content;
}

SKIP: {
    skip 'request not successful', 1 + ($has_xml_xpath ? 0+keys(%path_tests) : 0) unless $response -> is_success;
                      
    is( $response -> code, 200, 'HTTP OK status' );

#   diag $response -> content;
    if( $has_xml_xpath ) {
        do_xpath_tests(
            $response -> content,
            \%path_tests,
            { },
            1
        );
    }

}

$server -> delete( $location );
#$request = HTTP::Request -> new( DELETE => $location );
#$response = new HTTP::Response;
#
#eval {
#    $server -> handle_request( $request, $response );
#};
#
#$e = $@;
#
#is( $e, '', 'Request made');
#
#isa_ok( $response, 'HTTP::Response' );
#ok( $response -> is_success, "request succeeded");
#is( $response -> code, 200, 'HTTP OK status');

$request = HTTP::Request -> new( GET => $location );
$response = new HTTP::Response;

eval {
    $server -> handle_request( $request, $response );
};

$e = $@;

isa_ok( $e, 'RDF::Server::Exception::NotFound', 'Request made');

sub do_xpath_tests {
    my( $xml, $paths, $counts, $negate ) = @_;
    
    my $doc = XML::XPath -> new( xml => $xml );
    $doc -> set_namespace( app => APP_NS );
    $doc -> set_namespace( atom => ATOM_NS );
    $doc -> set_namespace( dc => DC_NS );
    $doc -> set_namespace( rdf => RDF_NS );
    $doc -> set_namespace( x => "http://www.example.com/ns/x#" );
        
    if( $negate ) {
        foreach my $path ( sort keys %$counts ) {
            isnt( scalar(@{ [ $doc -> findnodes($path) ] }), $counts -> {$path}, "count($path) != $counts->{$path}");
        }
        foreach my $path ( sort keys %$paths ) {
            isnt( $doc -> getNodeText($path), $paths -> {$path}, "$path ne $paths->{$path}" );
        }
    }
    else {
        foreach my $path ( sort keys %$counts ) {
            is( scalar(@{ [ $doc -> findnodes($path) ] }), $counts -> {$path}, "count($path) == $counts->{$path}");
        }
        foreach my $path ( sort keys %$paths ) {
            is( $doc -> getNodeText($path), $paths -> {$path}, "$path eq $paths->{$path}" );
        }
    }
}

