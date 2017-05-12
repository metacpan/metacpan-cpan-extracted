BEGIN {
    use Test::More;

    eval "use RDF::Core::Model";
    plan skip_all => 'RDF::Core required' if $@;

    plan tests => 65;

    use_ok('RDF::Server::Resource::RDFCore');

    eval { require RDF::Server::Model::RDFCore; };
}

use RDF::Core::Parser;
use RDF::Server::Constants qw( :ns );
use MooseX::Types::Moose qw( ArrayRef );
eval "use Carp::Always"; # for those who don't have it

my $model = RDF::Server::Model::RDFCore -> new(
    namespace => 'http://example.com/ns/'
);

###
# test _triple
###

my $r = RDF::Server::Resource::RDFCore -> _triple(
    subject_ns => $model -> namespace,
    subject_name => 'foo',
    subject_uri => $model -> namespace . 'foo',
    predicate_ns => RDF_NS,
    predicate_name => 'type',
    object_literal => 'Bag',
    object_lang => 'en',
);

isa_ok( $r, 'RDF::Core::Statement' );

isa_ok( $r -> getSubject, 'RDF::Core::Resource' );
is( $r -> getSubject -> getNamespace, $model -> namespace );
is( $r -> getSubject -> getLocalValue, 'foo' );
isa_ok( $r -> getPredicate, 'RDF::Core::Resource' );
is( $r -> getPredicate -> getNamespace, RDF_NS );
is( $r -> getPredicate -> getLocalValue, 'type' );
isa_ok( $r -> getObject, 'RDF::Core::Literal' );
is( $r -> getObject -> getValue, 'Bag' );

$r = RDF::Server::Resource::RDFCore -> _triple(
    subject_uri => $model -> namespace . 'foo',
    predicate_uri => join('', RDF_NS, 'type'),
    object_ns => RDF_NS,
    object_name => 'Bag'
);

isa_ok( $r -> getSubject, 'RDF::Core::Resource' );
is( $r -> getSubject -> getNamespace, $model -> namespace );
is( $r -> getSubject -> getLocalValue, 'foo' );
isa_ok( $r -> getPredicate, 'RDF::Core::Resource' );
is( $r -> getPredicate -> getNamespace, RDF_NS );
is( $r -> getPredicate -> getLocalValue, 'type' );
isa_ok( $r -> getObject, 'RDF::Core::Resource' );
is( $r -> getObject -> getNamespace, RDF_NS );
is( $r -> getObject -> getLocalValue, 'Bag' );

###
# load model with some stuff
###

my $parser = RDF::Core::Parser -> new(
    Assert => sub {
        my $stmt = RDF::Server::Resource::RDFCore -> _triple(@_);
        $model -> store -> addStmt( $stmt );
    },
    BaseURI => $model -> namespace
);

$parser -> parse(<<eoRDF);
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
</rdf:RDF>
eoRDF

###
# pull out a resource
###

my $resource = $model -> resource([ $model -> namespace, 'foo' ]);

is( $resource -> id, 'foo', 'id is foo');

ok( $resource -> exists, 'resource exists');

###
# test private methods
###

$r = $resource -> _resource( 'foo', 'bar' );

isa_ok( $r, 'RDF::Core::Resource' );

is( $r -> getNamespace, 'foo' );
is( $r -> getLocalValue, 'bar' );
is( $r -> getURI, 'foobar' );

ok( $resource -> _is_local_subject( '_:' . $resource -> bnode_prefix . '23' ), '_:bnode_prefix... is local' );
ok( $resource -> _is_local_subject( $model -> namespace . '2985' ), 'namespacefoo is local' );

my $subjects = $resource -> _get_subjects( $resource -> _resource( $model -> namespace, $resource -> id ) );

is( scalar( keys %$subjects ), 1, 'Should only be one subject');

my $sub_added = $resource -> _add_subject(<<eoRDF);
<rdf:RDF xmlns:rdf="@{[RDF_NS]}">
  <rdf:Description></rdf:Description>
</rdf:RDF>
eoRDF

is( $sub_added, qq{<rdf:RDF xmlns:rdf="@{[RDF_NS]}">
  <rdf:Description rdf:about="@{[$model -> namespace]}@{[$resource -> id]}"></rdf:Description>
</rdf:RDF>}, "subject added" );

my $rdf;

eval {
    $rdf = $resource -> fetch;
};

is( $@, '', 'fetched resource content');

my $xml = XML::Simple::XMLin($rdf, NSExpand => 1);

is( $xml->{"{@{[RDF_NS]}}Description"}->{"{@{[RDF_NS]}}about"}, 'foo' );
is( $xml->{"{@{[RDF_NS]}}Description"}->{"{@{[$model -> namespace]}}title"}, "Foo's Title" );

my $data;

eval {
    $data = $resource -> data;
};

is( $@, '', 'fetched resource data');

is( $data->{"{@{[RDF_NS]}}about"}, 'foo' );
is( $data->{"{@{[$model -> namespace]}}title"}, "Foo's Title" );

###
# create a resource
###

my $new_r = $model -> resource([ $model -> namespace, 'baz' ]);

is( $new_r -> id, 'baz', 'id is baz' );

ok( !$new_r -> exists, "resource doesn't exist" );

eval {
$new_r -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>   
  <rdf:Description>
    <x:title>Baz's Title</x:title>
  </rdf:Description>
</rdf:RDF>
eoRDF
};

is( $@, '', 'updated without errors');

ok( $new_r -> exists, "resource now exists" );

is( $new_r -> data -> {'{http://example.com/ns/}title'}, "Baz's Title" );

###
# modify a resource
###

eval {
$new_r -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description>
    <x:title>Baz's Second Title</x:title>
  </rdf:Description>
</rdf:RDF>
eoRDF
};

is( $@, '', 'update without problems' );

my $titles = $new_r -> data -> {'{http://example.com/ns/}title'};

#use Data::Dumper;
#diag(Data::Dumper->Dump([$new_r -> data]));

ok( is_ArrayRef( $titles ), 'array reference of titles' );
ok( is_ArrayRef( $titles ) && @$titles == 2, '2 titles' );

###
# deletion of part of a resource
###

eval {
$new_r -> purge(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description>
    <x:title>Baz's Second Title</x:title>
  </rdf:Description>
</rdf:RDF>
eoRDF
};

is( $@, '', 'purge without problems' );

$titles = $new_r -> data -> {'{http://example.com/ns/}title'};

is( $titles, "Baz's Title", "one title left" );

ok( $new_r -> has_triple( undef, [ 'http://example.com/ns/', 'title' ], "Baz's Title" ) );

###
# Add a bag
###

eval {
$new_r -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>  
  <rdf:Description>
    <x:stuff>
      <rdf:Description>
       <rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag"/>

      <!-- rdf:Bag -->
        <rdf:li>Item 1</rdf:li>
        <rdf:li>Item 2</rdf:li>
        <rdf:li>Item 3</rdf:li>
      </rdf:Description>
    </x:stuff>
  </rdf:Description>
</rdf:RDF>
eoRDF
};

my $bag = $new_r -> data -> {'{http://example.com/ns/}stuff'};

is( scalar(keys %$bag), 1, 'one key in stuff');

is( [ keys %$bag ] -> [0], "{@{[RDF_NS]}}Bag", "right key");

ok( is_ArrayRef( $bag -> {"{@{[RDF_NS]}}Bag"} ), "bag is array ref");

is( scalar( @{ $bag -> {"{@{[RDF_NS]}}Bag"} } ), 3, "three items in bag");
#diag $new_r -> fetch;

#use Data::Dumper;
#diag(Data::Dumper -> Dump([ $new_r -> data ]));

###
# add item to bag
###

$new_r -> update(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description>
    <x:stuff>
      <rdf:Bag>
        <rdf:li>Item 4</rdf:li>
      </rdf:Bag>
    </x:stuff>
  </rdf:Description>
</rdf:RDF>
eoRDF

$bag = $new_r -> data -> {'{http://example.com/ns/}stuff'};

is( scalar(keys %$bag), 1, 'one key in stuff');

is( [ keys %$bag ] -> [0], "{@{[RDF_NS]}}Bag", "right key");

ok( is_ArrayRef( $bag -> {"{@{[RDF_NS]}}Bag"} ), "bag is array ref");

is( scalar( @{ $bag -> {"{@{[RDF_NS]}}Bag"} } ), 4, "four items in bag");

my $old_rdf = $new_r -> fetch;

eval {
    $new_r -> update('');
};

is( $@, '', "empty update doesn't error");

is( $old_rdf, $new_r -> fetch, 'empty update makes no changes');

#diag $new_r -> fetch;

###
# remove item from bag
###

eval {
$new_r -> purge(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
>
  <rdf:Description>
    <x:stuff>
      <!-- rdf:Bag -->
<rdf:Description>
 <rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag"/>

        <rdf:li>Item 2</rdf:li>
      </rdf:Description>
    </x:stuff>
  </rdf:Description>
</rdf:RDF>
eoRDF
};

is( $@, '', 'purge ran');

$bag = $new_r -> data -> {'{http://example.com/ns/}stuff'};
    
is( scalar(keys %$bag), 1, 'one key in stuff');
  
is( [ keys %$bag ] -> [0], "{@{[RDF_NS]}}Bag", "right key");

ok( is_ArrayRef( $bag -> {"{@{[RDF_NS]}}Bag"} ), "bag is array ref");

is( scalar( @{ $bag -> {"{@{[RDF_NS]}}Bag"} } ), 3, "three items in bag");

is( scalar( grep { $_ eq 'Item 2' } @{$bag -> {"{@{[RDF_NS]}}Bag"}} ), 0, 'correct item was removed' );

###
# removal of a bag should delete the bag
###

$new_r -> purge(<<eoRDF);
<?xml version="1.0" ?>
<rdf:RDF xmlns:rdf="@{[ RDF_NS ]}"
         xmlns:x="http://example.com/ns/"
> 
  <rdf:Description>
    <x:stuff>
      <rdf:Bag>
        <rdf:li>Item 1</rdf:li>
        <rdf:li>Item 3</rdf:li>
        <rdf:li>Item 4</rdf:li>
      </rdf:Bag>
    </x:stuff>
  </rdf:Description>
</rdf:RDF>
eoRDF

$bag = $new_r -> data -> {'{http://example.com/ns/}stuff'};

is( scalar(keys %$bag), 0, 'nothing in stuff');

###
# complete removal of resource
###

$new_r -> update(<<eoRDF);
<?xml version="1.0" ?>
<RDF xmlns="@{[ RDF_NS ]}"
     xmlns:x="http://example.com/ns/"
> 
  <Description>
    <x:stuff>
      <Bag>
        <li>Item 1</li>
        <li>Item 3</li>
        <li>Item 4</li>
      </Bag>
    </x:stuff>
  </Description>
</RDF>
eoRDF
eval {
    $new_r -> delete;
};

is( $@, '', 'deletion ran');

ok( !$new_r -> exists, 'resource no longer exists');
