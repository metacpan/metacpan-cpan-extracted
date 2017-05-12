use Test::More;
use Test::Moose;
use RDF::Server;
eval "use Carp::Always"; # for those who don't have it

##
# test things that aren't in other tests
##

if( not eval { require POE::Component::Server::HTTP } ) {
    plan skip_all => 'POE::Component::Server::HTTP required for this test';
}
else {
    plan tests => 10;
}

my $class = RDF::Server -> build_from_config(
    interface => 'REST',
    protocol => 'HTTP',
    semantic => 'Atom',
    renderers => {
        'rdf' => 'RDF',
        'atom' => 'Atom',
    },
    port => '8000',
    loglevel => 2
);

meta_ok( $class, "server class has a meta" );
ok( $class -> isa('RDF::Server'), 'server class isa RDF::Server' );
does_ok( $class, 'RDF::Server::Semantic::Atom' );
does_ok( $class, 'RDF::Server::Protocol::HTTP' );
does_ok( $class, 'RDF::Server::Interface::REST' );

has_attribute_ok( $class, 'port' );

my $server;

eval {
$server = $class -> new(
    handler => [ workspace => {
        title => 'Foo'
    } ]
);
};

is( $@, '' );

isa_ok( $server, 'RDF::Server' );

has_attribute_ok($server, 'port');

my $p = eval { $server -> port; };

if($@ =~ m{Can't locate object method "port"} && $ENV{'AUTOMATED_TESTING'} ) {
    print STDERR "AUTOMATED TESTING info:\n";
    print STDERR "  server object: $server:\n";
    print STDERR "  attributes: ", join(", ",
        #map { $_ -> name } $server -> meta -> computer_all_applicable_attributes
        $server -> meta -> get_attribute_list
    ), "\n";
}

is( $p, '8000' );
