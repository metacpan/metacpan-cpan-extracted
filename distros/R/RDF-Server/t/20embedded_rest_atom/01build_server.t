use Test::More; # tests => 18;

BEGIN { 
    if(not not eval "require RDF::Core") {
        plan tests => 20;
    }
    else {
        plan skip_all => 'RDF::Core required';
    }

    use_ok 'RDF::Server';
    use_ok 'RDF::Server::Types';
    use_ok 'RDF::Server::Semantic::Atom';
};

use RDF::Server::Types qw( Protocol Interface Semantic Container );
eval "use Carp::Always"; # for those who don't have it

my $e;

eval {
    package My::Server;

    use RDF::Server;

    protocol 'Embedded';
    interface 'REST';
    semantic '+RDF::Server::Semantic::Atom';

    render xml => 'Atom';

    eval {
        render foo => 'Foo';
    };

    main::isnt( $@, '', 'Bad formatter package causes an error' );
};

$e = $@;
is( $e, '', 'No error creating test package' );

ok( is_Protocol( 'My::Server' ), 'Protocol is set' );
ok( is_Interface( 'My::Server' ), 'Interface is set' );
ok( is_Semantic( 'My::Server' ), 'Semantic is set' );

ok( My::Server -> does( 'RDF::Server::Protocol::Embedded' ), 'Protocol is Embedded' );
ok( My::Server -> does( 'RDF::Server::Interface::REST' ), 'Interface is REST' );

ok( My::Server -> does( 'RDF::Server::Semantic::Atom' ), 'Semantic is Atom' );

ok( My::Server -> meta -> get_attribute('handler') -> should_coerce(), 'handler should coerce');
ok( My::Server -> meta -> get_attribute('handler') -> type_constraint -> has_coercion(), 'handler type has coercion');

my $server;

eval {
    $server = My::Server -> new(
        default_renderer => 'Atom',
        handler => [ workspace => {
            title => 'title',
            collections => [
              {
                  title => 'title',
                  categories => [ ],
                  model => {
                      class => 'RDFCore',
                      namespace => 'http://www.example.org/ns/'
                  }
              }
            ]
        } ]
    );
};

$e = $@;

is( $e, '', 'No error creating server instance' ); 

isa_ok( $server -> handler, 'RDF::Server::Semantic::Atom::Workspace', 'top-level handler');

isa_ok( $server -> handler -> handlers -> (), 'ARRAY');

isa_ok( $server -> handler -> handlers -> () -> [0], 'RDF::Server::Semantic::Atom::Collection');

isa_ok( $server -> handler -> handlers -> () -> [0] -> model, 'RDF::Server::Model::RDFCore' );

eval {
    $server = My::Server -> new(
        handler => [ collaboration => {
            title => 'title'
        }]
    );
};

$e = $@;

isnt( $e, '' );
like( $e, qr{^Unknown Atom \(.*?\) document type: collaboration}, "Got the right kind of error message" );
