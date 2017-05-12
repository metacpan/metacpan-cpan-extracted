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
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *		- general fixing and improvements
# *			* instances and closure are Model
# *     version 0.3
# *		- added getLocalName() and getNamespace() to delegate to instances
# *		- changed checking to RDFStore::Model type
# *		- modified toString()
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *		- fixed miss-spell in validate()
# *     version 0.4
# *		- complete review of the code
# *		- updated accordingly to new RDFStore::Model
# *

package RDFStore::SchemaModel;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use Carp;
use RDFStore;
use RDFStore::VirtualModel;
use RDFStore::Resource;
use RDFStore::Literal;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFS;

@RDFStore::SchemaModel::ISA = qw( RDFStore::VirtualModel );

# Creates a schema model, closure must contain transitive closures of rdfs:subClassOf and rdfs:subPropertyOf
sub new {
	my ($pkg,$factory_or_instances,$instances_or_closure,$closure) = @_;

    	my $self = $pkg->SUPER::new();

	#to emulate typed parameters
	if ( 	(defined $factory_or_instances) && 
		(ref($factory_or_instances)) && 
		($factory_or_instances->isa("RDFStore::Model")) ) {
		$self->{nodeFactory}=new RDFStore::NodeFactory();
		$self->{instances}=$factory_or_instances;
		if(	(defined $instances_or_closure) && 
			(ref($instances_or_closure)) && 
			($instances_or_closure->isa("RDFStore::Model")) ) {
			$self->{closure}=$instances_or_closure;
			};
	} elsif(	(defined $factory_or_instances) && 
			(ref($factory_or_instances)) &&
			($factory_or_instances->isa("RDFStore::NodeFactory")) ) {
		$self->{nodeFactory}=$factory_or_instances;
		if (	(defined $instances_or_closure) && 
			(ref($instances_or_closure)) && 
			($instances_or_closure->isa("RDFStore::Model")) ) {
			$self->{instances}=$instances_or_closure;
			};
		if(	(defined $closure) && 
			(ref($closure)) && 
			($closure->isa("RDFStore::Model")) ) {
			$self->{closure}=$closure;
			};
	} else {
		$self->{nodeFactory}=new RDFStore::NodeFactory();
		if (	(defined $instances_or_closure) && 
			(ref($instances_or_closure)) && 
			($instances_or_closure->isa("RDFStore::Model")) ) {
			$self->{instances}=$instances_or_closure;
			};
		if(	(defined $closure) && 
			(ref($closure)) && 
			($closure->isa("RDFStore::Model")) ) {
			$self->{closure}=$closure;
			};
		};

	warn "Missing ground or schema model" and return
		unless( defined $self->{instances} and defined $self->{closure} );

    	bless $self,$pkg;
	};

# we alwasy use instances (data) model for generic reference operations
sub getNamespace {
        return $_[0]->{instances}->getNamespace();
	};

sub getLocalName {
	return $_[0]->{instances}->getLocalName();
	};

sub getLabel {
	return $_[0]->{instances}->getLabel();
	};

sub getURI {
	return $_[0]->{instances}->getURI();
	};

# return model contains the fact basis of this model
sub getGroundModel {
	return $_[0]->{instances};
	};

sub setSourceURI {
	$_[0]->{instances}->setSourceURI($_[1]);
	};

sub getSourceURI {
	return $_[0]->{instances}->getSourceURI();
	};

sub setContext {
	return $_[0]->{instances}->setContext($_[1]);
	};

sub resetContext {
	return $_[0]->{instances}->resetContext;
	};

sub getContext {
	return $_[0]->{instances}->getContext;
	};

sub getOptions {
	return $_[0]->{instances}->getOptions;
	};

sub isAnonymous {
	return 0;
	};

sub isConnected {
	return $_[0]->{instances}->isConnected;
	};

sub isRemote {
	return $_[0]->{instances}->isRemote;
	};

sub namespaces {
	return $_[0]->{instances}->namespaces;
	};

# return  number of triples (unknown due to the RDF Schema business)
sub size {
	return -1; #unknown
	};

sub isEmpty {
	return $_[0]->{instances}->isEmpty();
	};

sub isMutable {
	$_[0]->{instances}->isMutable();
	};

# Enumerates all triples (including derived) for a given model and schema
sub elements {
	my ($class) = @_;

	#something special here...like merge the instances and closure with Model?
        return RDFStore::SchemaModel::Iterator->new(	$class->getNodeFactory,
        						$class->{instances}->{rdfstore}->elements,
        						$class->{closure}->{rdfstore}->elements );
	};

sub contains {
	return 0
                unless( (defined $_[1]) &&
                        (ref($_[1])) &&
                        ($_[1]->isa("RDFStore::Statement")) );

        croak "Statement context '".$_[2]."' is not instance of RDFStore::Resource"
                unless(	(not(defined $_[2])) ||
                        (       (defined $_[2]) &&
                        	(ref($_[2])) &&
                                ($_[2]->isa('RDFStore::Resource')) ) );

        my $context;
        if(defined $_[2]) {
                $context = $_[2];
        } else {
                $context = $_[1]->context
                        if($_[1]->context);
                };

	# FIXME: efficiency?
	return !($_[0]->find(	$_[1]->subject(),
				$_[1]->predicate(),
				$_[1]->object(),
				$context
				)->isEmpty());
};

sub add {
	my ( $class ) = shift;

	$class->{instances}->add(@_);
	};

# Removes the triple from the model
sub remove {
	my ( $class ) = shift;

	$class->{instances}->remove(@_);
	};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: Model result = m.find( null, RDF.type, new Resource("http://...#MyClass") )
# finds all instances of the class MyClass
# NOTE: AR want DAML here now :-)
sub find {
	my ($class) = shift;
        my ($subject,$predicate,$object,$context,$words_operator,@words) = @_;

        croak "Subject '".$subject."' is not instance of RDFStore::Resource"
                unless( (not(defined $subject)) ||
                        (       (defined $subject) &&
                                (ref($subject)) &&
                                ($subject->isa('RDFStore::Resource')) ) );
        croak "Predicate '".$predicate."' is not instance of RDFStore::Resource"
                unless( (not(defined $predicate)) ||
                                (       (defined $predicate) &&
                                        (ref($predicate)) &&
                                        ($predicate->isa('RDFStore::Resource')) ) );
        croak "Object '".$object."' is not instance of RDFStore::RDFNode"
                unless( (not(defined $object)) ||
                                (       (defined $object) &&
                                        (ref($object)) &&
                                        ($object->isa('RDFStore::RDFNode')) ) );

        croak "Statement context '".$context."' is not instance of RDFStore::Resource"
                unless( (not(defined $context)) ||
                                (       (defined $context) &&
                                        (ref($context)) &&
                                        ($context->isa('RDFStore::Resource')) ) );

	# only two special cases for now but need more entailment/inferencing here

	my $res;

	# asking for instances - to me it looks really like PEN.pm ;-)
	if ((defined $object) && ($RDFStore::Vocabulary::RDF::type->equals($predicate))) {
		$res = $class->{instances}->find($subject,$predicate,$object,$context,$words_operator,@words);

		# collect subclasses
		my $subclass = $class->{closure}->find(undef,$RDFStore::Vocabulary::RDFS::subClassOf,$object)->elements; 
		while ( my $s = $subclass->each_subject ) {
			# find instances
			my $subclass_type = $class->{instances}->find( $subject,$RDFStore::Vocabulary::RDF::type,$s ); #slow and inefficient (most searches will fail) !!
			while ( my $s1 = $subclass_type->each ) {
				$res->add( $s1 );
				};
			};
	} elsif($RDFStore::Vocabulary::RDFS::subClassOf->equals($predicate)) {
		$res = $class->{closure}->find($subject,$predicate,$object,undef,$words_operator,@words); #we do not consider context!!!
	} elsif(defined $predicate) {
		$res = $class->{instances}->find($subject,$predicate,$object,$context,$words_operator,@words);

		# collect subproperties
		my $subprop = $class->{closure}->find(undef, $RDFStore::Vocabulary::RDFS::subPropertyOf,$predicate)->elements;
		while ( my $s = $subprop->each_subject ) {
			# find properties
			my $subprop_type = $class->{instances}->find( $subject,$s, $predicate ); #slow and inefficient (most searches will fail) !!
			while ( my $s1 = $subprop_type->each ) {
				$res->add( $s1 );
				};
			};
	} else {
		# normal search into instances
		$res = $class->{instances}->find($subject,$predicate,$object,$context,$words_operator,@words);
		};

        return $res;
};

sub duplicate {
	# creates a model that shares ONLY the closure with this model
	return new RDFStore::SchemaModel($_[0]->{nodeFactory},$_[0]->{instances}->duplicate(), $_[0]->{closure});
	};

sub create {
	return new RDFStore::SchemaModel($_[0]->{instances}->create(), $_[0]->{closure});
	};

sub getNodeFactory {
	return $_[0]->{nodeFactory};	
	};

sub toString {
	return "[RDFSchemaModel ".$_[0]->{instances}->getSourceURI()."]";
	};

sub intersect {
	my ($class,$other) = @_;

        return
                unless($other);

        croak "Model '".$other."' is not instance of RDFStore::SchemaModel"
                unless( (defined $other) && (ref($other)) &&
                        ($other->isa('RDFStore::Model')) );

        croak "Models can not be intersected"
                unless( (	( $class->{instances}->{Shared} == $class->{instances}->{Shared} ) &&
                		( $class->{closure}->{Shared} == $class->{closure}->{Shared} ) ) ||
                        (	( $class->{instances}->{rdfstore} == $other->{instances}->{rdfstore} ) &&
				( $class->{closure}->{rdfstore} == $other->{closure}->{rdfstore} ) ) );

        my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

        $res->{query_iterator} = $class->elements->intersect( $other->elements ); # that easy :)

        # set default context if any was set
        my $sg = $class->getContext;
        $res->setContext( $sg )
                if(defined $sg);

        return $res;
	};

sub subtract {
	};

sub unite {
	};

sub complement {
	};

sub exor {
	};

sub serialize {
	};

sub computeRDFSClosure {
	croak "Model ".$_[1]." is not instance of RDFStore::Model"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Model')) );

	#closure must be Model!!!
	my $closure = $_[0]->computeClosure($_[1],$RDFStore::Vocabulary::RDFS::subClassOf);
    	$closure->unite($_[0]->computeClosure($_[1],$RDFStore::Vocabulary::RDFS::subPropertyOf)); # works???
	return $closure;
	};

# Computes a transitive closure on a given predicate. If allowLoops is set to false, an error is thrown if a loop is encountered
sub computeClosure {
	my ($class, $model, $property, $allowLoops ) = @_;

	croak "Model ".$model." is not instance of RDFStore::Model"
                unless( (defined $model) && (ref($model)) &&
                        ($model->isa('RDFStore::Model')) );

	croak "Property ".$property." is not instance of RDFStore::Resource"
                unless( (defined $property) && (ref($property)) &&
                        ($property->isa('RDFStore::Resource')) );

	# disallow loops by default
	$allowLoops = 0
		unless( ($allowLoops) && (int($allowLoops)) );

	my $closure = $model->create(); #in-memory by default???

	# find all roots
	my $all = $model->find(undef, $property, undef)->elements;

    	# compute closure
	my %processedNodes = ();
	my %stack = ();
	while ( my $o = $all->each_object ) {
      		if(	(!(exists $processedNodes{ $o->toString })) &&
			($o->isa("RDFStore::Resource")) ) {
			%stack = ();
			croak "[RDFSchemaModel] found invalid loop in transitive closure of ",$property->getLabel," Loop node: ",$o->getLabel
				if(	($class->traverseClosure( \%processedNodes, $o, $property, \%stack, $closure, $model, 0)) &&
					(!($allowLoops)) );
      			};
    		};

	return $closure;
	};

# traverse down the tree, maintains stack and adds shortcuts to the model. Returns true if a loop is found - false otherwise
sub traverseClosure {
	my ($class, $processedNodes, $object, $property, $stack, $closure, $model, $depth ) = @_;

	croak "Hash ".$processedNodes." is not an HASH reference"
                unless( (defined $processedNodes) &&
                        (ref($processedNodes) =~ /HASH/) );

	croak "Resource ".$object." is not instance of RDFStore::Resource"
                unless( (defined $object) && (ref($object)) &&
                        ($object->isa('RDFStore::Resource')) );

	croak "Resource ".$property." is not instance of RDFStore::Resource"
                unless( (defined $property) && (ref($property)) &&
                        ($property->isa('RDFStore::Resource')) );

	croak "Hash ".$stack." is not an HASH reference"
                unless( (defined $stack) &&
                        (ref($stack) =~ /HASH/) );

	croak "Model ".$closure." is not instance of RDFStore::Model"
                unless( (defined $closure) && (ref($closure)) &&
                        ($closure->isa('RDFStore::Model')) );

	croak "Model ".$model." is not instance of RDFStore::Model"
                unless( (defined $model) && (ref($model)) &&
                        ($model->isa('RDFStore::Model')) );

	croak "Integer ".$depth." is not a valid INTEGER "
                unless( ($depth == 0) || ( (defined $depth) && (int($depth))) );

	$processedNodes->{ $object->toString } = 1;

	my $isOnStack = (exists $stack->{ $object->toString });
	my $isLoop = $isOnStack;
	if(!($isOnStack)) {
		$stack->{ $object->toString } = 1;

		# get all children of this node
		my $children = $model->find(undef, $property, undef)->elements;

		while ( my $s = $children->each_subject ) {
			# uauuu!! recursive here :)
        		$isLoop |= $_[0]->traverseClosure($processedNodes, $s, $property, $stack, $closure, $model, $depth+1 );
      			};

		delete $stack->{ $object->toString }
			if(!($isLoop));
		};

	# add everything from stack
    	if(!($isOnStack)) {
		while ( my ($k,$parent) = each %{$stack} ) {
			my $factory = $model->getNodeFactory();
      			$closure->add( $factory->createStatement($object, $property, $factory->createResource($parent)) );
			};
    		};

	return $isLoop;
	};

# validates instances model against a schema model
sub validateRawSchema {
	my ($class, $instances_model, $schema_model) = @_;

	croak "Model ".$instances_model." is not instance of RDFStore::Model"
                unless( (defined $instances_model) && (ref($instances_model)) &&
                        ($instances_model->isa('RDFStore::Model')) );

	croak "Model ".$schema_model." is not instance of RDFStore::Model"
                unless( (defined $schema_model) && (ref($schema_model)) &&
                        ($schema_model->isa('RDFStore::Model')) );

	my $closure = $class->computeRDFSClosure($schema_model);

	my $schema = new RDFStore::SchemaModel($schema_model, $closure); #kinda recursive here...
	my $instances = new RDFStore::SchemaModel($instances_model, $closure);

	$class->validate($instances, $schema);
	};

# converts an ordinal property to an integer
sub getOrd {
	croak "Resource ".$_[1]." is not instance of RDFStore::Resource"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Resource')) );

	return -1
		unless(defined $_[1]);

	my $uri = $_[1]->toString();

	#is RDF?
	return -1
		if(!((defined $uri) && ($uri =~ m|^$RDFStore::Vocabulary::RDF::_Namespace|)));
                  
	# Position of the namespace end
	my $pos;
	if (	($uri =~ m|#$|g) ||
		($uri =~ m|:$|g) ||
		($uri =~ m|\/$|g) ) {
		$pos=pos($uri);
	} else {
		$pos=length($uri);
		};

	if(($pos > 0) && ($pos + 1 < length($uri))) {
		#parseInt in Perl....
        	my $n = unpack("i*",substring($uri,$pos + 1));
        	return $n
			if($n >= 1);
    		};

	return -1;
	};

# validates the model. schema should be a RDFStore::SchemaModel
sub validate {
	my ($class, $instances, $schema ) = @_;

	croak "Model ".$instances." is not instance of RDFStore::Model"
                unless( (defined $instances) && (ref($instances)) &&
                        ($instances->isa('RDFStore::Model')) );

	croak "Model ".$schema." is not instance of RDFStore::SchemaModel"
                unless( (defined $schema) && (ref($schema)) &&
                        ($schema->isa('RDFStore::SchemaModel')) );

	my %containers = (); # triples containing collections and ordinals
	my @errors = ();
	my $ele = $instances->elements;
	while ( my $t = $ele->each ) {
		# rdf:type
		if($RDFStore::Vocabulary::RDF::type->equals($t->predicate())) {
			# ensure that the target is of type rdf:Class
			if($t->object()->isa("RDFStore::Literal")) {
          			$class->invalid( \@errors, $t, "Literals cannot be used for typing - object must be a RDF resource of some kind" );
				};
			# cast is skipped in Perl.....
        		my $res = $schema->find( $t->object(), $RDFStore::Vocabulary::RDF::type, $RDFStore::Vocabulary::RDFS::Class );
			if($res->isEmpty()) {
          			if($class->noSchema(\@errors, $t->object())) {
					last;
				} else {
            				$class->invalid( \@errors, $t, $t->object->toString . " must be an instance of ". $RDFStore::Vocabulary::RDFS::Class->toString );
        				};
        			};
		} elsif($class->getOrd($t->predicate()) > 0) {
			# save for later
			$containers{ $t->subject->toString }= $t;
		} else {
			# check rdfs:domain and rdfs:range
			my @expected = ();

			# find all allowed domains of the Property
			my $domains = $schema->find( $t->predicate(), $RDFStore::Vocabulary::RDFS::domain, undef );
        		if(!($domains->isEmpty())) {
          			my $domainOK = 0;
				# go through all valid domains and check whether the subject is an instance of a valid domain Class
				my $dd = $domains->elements;
				while( my $o = $dd->each_object ) {
            				push @expected, $o;
            				if(!($instances->find($t->subject(),$RDFStore::Vocabulary::RDF::type, $o)->isEmpty())) {
              					$domainOK = 1;
						last;
            					};
          				};
          			if(!($domainOK)) {
            				if($class->noSchema(\@errors, $t->subject())) {
						last;
					} else {
              					$class->invalid( \@errors, $t, "Subject must be instance of ".join(' or ', map { $_->toString } @expected ) );
          					};
          				};
        			};
			@expected=();

			# find all allowed ranges of the Property
			my $ranges = $schema->find( $t->predicate(), $RDFStore::Vocabulary::RDFS::range, undef );
        		if($ranges->size() == 1) { # there can be only one range property!!! (See specs)
          			my $rangeOK = 0;
				# go through all valid ranges and check whether
				# the object() is an instance of a valid range Class
				my $rr = $ranges->elements;
				while( my $o = $rr->each_object ) {
            				push @expected, $o;
            				# special treatment for Literals
            				if($RDFStore::Vocabulary::RDFS::Literal->equals($o)) {
              					if( $t->object()->isa("RDFStore::Literal")) {
							$rangeOK = 1;
                					last;
              					} else {
                					$class->invalid( \@errors, $t, $t->object() ." must be a literal");
							};
					} elsif (	($t->object()->isa("RDFStore::Resource")) &&
							(!($instances->find( $t->object(), $RDFStore::Vocabulary::RDF::type, $o )->isEmpty())) ) {
						$rangeOK = 1;
						last;
						};
					};
				if(!($rangeOK)) {
					if($class->noSchema(\@errors,$t->object())) {
						last;
					} else {
						$class->invalid( \@errors, $t, "Object must be instance of ".join(' or ', map { $_->toString } @expected ) );
						};
					};
        		} elsif($ranges->size() > 1) {
          			$class->invalid( \@errors, undef, "Invalid schema. Multiple ranges for ".$t->predicate->toString );
      				};
      			};
    		};

	croak "InvalidModel ".join(' , ', @errors)
		if(scalar(@errors)>0);
	};

sub noSchema {
 	return 0;
	};

sub invalid {
	croak "Parameter ".$_[1]." is not an ARRAY reference"
                unless( (defined $_[1]) &&
                        (ref($_[1])=~ /ARRAY/) );
	croak "Statement ".$_[2]." is not instance of RDFStore::Statement"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Statement')) );

	if(scalar(@{$_[1]}) > 0) {
		push @{$_[1]},"\n";
    		if(defined $_[2]) {
      			push @{$_[1]},"Invalid statement:\n\t".$_[2].".\n\t";
    			};
    		};

	push @{$_[1]},$_[3];
	};

# simple front-end to RDFStore::Iterator using a the given nodeFactory
package RDFStore::SchemaModel::Iterator;

use vars qw ( $VERSION );
use strict;

$VERSION = '0.1';

sub new {
	my ($pkg,$factory,$iterator) = @_;

	return
                unless( (defined $iterator) && (defined $factory) );

        return 	bless {
			factory => 	$factory,
			iterator => 	$iterator
		},$pkg;
	};

sub size {
	return $_[0]->{iterator}->size;
	};

sub duplicate {
	return $_[0]->{iterator}->duplicate;
	};

sub hasnext {
	return $_[0]->{iterator}->hasnext;
	};

sub remove {
	return $_[0]->{iterator}->remove;
	};

sub intersect {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::SchemaModel::Iterator")) );

	return new RDFStore::SchemaModel::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->intersect( $_[1]->{iterator} ) );
	};

sub unite {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::SchemaModel::Iterator")) );

	return new RDFStore::SchemaModel::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->unite( $_[1]->{iterator} ) );
	};

sub subtract {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::SchemaModel::Iterator")) );

	return new RDFStore::SchemaModel::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->subtract( $_[1]->{iterator} ) );
	};

sub complement {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::SchemaModel::Iterator")) );

	return new RDFStore::SchemaModel::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->complement( $_[1]->{iterator} ) );
	};

sub exor {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::SchemaModel::Iterator")) );

	return new RDFStore::SchemaModel::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->exor( $_[1]->{iterator} ) );
	};

sub next {
	my ($st) = $_[0]->{iterator}->next;

	return
		unless($st);

	return $_[0]->{factory}->createStatement(
			( $st->subject->isbNode ) ? 
				$_[0]->{factory}->createAnonymousResource( $st->subject->toString ) : 
				$_[0]->{factory}->createResource( $st->subject->toString ),
			( $st->predicate->isbNode ) ? # I know that is not possible but we allow it anyway ;-/
				$_[0]->{factory}->createAnonymousResource( $st->predicate->toString ) : 
				$_[0]->{factory}->createResource( $st->predicate->toString ),
			( $st->object->isa("RDFStore::Literal") ) ?
				$_[0]->{factory}->createLiteral(	$st->object->getLabel,
									$st->object->getParseType,
									$st->object->getLang,
									$st->object->getDataType ) :
			( $st->object->isbNode ) ? 
				$_[0]->{factory}->createAnonymousResource( $st->object->toString ) : 
				$_[0]->{factory}->createResource( $st->object->toString ),
			( $st->context ) ?  ( $st->context->isbNode ) ? 
						$_[0]->{factory}->createAnonymousResource( $st->context->toString ) : 
						$_[0]->{factory}->createResource( $st->context->toString ) : undef );
	};

sub next_subject {
	my ($n) = $_[0]->{iterator}->next_subject;

        return
                unless($n);

        return ( $n->isbNode ) ?
			$_[0]->{factory}->createAnonymousResource( $n->toString ) : 
			$_[0]->{factory}->createResource( $n->toString );
	};

sub next_predicate {
	my ($n) = $_[0]->{iterator}->next_predicate;

        return
                unless($n); 

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub next_object {
	my ($n) = $_[0]->{iterator}->next_object;

        return
                unless($n); 

	return ( $n->isa("RDFStore::Literal") ) ?
               	$_[0]->{factory}->createLiteral(	$n->getLabel,
                                                        $n->getParseType,
                                                        $n->getLang,
                                                        $n->getDataType ) :
               ( $n->isbNode ) ?
                	$_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub next_context {
	my ($n) = $_[0]->{iterator}->next_context;

        return
                unless($n); 

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub current {
	my ($st) = $_[0]->{iterator}->current;

        return
                unless($st);

	return $_[0]->{factory}->createStatement(
                        ( $st->subject->isbNode ) ?
                                $_[0]->{factory}->createAnonymousResource( $st->subject->toString ) :
                                $_[0]->{factory}->createResource( $st->subject->toString ),
                        ( $st->predicate->isbNode ) ? # I know that is not possible but we allow it anyway ;-/
                                $_[0]->{factory}->createAnonymousResource( $st->predicate->toString ) :
                                $_[0]->{factory}->createResource( $st->predicate->toString ),
                        ( $st->object->isa("RDFStore::Literal") ) ?
                                $_[0]->{factory}->createLiteral(        $st->object->getLabel,
                                                                        $st->object->getParseType,
                                                                        $st->object->getLang,
                                                                        $st->object->getDataType ) :
                        ( $st->object->isbNode ) ? 
                                $_[0]->{factory}->createAnonymousResource( $st->object->toString ) : 
                                $_[0]->{factory}->createResource( $st->object->toString ), 
                        ( $st->context ) ?  ( $st->context->isbNode ) ?                  
                                                $_[0]->{factory}->createAnonymousResource( $st->context->toString ) :
                                                $_[0]->{factory}->createResource( $st->context->toString ) : undef );
	};

sub current_subject {
	my ($n) = $_[0]->{iterator}->current_subject;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub current_predicate {
	my ($n) = $_[0]->{iterator}->current_predicate;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub current_object {
	my ($n) = $_[0]->{iterator}->current_object;

        return
                unless($n);

        return ( $n->isa("RDFStore::Literal") ) ?
                $_[0]->{factory}->createLiteral(        $n->getLabel,
                                                        $n->getParseType,
                                                        $n->getLang,
                                                        $n->getDataType ) :
               ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub current_context {  
	my ($n) = $_[0]->{iterator}->current_context;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
        };

sub first {
	my ($st) = $_[0]->{iterator}->first;

        return
                unless($st);

	return $_[0]->{factory}->createStatement(
                        ( $st->subject->isbNode ) ?
                                $_[0]->{factory}->createAnonymousResource( $st->subject->toString ) :
                                $_[0]->{factory}->createResource( $st->subject->toString ),
                        ( $st->predicate->isbNode ) ? # I know that is not possible but we allow it anyway ;-/
                                $_[0]->{factory}->createAnonymousResource( $st->predicate->toString ) :
                                $_[0]->{factory}->createResource( $st->predicate->toString ),
                        ( $st->object->isa("RDFStore::Literal") ) ?
                                $_[0]->{factory}->createLiteral(        $st->object->getLabel,
                                                                        $st->object->getParseType,
                                                                        $st->object->getLang,
                                                                        $st->object->getDataType ) :
                        ( $st->object->isbNode ) ? 
                                $_[0]->{factory}->createAnonymousResource( $st->object->toString ) : 
                                $_[0]->{factory}->createResource( $st->object->toString ), 
                        ( $st->context ) ?  ( $st->context->isbNode ) ?                  
                                                $_[0]->{factory}->createAnonymousResource( $st->context->toString ) :
                                                $_[0]->{factory}->createResource( $st->context->toString ) : undef );
	};

sub first_subject {
	my ($n) = $_[0]->{iterator}->first_subject;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub first_predicate {
	my ($n) = $_[0]->{iterator}->first_predicate;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub first_object {
	my ($n) = $_[0]->{iterator}->first_object;

        return
                unless($n);

        return ( $n->isa("RDFStore::Literal") ) ?
                $_[0]->{factory}->createLiteral(        $n->getLabel,
                                                        $n->getParseType,
                                                        $n->getLang,
                                                        $n->getDataType ) :
               ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub first_context {  
	my ($n) = $_[0]->{iterator}->first_context;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
        };

sub each {
	my ($st) = $_[0]->{iterator}->each;

        return
                unless($st);

	return $_[0]->{factory}->createStatement(
                        ( $st->subject->isbNode ) ?
                                $_[0]->{factory}->createAnonymousResource( $st->subject->toString ) :
                                $_[0]->{factory}->createResource( $st->subject->toString ),
                        ( $st->predicate->isbNode ) ? # I know that is not possible but we allow it anyway ;-/
                                $_[0]->{factory}->createAnonymousResource( $st->predicate->toString ) :
                                $_[0]->{factory}->createResource( $st->predicate->toString ),
                        ( $st->object->isa("RDFStore::Literal") ) ?
                                $_[0]->{factory}->createLiteral(        $st->object->getLabel,
                                                                        $st->object->getParseType,
                                                                        $st->object->getLang,
                                                                        $st->object->getDataType ) :
                        ( $st->object->isbNode ) ? 
                                $_[0]->{factory}->createAnonymousResource( $st->object->toString ) : 
                                $_[0]->{factory}->createResource( $st->object->toString ), 
                        ( $st->context ) ?  ( $st->context->isbNode ) ?                  
                                                $_[0]->{factory}->createAnonymousResource( $st->context->toString ) :
                                                $_[0]->{factory}->createResource( $st->context->toString ) : undef );
	};

sub each_subject {
	my ($n) = $_[0]->{iterator}->each_subject;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub each_predicate {
	my ($n) = $_[0]->{iterator}->each_predicate;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub each_object {
	my ($n) = $_[0]->{iterator}->each_object;

        return
                unless($n);

        return ( $n->isa("RDFStore::Literal") ) ?
                $_[0]->{factory}->createLiteral(        $n->getLabel,
                                                        $n->getParseType,
                                                        $n->getLang,
                                                        $n->getDataType ) :
               ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
	};

sub each_context {  
	my ($n) = $_[0]->{iterator}->each_context;

        return
                unless($n);

        return ( $n->isbNode ) ?
                        $_[0]->{factory}->createAnonymousResource( $n->toString ) :
                        $_[0]->{factory}->createResource( $n->toString );
        };

1;
};

__END__

=head1 NAME

RDFStore::SchemaModel - implementation of the SchemaModel RDF API

=head1 SYNOPSIS

	use RDFStore::SchemaModel;
	my $schema_validator = new RDFStore::SchemaModel();
	my $valid = $schema_validator->validateRawSchema($m,$rawSchema);

=head1 DESCRIPTION

This is an incomplete package and it provides basic RDF Schema support accordingly to the Draft API of Sergey Melnik at http://www-db.stanford.edu/~melnik/rdf/api.html.
Please use it as a prototype and/or just to get the idea. It provide basic 'closure' support and validation of a given RDF instance against an RDF Schema.

=head1 SEE ALSO

 RDFStore::Model(3) RDFStore::VirtualModel(3)

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

 DARPA Agent Markup Language (DAML) - http://www.daml.org/

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
