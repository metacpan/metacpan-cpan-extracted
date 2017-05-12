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
# *		- fixed bug in new() to check if triples is HASH ref when passed by user
# *		- fixed bug in find() do avoid to  return instances of SetModel (see SchemaModel.pm also)
# *		  Now result sets are put in an object(model) of the the same type - see find()
# *             - modified add() remove() clone() duplicate() and added toString() makePrivate()
# *		  getNamespace() getLocalName() methods accordingly to rdf-api-2000-10-30
# *		- modifed new(), duplicate(), clone() and find() to support cloned models
# *		  Due the fact that Data::MagicTie does not support the clone method, when
# *		  either the triples or the index are duplicated (or cloned) the user could
# *		  specify on which HASH(es) (tied or not) to store the results (see duplicate())
# *		- modified find() to manage normal Models and indexed Models differently
# *		- added optional indirect indexing to find() i.e. the FindIndex stores just digested keys
# *		  and not the full BLOB; fetch from an index then require an additional look up in triples
# *     version 0.3
# *		- fixed bug in find(). Check the type of $t before using methods on it
# *		- added toStrawmanRDF() to serialise the model in strawman RDF for RDFStore::Parser::OpenHealth
# *		- fixed bug in create()
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *             - modified updateDigest() method accordingly to rdf-api-2000-11-13
# *     version 0.31
# *		- commented out isEmpty() check in find() due to DBMS(3) efficency problems
# *		- fixed bug in add() when adding statements with a Literal value
# *		- updated toStrawmanRDF() method
# *		- modifed add() to avoid update of existing statements
# *     version 0.4
# *		- modifed add() to return undef if the triples exists already in the database
# *		- changed way to return undef in subroutines
# *		- renamed triples hash to store
# *		- adapted to use the new Data::MagicTie interface
# *		- complete re-design of the indexing and storage method
# *		- added getOptions() method
# *		- Devon Smith <devon@taller.pscl.cwru.edu> changed getDigestBytes() to generate digests and hashes
# *               that match Stanford java ones exactly
# *		- added inheritance from RDFStore::Digest::Digestable
# *		- removed RDFStore::Resource inheritance
# *     version 0.41
# *             - updated _getLookupValue() and _getValuesFromLookup() to consider negative hashcodes
# *     version 0.42
# *		- complete redesign of the indexing method up to free-text search on literals
# *		- added tied array iterator RDFStore::Model::Statements to allow fetching results one by one
# *		- modified find() to allow a 4th paramater to make free-text search over literals
# *     version 0.43
# *		- brand new design now using the faster C/XS RDFStore(3) module....finally :)
# *		- updated methods to avoid a full copy of statements across when the model is shared if possible
# *		- added basic support for statements grouping - see setContext(), getContext() and resetContext()
# *		- zapped toStrawmanRDF() method
# *		- added serialize() method to generally dump a model/graph to a string or filehanlde
# *		- added isConnected() and isRemote() methods
# *		- added unite(), subtract(), intersect(), complement() and exor() methods
# *		- re-added RDFStore::Resource inheritance
# *		- added getParser(), getReader(), getSerializer() and getWriter() methods
# *     version 0.44
# *		- updated search() method call to use new XS code interface (hash ref)
# *		- added ifModifiedSince() method
# *

package RDFStore::Model;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.44';

use Carp;

use RDFStore;
use RDFStore::Digest::Digestable;
use RDFStore::Literal;
use RDFStore::Resource;
use RDFStore::Object;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::NTriples;
use RDFStore::Serializer::RDFXML;
use RDFStore::Serializer::NTriples;
use RDFStore::Util::Digest;

@RDFStore::Model::ISA = qw( RDFStore::Resource RDFStore::Digest::Digestable );

sub new {
        my ($pkg,%params) = @_;
 
        my $self = {};
 
        # first operation creates lookup table
        $self->{nodeFactory}=(  (exists $params{nodeFactory}) &&
                                (defined $params{nodeFactory}) &&
                                (ref($params{nodeFactory})) &&
                                ($params{nodeFactory}->isa("RDFStore::NodeFactory")) ) ?
                                $params{nodeFactory} : new RDFStore::NodeFactory();

        $self->{options} = \%params;

	#store
	my @params = ();
	
	if (	(exists $params{Name}) && 
		(defined $params{Name}) ) {
		push @params, $params{Name};
	} else {
		push @params,undef;
		};
	if (	(exists $params{Mode}) && 
		(defined $params{Mode}) ) {
		push @params, ($params{Mode} eq 'r') ? 1 : 0;
	} else {
		push @params,0;
		};
	if (	(exists $params{FreeText}) && 
		(defined $params{FreeText}) ) {
		push @params, ($params{FreeText} =~ /(1|on|yes|true)/i) ? 1 : 0;
	} else {
		push @params,0;
		};
	if (	(exists $params{Sync}) && 
		(defined $params{Sync}) ) {
		push @params, int($params{Sync});
	} else {
		push @params,0;
		};
	if (	(	(exists $params{Host}) && 
			(defined $params{Host}) ) ||
		(	(exists $params{Port}) && 
			(defined $params{Port}) ) ) {
		push @params, 1;
	} else {
		push @params, 0;
		};
	if (	(exists $params{Host}) && 
		(defined $params{Host}) ) {
		push @params, $params{Host};
	} else {
		push @params,undef;
		};
	if (	(exists $params{Port}) && 
		(defined $params{Port}) ) {
		push @params, $params{Port};
	} else {
		push @params,undef;
		};

	$self->{'rdfstore'} = new RDFStore( @params );

        die "Cannot connect rdfstore"
		unless(	(defined $self->{rdfstore}) &&
			(ref($self->{rdfstore})) &&
			($self->{rdfstore}->isa("RDFStore")) );

	$self->{'rdfstore_params'} = \%params;

        bless $self,$pkg;

	return $self;
};

# set a context for the statements (i.e. each asserted statement will get such a context automatically)
# NOTE: this stuff I can not still understand how could be related to reification/logic/inference but it should...
sub setContext {
	my ($class,$context)=@_;

	$class->{rdfstore}->set_context( $context );
	};

# reset the context for the statements (i.e. each asserted statement will be in a *empty* context after calling this method)
sub resetContext {
	my ($class)=@_;

	$class->{rdfstore}->reset_context;
	};

#return actual defined context of the model
sub getContext {
	my ($class)=@_;

	my $ctx = $class->{rdfstore}->get_context;

	return
		unless($ctx);

        return ($ctx->isbNode) ? $class->{nodeFactory}->createAnonymousResource($ctx->toString) : $class->{nodeFactory}->createResource($ctx->toString);
	};

# return model options
sub getOptions {
	return %{$_[0]->{'options'}};
	};

sub isAnonymous {
        return 0;
        };

sub getNamespace {
        return undef;
	};

sub getLocalName {
        return $_[0]->getURI();
	};

sub toString {
        return "Model[".$_[0]->getSourceURI()."]";
	};

# Set a base URI for the model
sub setSourceURI {
	$_[0]->{rdfstore}->set_source_uri( (	(ref($_[1])) && ($_[1]->isa("RDFStore::Resource")) ) ? $_[1]->toString : $_[1] );
	# we shuld probably set it as default context eventually but I am not sure....
	};

# Returns current base URI for the model
sub getSourceURI {
	$_[0]->{rdfstore}->get_source_uri;
	};

# model access methods

# return the number of triples in the model
sub size {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		if(exists $_[0]->{query_iterator}) {
			return $_[0]->{query_iterator}->size;
		} else {
			return $_[0]->{Shared}->size;
			};
	};

        $_[0]->{rdfstore}->size;
	};

# check whether or not the model is empty
sub isEmpty {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		if(exists $_[0]->{query_iterator}) {
			return ( $_[0]->{query_iterator}->size > 0 ) ? 0 : 1;
		} else {
			return $_[0]->{Shared}->isEmpty;
			};
		};
        $_[0]->{rdfstore}->is_empty;
	};

sub isConnected {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		return $_[0]->{Shared}->isConnected;
		};
        $_[0]->{rdfstore}->is_connected;
	};

sub isRemote {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		return $_[0]->{Shared}->isRemote;
		};
        $_[0]->{rdfstore}->is_remote;
	};

sub ifModifiedSince {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		return $_[0]->{Shared}->ifModifiedSince( $_[1] );
		};

	&RDFStore::if_modified_since( $_[0]->{'rdfstore_params'}->{'Name'}, $_[1] );
	};

# return an instance of RDFStore::Model::Iterator
sub elements {
	my ($class) = @_;

	if(	(exists $class->{Shared}) &&
		(defined $class->{Shared}) ) {
		if(exists $class->{query_iterator}) {
			if(	($class->{query_iterator}->size > 0 ) &&
				(defined $class->{query}) &&
				(ref($class->{query})=~/ARRAY/) ) {
                		delete($class->{query});
				};
			# iterator over result set
			return RDFStore::Model::Iterator->new(	$class->getNodeFactory, 
								$class->{query_iterator} );
		} else {
			return $class->{Shared}->elements;
			};
	} else {
		# normal iterator over the whole model
		return RDFStore::Model::Iterator->new(	$class->getNodeFactory, 
							$class->{rdfstore}->elements );
		};
	};

sub namespaces {
	my ($class) = @_;

	my %ns_table=();

	# must scan the whole database of course :-(
	my $itr = $class->elements;
        while ( my $p = $itr->each_predicate ) {
                my $ns_uri = $p->getNamespace;

		next
			unless(defined $ns_uri);

		$ns_table{ $ns_uri } = 1
			unless(exists $ns_table{ $ns_uri });
		};

	return keys %ns_table;
	};

# tests if the model contains a given statement
sub contains {
        return 0
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
                	($_[1]->isa("RDFStore::Statement")) );

        croak "Statement context '".$_[2]."' is not instance of RDFStore::Resource"
                unless( (not(defined $_[2])) ||
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

	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		if(exists $_[0]->{query_iterator}) {
			return 0
                                if($_[0]->{query_iterator}->size <= 0); #got an empty query

                        # simply use the iterator we got from last query to quickly (??) check whether or not the st_id exists in the rdfstore; efficient, really??
                        return $_[0]->{query_iterator}->contains( $_[1], undef, undef, $context );
		} else {
			return ( $_[0]->find( $_[1]->subject, $_[1]->predicate, $_[1]->object, $context )->elements->size == 1 );
			};
		};

	return $_[0]->{rdfstore}->contains( $_[1], undef, undef, $context );
	};

# Model manipulation: add, remove, find
#
# NOTE: it is not really safe here - we might need to lock all DBs, add statement, unlock and return (TXP) :)
#
# Adds a new triple to the model
sub add {
        my ($class, $subject,$predicate,$object,$context) = @_;

        croak "Subject or Statement '".$subject."' is either not instance of RDFStore::Statement or RDFStore::Resource"
                unless( (defined $subject) &&
                        (ref($subject)) &&
                        (       ($subject->isa('RDFStore::Resource')) ||
                                ($subject->isa('RDFStore::Statement')) ) );
	croak "Predicate '".$predicate."' is not instance of RDFStore::Resource"
                unless( (not(defined $predicate)) ||
                        (       (defined $predicate) &&
                                (ref($predicate)) &&
                                ($predicate->isa('RDFStore::Resource')) ) );
        croak "Object '".$object."' is not instance of RDFStore::RDFNode"
                unless( (not(defined $object)) ||
                        ( ( (defined $object) &&
                              (ref($object)) &&
                              ($object->isa('RDFStore::RDFNode'))) ||
                            ( (defined $object) &&
                              ($object !~ m/^\s+$/) ) ) );

        croak "Statement context '".$context."' is not instance of RDFStore::Resource"
        	unless(	(not(defined $context)) ||
                        (       (defined $context) &&
                        	(ref($context)) &&
                                ($context->isa('RDFStore::Resource')) ) );

        if(     (defined $subject) &&
                (ref($subject)) &&
                ($subject->isa("RDFStore::Statement")) &&
		(not(defined $predicate)) &&
		(not(defined $object)) ) {
		$context = $subject->context
			unless(defined $context);
                ($subject,$predicate,$object) = ($subject->subject, $subject->predicate, $subject->object);
        } elsif(        (defined $object) &&
                        (!(ref($object))) ) {
                        $object = $class->{nodeFactory}->createLiteral($object);
        };

	if(     (exists $class->{Shared}) &&
                (defined $class->{Shared}) ) {
		if(exists $class->{query_iterator}) {
                        # simply use the iterator we got from last query to quickly (??) check whether or not the st_id exists in the rdfstore
                        # this should save the expensive _copyOnWrite() below eventually
                        return 0 #is it working also for empty queries???!
                                if ( $class->{query_iterator}->contains( $subject, $predicate, $object, $context ) );
                        };
		# copy across stuff if necessary
        	$class->_copyOnWrite();
        	};

	my $status = $_[0]->{rdfstore}->insert( $subject, $predicate, $object, $context );

        $class->updateDigest($subject,$predicate,$object,$context); #add context to updateDigest() as well???

	return $status;
	};

sub updateDigest {
	delete $_[0]->{digest};

      	#return
	#	unless(defined $_[0]->{digest});
	# see http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31
	#my $digest = $_[1]->getDigest();
      	#RDFStore::Util::Digest::xor($_[0]->getDigest(),$digest->getDigest());
	};

# Removes the triple from the model
# NOTE: it is not really safe here - we might need to lock all DBs, del statement, unlock and return (TXP) :)
sub remove {
        croak "Statement '".$_[1]."' is not instance of RDFStore::Statement"
                unless( (defined $_[1]) &&
                        (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Statement')) );

        croak "Statement context '".$_[2]."' is not instance of RDFStore::Resource"
                unless( (not(defined $_[2])) ||
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

	# copy across stuff if necessary
        $_[0]->_copyOnWrite()
		if(     (exists $_[0]->{Shared}) &&
                	(defined $_[0]->{Shared}) );
 
	my $status = $_[0]->{rdfstore}->remove( $_[1], undef, undef, $context );

        $_[0]->updateDigest($_[1]->subject, $_[1]->predicate, $_[1]->object, $context);

	return $status;
	};

sub isMutable {
	return 1;
	};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: $result = $m->find( undef, $RDFStore::Vocabulary::RDF::type, new RDFStore::Resource("http://...#MyClass"), [ context, words_operator, @words ] );
# finds all instances in the model
sub find {
        my ($class) = shift;
        my ($subject,$predicate,$object,$context,$words_operator,@words) = @_;

        croak "Subject '".$subject."' is not instance of RDFStore::Resource"
                unless(	(not(defined $subject)) ||
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

	# e.g. $class->find($subject,$predicate,$object)->find(....) and so on
	# NOTE: we are trying to improve this by avoiding DB operations using shared_ids of statements/properties.....
	if(     (exists $class->{Shared}) &&
                (defined $class->{Shared}) ) {
                $class->{Shared}->{sharing_query_iterator} = $class->{query_iterator}->duplicate
                        if(exists $class->{query_iterator});
                return $class->{Shared}->find($subject,$predicate,$object,$context,$words_operator,@words);
        };

	my @query = @_;
	$class->{query} = \@query;

        # we have the same problem like in Pen - a result set must be a model/collection :-)
        my $res = $class->create(); #EMPTY MODEL

	#skip 2 FETCHES for the moment - efficency
        #return $res
	#	if($class->{rdfstore}->is_empty());

	#share IDs till first write operation such as add() or remove() on query result model
	# NOTE: sharing avoid add() full-blown statements to the result model
	$res->{Shared}=$class;

	$res->setContext( $context ) #correct ???!!???
		if(defined $context);

        if(     (not(defined $subject)) &&
        	(not(defined $predicate)) &&
                (not(defined $object)) &&
                (not(defined $context)) &&
		($#words < 0) ) {
		# does NOT work for shared models yet!!!! - note: the duplicate() above could have fixed it :)
		if ( exists $class->{sharing_query_iterator}) {
                	$res->{query_iterator} = $class->{sharing_query_iterator};
                	delete $class->{sharing_query_iterator};

			return $res;
		} else {
			my $d = $class->duplicate();
			#$d->setContext( $context ) #correct???!??
			#	if(defined $context); #impossible
			return $d;
			};
		};

	#all non-words operators are set to 0=OR - will need 1=AND for real RDQL query
	my $query = {	'search_type' => 0, #default triple-pattern search
			"s" => [],
                        "s_op" => "or",
                        "p" => [],
                        "p_op" => "or",
                        "o" => [],
                        "o_op" => "or",
                        "c" => [],
                        "c_op" => "or",
                        "xml:lang" => [],
                        "xml:lang_op" => "or",
                        "rdf:datatype" => [],
                        "rdf:datatype_op" => "or"
                        };

	my @qq=();
	if($subject) {
		push @{$query->{'s'}}, $subject;
		};
	if($predicate) {
		push @{$query->{'p'}}, $predicate;
		};
	if($object) {
		push @{$query->{'o'}}, $object;
		#still need to add xml:lang and rdf:datatype for passed object here...
		};
	if($context) {
		push @{$query->{'c'}}, $context;
		};
	$query->{'words_op'} = (	(defined $words_operator) &&
					($words_operator =~ /(and|&|1)/i) ) ? 'and' :
					(       (defined $words_operator) &&
						($words_operator =~ /(not|~|2)/i) ) ? 'not' : 'or' ;

	push @{$query->{'words'}}, @words;

	my $iterator = $class->{rdfstore}->search( $query );

	if ( exists $class->{sharing_query_iterator}) {
                # intersect/diff the two iterators
		$res->{query_iterator} = $class->{sharing_query_iterator}->intersect( $iterator );
                delete $class->{sharing_query_iterator};
        } else {
                $res->{query_iterator} = $iterator;
                };

        return $res;
	};

sub fetch_object {
        my ($class,$resource,$context) = @_;

        croak "Resource '".$resource."' is not instance of RDFStore::Resource"
                unless(       (defined $resource) &&
                              (ref($resource)) &&
			      ($resource->isa('RDFStore::Resource')) );

        croak "Context '".$context."' is not instance of RDFStore::Resource"
                unless( (not(defined $context)) ||
                                (       (defined $context) &&
                                        (ref($context)) &&
                                        ($context->isa('RDFStore::Resource')) ) );

	return
		if( $resource->isbNode );

	# we have the same problem like in Pen - a result set must be a model/collection :-)
        my $res = $class->create(); #EMPTY MODEL

        #share IDs till first write operation such as add() or remove() on query result model
        # NOTE: sharing avoid add() full-blown statements to the result model
        $res->{Shared}=$class;

        $res->setContext( $context ) #correct ???!!???
                if(defined $context);

#print "FETCH --> ".$resource->toString."\n";
        $res->{query_iterator} = $class->{rdfstore}->fetch_object( ($resource->isa("RDFStore::Object")) ? $resource->{'rdf_object'} : $resource, $context );

	return $res;
	};

sub getResource {
        my ($class,$resource) = @_;

	my $object = new RDFStore::Object( $resource );
	$object->load( $class->fetch_object( $class->getNodeFactory->createResource($resource) ) );

	return $object; #return a new in-memory RDF object (and relative model)
	};

# clone the model - So due that copy is expensive we use sharing :)
sub duplicate {
	my ($class) = @_;

	return $class->{Shared}->duplicate
		if(     (exists $class->{Shared}) &&
                	(defined $class->{Shared}) );

        my $new = $class->create();

        # return a model that shares store and lookup with this model
        # delegate read operations till first write operation such as add() or remove()
	# NOTE: sharing avoid to copy right the way the whole original model that could be very large :)
	#       This trick allows to chain nicely find() methods
        $new->{Shared} = $class;

	# set default context if any was set
	my $sg = $class->getContext;
	$new->setContext( $sg )
        	if(defined $sg);
        return $new;
};

# Creates in-memory empty model with the same options but Sync
sub create {
        my($class) = shift;

        my $self = ref($class);
        my $new = $self->new(); #we also get empty RDFStore(3)

        return $new;
	};

sub getNodeFactory {
        return $_[0]->{nodeFactory};
	};

sub getLabel {
        return $_[0]->getURI;
	};

sub getURI {
        if($_[0]->isEmpty()) {
                return $_[0]->{nodeFactory}->createUniqueResource()->toString();
        } else {
                return "urn:rdf:".
				&RDFStore::Util::Digest::getDigestAlgorithm()."-".
                        	unpack("H*", $_[0]->getDigest() );
        	};
	};

sub getDigest {
        unless ( defined $_[0]->{digest} ) {
                sub digest_sorter {
                        my @a1 = unpack "c*",$a->getDigest();
                        my @b1 = unpack "c*",$b->getDigest();
                        my $i;
                        for ($i=0; $i < $#a1 +1; $i++) {
                                return $a1[$i] - $b1[$i] unless ord $a1[$i] == ord $b1[$i];
                        };
                        return 0;
                };
                my $t;
                my $digest_bytes;
		my ($el) = $_[0]->elements;
		my @sts = ();
		my $ss;
		for (	$ss = $el->first;
			$el->hasnext;
			$ss = $el->next ) {
			push @sts, $ss;
			};
                for  $t ( sort digest_sorter @sts ){ #this still fetches all statements in-memory :(
                        $digest_bytes .= $t->getDigest();
                	};
                $_[0]->{digest} = RDFStore::Util::Digest::computeDigest($digest_bytes);
        	};
        return $_[0]->{digest};
	};

#set operations on RDFStore::Model using RDFStore::Iterator (mostly efficient in-memory)
sub intersect {
	my ($class,$other) = @_;

	return
		unless($other);

	croak "Model '".$other."' is not instance of RDFStore::Model"
		unless( (defined $other) && (ref($other)) &&
			($other->isa('RDFStore::Model')) );

	croak "Models can not be intersected"
		unless(	( $class->{Shared} == $class->{Shared} ) ||
			( $class->{rdfstore} == $other->{rdfstore} ) );

        my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

	my $iter = $class->elements->intersect( $other->elements ); # that easy :)

	return
		unless($iter);

	$res->{query_iterator} = $iter->{iterator};

	# set default context if any was set
	my $sg = $class->getContext;
	$res->setContext( $sg )
        	if(defined $sg);

        return $res;
	};

sub subtract {
	my ($class,$other) = @_;

	return
		unless($other);

	croak "Model '".$other."' is not instance of RDFStore::Model"
		unless( (defined $other) && (ref($other)) &&
			($other->isa('RDFStore::Model')) );

	croak "Models can not be subtracted"
		unless(	( $class->{Shared} == $class->{Shared} ) ||
			( $class->{rdfstore} == $other->{rdfstore} ) );

	my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

        my $iter = $class->elements->subtract( $other->elements );

	return
		unless($iter);

	$res->{query_iterator} = $iter->{iterator};

        # set default context if any was set
        my $sg = $class->getContext;
        $res->setContext( $sg )
                if(defined $sg);

        return $res;
	};

sub unite {
	my ($class,$other) = @_;

	return
		unless($other);

	croak "Model '".$other."' is not instance of RDFStore::Model"
		unless( (defined $other) && (ref($other)) &&
			($other->isa('RDFStore::Model')) );

	croak "Models can not be united"
		unless(	( $class->{Shared} == $class->{Shared} ) ||
			( $class->{rdfstore} == $other->{rdfstore} ) );

	my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

        my $iter = $class->elements->unite( $other->elements );

	return
		unless($iter);

	$res->{query_iterator} = $iter->{iterator};

        # set default context if any was set
        my $sg = $class->getContext;
        $res->setContext( $sg )
                if(defined $sg);

        return $res;
	};

sub complement {
	my ($class) = @_;

	my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

        my $iter = $class->elements->complement;

	return
		unless($iter);

	$res->{query_iterator} = $iter->{iterator};

        # set default context if any was set
        my $sg = $class->getContext;
        $res->setContext( $sg )
                if(defined $sg);

        return $res;
	};

sub exor {
	my ($class,$other) = @_;

	return
		unless($other);

	croak "Model '".$other."' is not instance of RDFStore::Model"
		unless( (defined $other) && (ref($other)) &&
			($other->isa('RDFStore::Model')) );

	croak "EXOR can not be performed between the two given models"
		unless(	( $class->{Shared} == $class->{Shared} ) ||
			( $class->{rdfstore} == $other->{rdfstore} ) );

	my $res = $class->create(); #EMPTY MODEL in-memory

        $res->{Shared} = $class; # share storage (the other is sharing it anyway by definition :-)

        my $iter = $class->elements->exor( $other->elements ); # that easy :)

	return
		unless($iter);

	$res->{query_iterator} = $iter->{iterator};

        # set default context if any was set
        my $sg = $class->getContext;
        $res->setContext( $sg )
                if(defined $sg);

        return $res;
	};

#serialize the model/graph as string or to a filehandle using a specific syntax ("RDF/XML", "N-Triples")
sub serialize {
	my ($class, $fh, $syntax, $namespaces, $base ) = @_;

	my $serializer;
	if(	(! $syntax ) ||
		( $syntax =~ m#RDF/XML#i) ) {
		$serializer = new RDFStore::Serializer::RDFXML;
	} elsif( $syntax =~ m/N-Triples/i) {
		$serializer = new RDFStore::Serializer::NTriples;
	} else {
		croak "Unknown serialization syntax '$syntax'";
		};

	return
		unless($serializer);

	return $serializer->write( $class, $fh, $namespaces, $base );
};

sub getSerializer {
	my ($class) = shift;

	$class->getWriter(@_);
	};

sub getWriter {
	my ($class, $syntax) = @_;

	my $serializer;
	if(	(! $syntax ) ||
		( $syntax =~ m#RDF/XML#i) ) {
		$serializer = new RDFStore::Serializer::RDFXML;
	} elsif( $syntax =~ m/N-Triples/i) {
		$serializer = new RDFStore::Serializer::NTriples;
	} else {
		croak "Unknown serialization syntax '$syntax'";
		};

	$serializer->{'model'} = $class; #not sure is correct - perhaps we really need to spell it out in write() method

	return $serializer;
	};

sub getParser {
	my ($class) = shift;

	$class->getReader(@_);
	};

sub getReader {
	my ($class, $syntax) = @_;

	$class->{'GenidNumber'} = 0
		unless(exists $class->{'GenidNumber'});

	my $parser;
	if(	(! $syntax ) ||
		( $syntax =~ m#RDF/XML#i) ) {
		$parser = new RDFStore::Parser::SiRPAC(
					ErrorContext => 3,
					Style => 'RDFStore::Parser::Styles::RDFStore::Model',
					NodeFactory => $class->getNodeFactory,
					Source  => ($class->getSourceURI ) ? $class->getSourceURI : undef,
					GenidNumber => $class->{'GenidNumber'},
					'style_options' => { 'store_options' => { 'sourceModel' => $class } } );
	} elsif( $syntax =~ m/N-Triples/i) {
		$parser = new RDFStore::Parser::NTriples(
					ErrorContext => 3,
					Style => 'RDFStore::Parser::Styles::RDFStore::Model',
					NodeFactory => $class->getNodeFactory,
					Source  => ($class->getSourceURI ) ? $class->getSourceURI : undef,
					GenidNumber => $class->{'GenidNumber'},
					'style_options' => { 'store_options' => { 'sourceModel' => $class } } );
	} else {
		croak "Unknown RDF syntax '$syntax'";
		};

	return $parser;
	};

# Copy shared statements across; we do not set any context for them here bacause the add() below will do it eventually using the default context. Shared/virtual models are there for efficiency 
# only and can be only generated by a find() or duplicate(); in the former case the context eventually is the context of the query while in the latter is the contexnt of the model (default one).
# Those two other methods are setting/copying the right default context if necessary
sub _copyOnWrite {
	my($class) = @_;
 
	return
        	unless( (exists $class->{Shared}) &&
                	(defined $class->{Shared}) );

#print "Copying stuff across:\n";
                
        my ($shares) = $class->elements;

        #forget about being a query model if necessary :)
        delete($class->{query});
        if(exists $class->{query_iterator}) {
		delete($class->{query_iterator});
		};

        #break the sharing
        delete($class->{Shared});

	my $ss;
	for (	$ss = $shares->first;
		$shares->hasnext;
		$ss = $shares->next ) {
		#print "\tcopying('".$ss->toString."')\n";
                $class->add($ss); # what about context here in the cross-copy???
        	};

#print "\nDONE!\n";
};

# simple front-end to RDFStore::Iterator using a the given nodeFactory
package RDFStore::Model::Iterator;

use vars qw ( $VERSION );
use strict;

$VERSION = '0.1';

sub new {
	my ($pkg,$factory,$iterator) = @_;

	return
                unless(	(defined $iterator) &&
			(ref($iterator)) &&
			($iterator->isa("RDFStore::Iterator")) &&
			(defined $factory) &&
			(ref($factory)) &&
			($factory->isa("RDFStore::NodeFactory")) );

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
			($_[1]->isa("RDFStore::Model::Iterator")) );

	return new RDFStore::Model::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->intersect( $_[1]->{iterator} ) );
	};

sub unite {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Model::Iterator")) );

	return new RDFStore::Model::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->unite( $_[1]->{iterator} ) );
	};

sub subtract {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Model::Iterator")) );

	return new RDFStore::Model::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->subtract( $_[1]->{iterator} ) );
	};

sub complement {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Model::Iterator")) );

	return new RDFStore::Model::Iterator(	$_[0]->{factory},
						$_[0]->{iterator}->complement( $_[1]->{iterator} ) );
	};

sub exor {
	return
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Model::Iterator")) );

	return new RDFStore::Model::Iterator(	$_[0]->{factory},
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

RDFStore::Model - An implementation of the Model RDF API using tied hashes and implementing free-text search on literals

=head1 SYNOPSIS

	use RDFStore::NodeFactory;
	my $factory= new RDFStore::NodeFactory();
	my $statement = $factory->createStatement(
                        	$factory->createResource('http://perl.org'),
                        	$factory->createResource('http://iscool.org/schema/1.0/','label'),
                        	$factory->createLiteral('Cool Web site')
                                );
	my $statement1 = $factory->createStatement(
				$factory->createResource("http://www.altavista.com"),
				$factory->createResource("http://pen.jrc.it/schema/1.0/','author'),
				$factory->createLiteral("Who? :-)")
				);

	my $statement2 = $factory->createStatement(
				$factory->createUniqueResource(),
				$factory->createUniqueResource(),
				$factory->createLiteral("")
				);

	use RDFStore::Model;
	my $model = new RDFStore::Model( Name => 'store', FreeText => 1 );

	$model->add($statement);
	$model->add($statement1);
	$model->add($statement2);
	my $model1 = $model->duplicate();

	print $model1->getDigest->equals( $model1->getDigest );
	print $model1->getDigest->hashCode;

	my $found = $model->find($statement2->subject,undef,undef);
	my $found1 = $model->find(undef,undef,undef,undef,'Cool'); #free-text search on literals :)

	#get Statements
	foreach ( @{$found->elements} ) {
        	print $_->getLabel(),"\n";
	};

	#or faster
	my $fetch;
	foreach ( @{$found->elements} ) {
		my $fetch=$_;  #avoid too many fetches from RDFStore::Model::Statements
        	print $fetch->getLabel(),"\n";
	};

	#or
	my($statements)=$found1->elements;
	for ( 0..$#{$statements} ) {
                print $statements->[$_]->getLabel(),"\n";
        };

	#get RDFNodes
	foreach ( keys %{$found->elements}) {
        	print $found->elements->{$_}->getLabel(),"\n";
	};

	# set operations
        my $set = new RDFStore::Model( Name => 'setmodel' );

        $set=$set->interset($other_model);
        $set=$set->unite($other_model);
        $set=$set->subtract($other_model);

=head1 DESCRIPTION

An RDFStore::Model implementation using RDFStore(3) to store triplets.

=head1 CONSTRUCTORS
 
The following methods construct/tie RDFStore::Model storages and objects:

=item $model = new RDFStore::Model( %whateveryoulikeit );
 
Create an new RDFStore::Model object and tie up the RDFStore(3). The %whateveryoulikeit hash contains a set of configuration options about how and where store actual data.

Possible additional options are the following:

=over 4

=item Name
 
This is a label used to identify a B<Persistent> storage by name. It might correspond to a physical file system directory containing the indexes DBs. By default if no B<Name> option is given the storage is assumed to be B<in-memory> (e.g. RDFStore::Storage::find method return result sets as in-memory models by default unless specified differently). For local persistent storages a directory named liek this option is created in the current working directory with mode 0666)

=item Sync

Sync the RDFStore::Model with the underling Data::MagciTie GDS after each add() or remove().

=item FreeText

Enable free text searching on literals over a model (see B<find>)

=head1 SEE ALSO

Digest(3) RDFStore(3) RDFStore::Digest::Digestable(3) RDFStore::Digest(3) RDFStore::RDFNode(3) RDFStore::Resource(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
