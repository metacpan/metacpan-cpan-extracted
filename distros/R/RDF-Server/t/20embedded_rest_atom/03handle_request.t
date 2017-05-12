use constant TESTS => 15;

use Test::More;
use HTTP::Response;
use HTTP::Request;

eval "use Carp::Always"; # for those who don't have it

my( %service_path_tests, %service_path_counts, $has_xml_path );
my( %collection_path_tests, %collection_path_counts );


BEGIN {
    if(not eval "require RDF::Core") {
        plan skip_all => 'RDF::Core required';
    }

    $has_xml_xpath = not not eval { require XML::XPath; };

    %service_path_tests = (
        '/app:service/app:workspace/atom:title' => 'Workspace',
        '/app:service/app:workspace/app:collection/atom:title' => 'All of Foo',
        '/app:service/app:workspace/app:collection/@href' => '/baz/foo/',
    );

    %service_path_counts = (
        '/app:service/app:workspace' => 1,
        '/app:service/app:workspace/app:collection' => 1,
        '/app:service/app:workspace/app:collection/app:categories' => 1,
        '/app:service/app:workspace/app:collection/app:categories/atom:category' => 2,
    );

    %collection_path_tests = (
        '/app:collection/atom:title' => $service_path_tests{'/app:service/app:workspace/app:collection/atom:title'},
    );

    %collection_path_counts = (
        '/app:collection/app:categories/atom:category[@term="digital"]' => 1,
        '/app:collection/app:categories/atom:category[@term="humanities"]' => 1,
    );

    eval {
        use RDF::Server;
        use RDF::Server::Semantic::Atom;
        use RDF::Server::Types qw( Protocol Interface Semantic Container );
        use RDF::Server::Constants qw( :ns );
    };
    if($@) {
        plan skip_all => "Required modules don't compile";
    }
    else {
        plan tests => TESTS + ($has_xml_xpath ? ( keys( %service_path_tests ) + keys( %service_path_counts ) + keys( %collection_path_tests ) + keys( %collection_path_counts ) ) : 0 );
    }

    
}

diag "\nInstall XML::XPath to run more detailed tests\n\n" unless $has_xml_xpath;

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
                path_prefix => 'baz/',
                title => $service_path_tests{'/app:service/app:workspace/atom:title'},
                collections => [
                  {
                      title => $service_path_tests{'/app:service/app:workspace/app:collection/atom:title'},
                      path_prefix => '/foo/',
                      categories => [
                          {
                              term => 'digital',
                              scheme => 'http://example.org/categories/'
                          },
                          {
                              term => 'humanities',
                              scheme => 'http://example.org/categories/'
                          },
                      ],
                      model => {
                          class => 'RDFCore',
                          namespace => 'http://www.example.org/ns/',
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

my $response = new HTTP::Response;
my $request = HTTP::Request -> new( GET => '/' );

eval {
    $server -> handle_request( $request, $response );
};

$e = $@;

is( $e, '', 'Request made');

isa_ok( $response, 'HTTP::Response' );

SKIP: {
    skip 'request not successful', (
         ($has_xml_xpath ? keys( %service_path_tests ) + keys( %service_path_counts ) + 1
                         : 0 ) + 2
    ) unless $response -> is_success;

    is( $response -> code, 200, 'HTTP OK status' );

    #diag $response -> content;

    is( $response -> content, $server -> fetch( '/' ), "protocol and interface give identical content" );

    if( $has_xml_xpath ) {
        do_xpath_tests(
            $response -> content,
            \%service_path_tests,
            \%service_path_counts
        );
    }
}

$request = HTTP::Request -> new( GET => '/baz/' );
$response = new HTTP::Response;

eval {
   $server -> handle_request( $request, $response );
};
                          
$e = $@;
                       
is( $e, '', 'Request made');
                 
isa_ok( $response, 'HTTP::Response' );

ok( $response -> is_success, "Workspace successfully requested" );

is( $response -> content, $server -> fetch( '/baz/' ), "protocol and interface give identical content" );

$request = HTTP::Request -> new( GET => '/baz/foo/' );
$response = new HTTP::Response;

eval {
    $server -> handle_request( $request, $response );
};

$e = $@;

is( $e, '', 'Request made');

isa_ok( $response, 'HTTP::Response' );

SKIP: {
   skip 'request not successful', (
         ($has_xml_xpath ? keys( %collection_path_tests ) + keys( %collection_path_counts ) + 1
                         : 0 ) + 1
   ) unless $response -> is_success;

   is( $response -> code, 200, 'HTTP OK status' );

   #diag $response -> content;

    if( $has_xml_xpath ) {
        do_xpath_tests(
            $response -> content,
            \%collection_path_tests,
            \%collection_path_counts
        );
    }
}

is( $server -> default_renderer, 'Atom');
is( $server -> formatter, 'RDF::Server::Formatter::Atom');

sub do_xpath_tests {
    my( $xml, $paths, $counts ) = @_;

    my $doc = XML::XPath -> new( xml => $xml );
    $doc -> set_namespace( app => APP_NS );
    $doc -> set_namespace( atom => ATOM_NS );
                              
    foreach my $path ( sort keys %$counts ) {
        is( scalar(@{ [ $doc -> findnodes($path) ] }), $counts -> {$path}, "count($path) == $counts->{$path}");
    }
    foreach my $path ( sort keys %$paths ) {
        is( $doc -> getNodeText($path), $paths -> {$path}, "$path eq $paths->{$path}" );
    }
}
