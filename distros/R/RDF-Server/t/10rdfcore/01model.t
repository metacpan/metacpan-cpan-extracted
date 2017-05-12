BEGIN {
    use Test::More;

    eval "use RDF::Core::Model";
    plan skip_all => 'RDF::Core required' if $@;

    plan tests => 34;

    use_ok('RDF::Server::Model::RDFCore');
}

use MooseX::Types::Moose qw( ArrayRef );
use RDF::Server::Constants qw( ATOM_NS RDF_NS );
eval "use Carp::Always"; # for those who don't have it

my $model;

eval {
    $model = RDF::Server::Model::RDFCore -> new(
        namespace => 'http://example.com/ns/'
    );
};

is( $@, '', 'Model object created');

is( $model -> namespace, 'http://example.com/ns/', 'namespace set' );

isa_ok( $model -> store, 'RDF::Core::Model' );

###
# get_value
###

is( $model -> get_value, undef, 'get_value returns undef' );

###
# _make_resource
###

my $r = $model -> _make_resource( 'http://example.com/ns/foo' );

isa_ok( $r, 'RDF::Core::Resource' );



$r = $model -> _make_resource( [ $model -> namespace, 'foo' ] );

isa_ok( $r, 'RDF::Core::Resource' );


###
# load model with some stuff
###

use RDF::Server::Constants qw( :ns );

$model -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description rdf:about="http://example.com/ns/foo">
    <x:title>Foo's Title</x:title>
  </rdf:Description>

  <rdf:Description rdf:about="http://example.com/ns/bar">
    <x:title>Bar's Title</x:title>
  </rdf:Description>

  <rdf:Description rdf:about="http://www.example.com/ns2/0956">
    <x:title>Something for 0956</x:title>
  </rdf:Description>
</rdf:RDF>
eoRDF

my $data = $model -> data;
ok( is_ArrayRef( $data ) );
is( scalar( @$data ), 3, "three entries in model" );

###
# has_triple
###

ok( $model -> has_triple( 
       [ $model -> namespace, 'foo' ],
       [ $model -> namespace, 'title' ],
       "Foo's Title"
    )
);

###
# resource_exists
###

ok(  $model -> resource_exists( $model -> namespace, 'foo' ) );
ok(  $model -> resource_exists( $model -> namespace, 'bar' ) );
ok( !$model -> resource_exists( $model -> namespace, 'baz' ) );
ok( !$model -> resource_exists( $model -> namespace, 'title' ) );

###
# resource
###

isa_ok( $model -> resource( $model -> namespace, 'foo' ), 'RDF::Server::Resource::RDFCore' );

###
# resources
###

my $iter = $model -> resources;

# should be a list of Resources
use Iterator::Simple qw( list is_iterator );

ok( is_iterator($iter), 'resources returns an iterator' );

my @resources = @{ list $iter };
is( scalar(@resources), 2, 'Two resources' );

isa_ok( $resources[0], 'RDF::Server::Resource::RDFCore' );
isa_ok( $resources[1], 'RDF::Server::Resource::RDFCore' );

my $ids = join ':::', sort map { $_ -> id } @resources;

is( $ids, 'bar:::foo', 'Resource ids are right' );

$iter = $model -> resources('http://www.example.com/ns2/');

ok( is_iterator($iter), 'resources($ns) returns an iterator' );

@resources = @{ list $iter };
is( scalar(@resources), 1, 'One resource' );

$ids = join ':::', sort map { $_ -> id } @resources;

is( $ids, '0956', 'Resource ids are right' );

$iter = $model -> resources('');

ok( is_iterator($iter), "resources('') returns an iterator" );

@resources = @{ list $iter };

is( scalar( @resources ), 3, 'Three resources' );


###
# add_triple
###

# the following should all result in the triple *not* being added
eval { $model -> add_triple( undef, undef, undef ); };
is( $@, '', "trying to add undef triple doesn't cause an error" );

eval { $model -> add_triple( [ $model -> namespace, 'foo' ], undef, undef ); };

is( $@, '', "trying to add undef triple doesn't cause an error" );

eval { $model -> add_triple( [ $model -> namespace, 'foo' ], [ ATOM_NS, 'title' ], undef ); };
is( $@, '', "trying to add undef triple doesn't cause an error" );


$model -> add_triple(
    RDF::Core::Resource -> new( $model -> namespace, 'foo' ),
    RDF::Core::Resource -> new( ATOM_NS, 'title' ),
    RDF::Core::Literal -> new( 'An Atomic Title' )
);

ok( $model -> store -> existsStmt(
    RDF::Core::Resource -> new( $model -> namespace, 'foo' ),
    RDF::Core::Resource -> new( ATOM_NS, 'title' ),
    RDF::Core::Literal -> new( 'An Atomic Title' )
), 'Adding triple using RDF::Core objects works' );

ok( $model -> has_triple( [ $model -> namespace, 'foo' ], [ ATOM_NS, 'title' ], 'An Atomic Title' ) );

###
# purge
###

$model -> purge(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:atom="@{[ ATOM_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description rdf:about="http://example.com/ns/foo">
    <x:title>Foo's Title</x:title>
    <atom:title>An Atomic Title</atom:title>
  </rdf:Description>
</rdf:RDF>
eoRDF

$iter = $model -> resources;

@resources = @{ list $iter };

is( scalar(@resources), 1, 'Only one resource');

is( $resources[0] -> id, 'bar', 'Bar is the remaining resource');

ok( !$model -> resource_exists( $model -> namespace, 'foo' ) );  

###
# delete
###

$model -> delete;

$iter = $model -> resources('');

@resources = @{ list $iter };

is( scalar(@resources), 0, 'Model is empty after delete' );
