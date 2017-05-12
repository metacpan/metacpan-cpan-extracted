# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - 2005/06/09 at 16:21 CEST
# *

package RDFStore::Object;
{
use vars qw ($VERSION $AUTOLOAD);
use strict;
use Carp;
 
$VERSION = '0.1';

use RDFStore::Resource;
use RDFStore::Model;
use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFStoreContext;
use RDFStore::Statement;

@RDFStore::Object::ISA = qw( RDFStore::Resource ); # a bit property centric API now?!?

# map symbolic namespace identifiers to real URLs which can be processed
# NOTE: hopefully this will map URIs-to-URNs via DDDS I2C (or even better if user writes urn: like xmlns declarations :)
# mime-type is not used/negotiated and an extra hash key is used instead to specify that
%RDFStore::Object::default_prefixes = (
        #'#default' => { 'namespace' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' }, #this is just handy
        'rdf' => { 'namespace' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' },
        'rdfs' => { 'namespace' => 'http://www.w3.org/2000/01/rdf-schema#' },
        'rss' => { 'namespace' => 'http://purl.org/rss/1.0/' },
        'daml' => { 'namespace' => 'http://www.daml.org/2001/03/daml+oil#' },
        'dc' => { 'namespace' => 'http://purl.org/dc/elements/1.1/' },
        'dcq' => { 'namespace' => 'http://purl.org/dc/terms/' },
        'foaf' => { 'namespace' => 'http://xmlns.com/foaf/0.1/' },
        'xsd' => { 'namespace' => 'http://www.w3.org/2001/XMLSchema#' },
        'owl' => { 'namespace' => 'http://www.w3.org/2002/07/owl#' }
	# E.g. of a real one
	# 'isc' => { 'namespace' => 'http://earth.esa.int/standards/showcase/',
	#            'URI' => 'http://demo.asemantics.com/rdformer/isc/config/isc.rdf', 
	#	     'content_type' => 'RDF/XML' }
        );

# subclass and adapt to RDFStore::Resource
sub new {
        my ($pkg, $namespace, $localname, $bnode) = @_;

	my $self={ 'prefixes' =>  {}, 'schemas' => {}, 'types' => [] };

	# set default prefixes, schemas and content_types
        map {
		my $x = $_;
                $self->{ 'prefixes' }->{ $x } = {};

		map {
                	$self->{ 'prefixes' }->{ $x }->{ $_ } = $RDFStore::Object::default_prefixes{ $x }->{ $_ };
		} keys %{ $RDFStore::Object::default_prefixes{ $x } };
        } keys %RDFStore::Object::default_prefixes;

	# if no name or QName is passed is a bNoded RDF object by office - no error like in RDFStore::Resource superclass
	if( $namespace ) {
		$self->{'rdf_object'} = $pkg->SUPER::new( $namespace, $localname, $bnode );
	} else {
		$self->{'rdf_object'} = _createbNode( $self );
		};

	bless $self, $pkg;
	};

# this is needed due we expect to have some RDFStore::ObjectFactory at some moment....
sub _createbNode {
	my ($class) = @_;

        $class->{'bnodesCounter'} = 0
		unless( exists $class->{'bnodesCounter'});
	
        $class->{'timestamp'} = time()
		unless( exists $class->{'timestamp'});

        $class->{'rand_seed'} = unpack("H*", rand())
		unless( exists $class->{'rand_seed'});

	# try to generate system/run wide unique ID i.e. 'S' + unpack("H*", rand()) + 'P' + $$ + 'T' + time() + 'N' + GenidNumber
	return new RDFStore::Resource(
			'rdf:object:genidrdfstore' .
                        'S'.$class->{'rand_seed'} .
                        'P'. $$.
                        'T'. $class->{'timestamp'} .
			'N'. $class->{bnodesCounter}++, undef, 1 );
	};

# export prefixes
sub export {
	my ($class, @prefixes) = @_;

	for my $prefix (@prefixes)  {
		croak "Can't find prefix $prefix - perhaps need to call define() method before?"
			unless(exists $class->{'prefixes'}->{ $prefix });

		no strict;
		*{"$prefix\::AUTOLOAD"} = sub {
			my $object = shift;
			(my $prop = $AUTOLOAD) =~ s/^.*:://o;
			if (ref($object)) {
				$object->set_or_get( "$prefix:$prop", @_ );
			} else {
				return "$prefix$prop";
				};
			};
		};
	};

sub getNamespace {
	return $_[0]->{'rdf_object'}->getNamespace;
	};

sub getLocalName {
	return $_[0]->{'rdf_object'}->getLocalName;
	};

sub getbNode {
	return $_[0]->{'rdf_object'}->getbNode;
	};

sub getLabel {
	return $_[0]->{'rdf_object'}->getLabel;
	};

sub getDigest {
	return $_[0]->{'rdf_object'}->getDigest;
	};

sub isbNode {
	return $_[0]->{'rdf_object'}->isAnonymous;
	};

sub getURI {
	return
		if($_[0]->{'rdf_object'}->isAnonymous); #bNodes do not have a URI

	return $_[0]->{'rdf_object'}->getLabel;
	};

sub getNodeID {
        return
                unless($_[0]->{'rdf_object'}->isAnonymous);

        return $_[0]->{'rdf_object'}->getLabel;
	};

# set the context/provenance for the RDF object
sub setDomain {
	my ($class, $context) = @_;

	$class->connect
		unless($class->isConnected);

	# NOTE: need to think/fix the context/provenance story - also because when connect to another store what happens? another context or the same with
	#       a different dc:date and dc:source? same ID? boooh....but very important especially when adding URN DDDS registration to this class :o)
	## create rdfstore:Context for this RDF object
	#$self->{'context'} = _createbNode( $self );
	#$self->{'model'}->setContext( $self->{'context'} );
	## add its triple to model
	#$self->{'model'}->add( $self->{'context'}, $RDFStore::Vocabulary::RDF::type, $RDFStore::Vocabulary::RDFStoreContext::Context );

	};

# zap any context/provenance info for the RDF object - possible!? needed???
sub resetDomain {
	};

# connect/associate an object to an RDFStore::Model
sub connect {
	my ($class, $model) = @_;

	if($model and ref($model) and $model->isa("RDFStore::Model")) {
		if(exists $class->{'model'}) {
			# copy really stuff across - !!!! these operations can be very expensive !!!!
			my $stuff = $class->{'model'}->elements;
			while ( my $st = $stuff->each ) {
				$model->add($st);
				};
			};
		$class->{'model'} = $model;
	} elsif($model) {
		$class->{'model'} = new RDFStore::Model( 'Name' => $model ); # name to physical store
	} else {
		$class->{'model'} = new RDFStore::Model
			unless(exists $class->{'model'}); # create an in-memory model unless is already there
		};

	return $class->{'model'};
	};

# dis-connect/de-associate an object from an RDFStore::Model
sub disconnect {
	my ($class) = @_;

	my $model = new RDFStore::Model; #empty in-memory

	if(exists $class->{'model'}) {
		# copy really stuff across - !!!! these operations can be very expensive !!!!
		my $stuff = $class->{'model'}->elements;
		while ( my $st = $stuff->each ) {
			$model->add($st); # note we do not clean up the previously connected store
			};
		};
	$class->{'model'} = $model;

	return $class->{'model'};
	};

sub connection {
	return $_[0]->{'model'};
	};

sub isConnected {
	return (exists $_[0]->{'model'});
	};

# tie some bNode identifed RDF object to a well-known URI
sub deanonymize {
	my ($class, $uri) = @_;

        return
                unless( $class->{'rdf_object'}->isAnonymous and (! $uri->isAnonymous ) );

	#fetch object, substitute its identifer with URI and re-ingest it...
	};

# make the object a bNode i.e. rename it to a randomize/generated rdf:nodeID
sub anonymize {
	my ($class) = @_;
	};

# define prefixes, schemas and content_type for RDF object (shouldnt' these be in RDFStore::Model then like in Jena?)
sub define {
	my ($class, %prefixes) = @_;

	# overridden ones
	map {
        	$class->{ 'prefixes' }->{ $_ } = $prefixes{ $_ };
	} %prefixes;

	# merge in passed prefixes stuff to current ones
	map {
		my $x = $_;
                $class->{ 'prefixes' }->{ $x } = {}
			unless(exists $class->{ 'prefixes' }->{ $x });

		my ($content_type, $URI);
		map {
                	$class->{ 'prefixes' }->{ $x }->{ $_ } = $prefixes{ $x }->{ $_ };
			$content_type = $prefixes{ $x }->{ $_ }
				if( $_ eq 'content_type' );
			$URI = $prefixes{ $x }->{ $_ }
				if( $_ eq 'URI' );
		} keys %{ $prefixes{ $x } };

		# now if the define is about a specific URI try to content_type parse it and keep it "cached" 
		# into prefixes hash-table (how many schemas cachable??)
		if( $URI and $content_type ) {
			my $schema;
			eval {
				$schema = new RDFStore::Model; # we could keep a pool/registry as well with context/provenance for each schema...
				$schema->setContext( $schema->getNodeFactory->createResource( $URI ) );
				my $p = $schema->getReader( $content_type );
				$p->parsefile( $URI );
				};
			if($@) {
				print STDERR $@;
				return 0;
				};
			$class->{ 'prefixes' }->{ $x }->{ 'schema' } = $schema;
			};
        	} keys %prefixes;

	return 1;
	};

# load some RDF into underlying model (not checking yet if the input triples actually relate to the RDF object)
sub load {
	my ($class, $input, $syntax) = @_;

	$class->connect
		unless($class->isConnected);

	my $parser = $class->{'model'}->getReader($syntax);

	return
		unless($parser);

	if (ref($input) and UNIVERSAL::isa($input, 'RDFStore::Model')) {
		my $elements = $input->elements;
		while ( my $st = $elements->each ) {
			$class->{'model'}->add( $st );
			};
	} elsif (ref($input) and UNIVERSAL::isa($input, 'IO::Handle')) {
		$parser->readstream( $input );
	} else {
		my $uri = new URI( $input );
		if($uri) {
			$parser->readfile( $uri );
		} else {
			$parser->readstring( $input );
			};
		};
	};

sub set_or_get {
	my ($class, $property, @vals) = @_;

	if (@vals) {
		$class->set( $property => shift @vals);
	} else {	
		return $class->get($property);
		};
	};

# initialize the RDF object with a bounce of property-name/property-value pairs as defined into the prefixes and associated schema
#	$object->set( 'rdf:type' =>  'foaf:Person', 'dc:title' => "my title" )
#
# The %values can contain nested RDFStore::RDFNode (and then RDFStore::Object) objects to express the data-structure.
#
# If a non-correct RDF-striped syntax is used (resource-property-resource.....-property-value/resource) an error is reported. When a RDF
# object is 'typed' (one or more rdf:type properties have been associated to it), and the corresponding RDF/S infromation is available
# basic RDF/S semantics checking is also done on the rdfs:domain, rdfs:range and  and cardinalities (owl:minCardinality and owl:maxCardinality). All
# mandatory (owl:minCardinality >= 1 if defined) fields are being defaulted to NULL (undef). Recursive bNodes are created as necessary (like
# following the bNodes / CBD description for the Joseki fetch_object() method to understand).
#
sub set {
	my ($class, %values) = @_;

	$class->connect
		unless($class->isConnected);

	# pick up properties
	foreach my $property_name ( keys %values ) {
		# look up property QName for property and build a resource for it (actually here is all the RDFStore::Vocabualry biz which should use
		# RDF objects instead of simple resources i.e. resources than know about their type informations (even if more polymorphic in RDF :)
		$property_name =~ m/^([^:]+):?(.*)/;
		my $localname = ($2) ? $2 : $1;
		#my $namespace = ($2) ? $class->{ 'prefixes' }->{ $1 }->{ 'namespace' } : $class->{ 'prefixes' }->{ '#default' }->{ 'namespace' };
		my $namespace = $class->{ 'prefixes' }->{ $1 }->{ 'namespace' }
			if($2);
		unless(defined $namespace) {
			print STDERR "Can not set unknown property '$property_name'\n";
			return;
			};
		my $factory = $class->{'model'}->getNodeFactory;
		my $property = $factory->createResource( $namespace, $localname );

		my $property_value = $values{ $property_name };

		if( ref($property_value) and UNIVERSAL::isa($property_value, 'RDFStore::Resource') ) {
			push @{ $class->{'types'} }, $property_value #save the rdf:type (polymorphism alike)
				if($property->equals( $RDFStore::Vocabulary::RDF::type ));

			# what happen when this is rdf:resource and two RDFStore::Object DBs are different? real linking?? :-)

			$property_value = $property_value->{'rdf_object'} #keep on wrapping up rdf objects..
				if( ref($property_value) and UNIVERSAL::isa($property_value, 'RDFStore::Object') );
		} else {
			if( ref($property_value) =~ /HASH/ ) {
				my $sub_values =  $property_value;
				# recursive on brand new untyped object or proper one if RDF/S which also share same DB
				$property_value = new RDFStore::Object; #bNode for sure
				$property_value->connect( $class->connection ); # kinda sharing the model (then provenance too???)
				
				$property_value->set( %{$sub_values} ); #recursive call on the bNode created - cool eh? :)
				$property_value = $property_value->{'rdf_object'};#keep on wrapping up rdf objects..
			} elsif( ref($property_value) =~ /ARRAY/ ) {
				# target is new rdf:Seq object sharing same DB too
				my $array_of_values =  $property_value;

				# recursive on brand new untyped object or proper one if RDF/S which also share same DB
				$property_value = new RDFStore::Object; #bNode for sure
				$property_value->connect( $class->connection ); # kinda sharing the model (then provenance too???)
				
				# expand @{$sub_values} into rdf:_1, rdf:_2 ....rdf:_n story....
				my %sub_values=();
				my $i=1;
				map {
					$sub_values{ 'rdf:_' . $i++ } = $_;
				} @{$array_of_values};

				$property_value->set( %sub_values );
				$property_value = $property_value->{'rdf_object'};#keep on wrapping up rdf objects..
			} else {
				#literal.. should add xml:lang and rdf:datatype ala Turtle syntax too
				$property_value = $factory->createLiteral( $property_value );
				};
			};

		#print "S='".$class->{'rdf_object'}->toString."' P='".$property->toString."' O='".$property_value->toString."'\n";
		# add bloody statement finally :)
		$class->{'model'}->add( $class->{'rdf_object'}, $property, $property_value ); #what about provenance here then?
		};
	};

sub get {
	my ($class, $property_name) = @_;
	 
	$class->connect
		unless($class->isConnected);

	$property_name =~ m/^([^:]+):?(.*)/;
	my $localname = ($2) ? $2 : $1;
	#my $namespace = ($2) ? $class->{ 'prefixes' }->{ $1 }->{ 'namespace' } : $class->{ 'prefixes' }->{ '#default' }->{ 'namespace' };
	my $namespace = $class->{ 'prefixes' }->{ $1 }->{ 'namespace' }
		if($2);
	unless(defined $namespace) {
		print STDERR "Can not get unknown property '$property_name'\n";
		return;
		};

	my $factory = $class->{'model'}->getNodeFactory;

	return
		unless($factory);

	my $property = $factory->createResource( $namespace, $localname );

	return
		unless($property);

	my $values = $class->{'model'}->find( $class->{'rdf_object'}, $property )->elements;

	#print "FOUND '".$values->size."' values for '".$property->toString."'\n";

	my @values;
	while( my $object = $values->each_object ) {
		push @values, $object;
		};

	return wantarray ? @values : $values[0];
	};

sub dump {
	my($class) = shift;

	$class->serialize(@_);
	};

sub serialize {
	my ($class, $fh, $syntax, $namespaces, $base ) = @_;

	$class->connect
		unless($class->isConnected);

	my %namespaces = ();
	map {
		$namespaces{ $class->{'prefixes'}->{ $_ }->{'namespace'} } = $_;
	} keys %{ $class->{'prefixes'} };

	return $class->{'model'}->serialize( $fh, $syntax, \%namespaces, $base );
	};

1;
};

__END__

=head1 NAME

RDFStore::Object - A very useful abstration over an RDFStore::Model

=head1 SYNOPSIS

	use RDFStore::Object;

=head1 DESCRIPTION

A "RDF object" wrapper around RDFStore::Model

=head1 SEE ALSO

RDFStore::Model(3) Class::RDF(3)

=head1 ABOUT RDF Objects

 http://www.hpl.hp.com/techreports/2002/HPL-2002-315.pdf

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
