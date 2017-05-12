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
# *     version 0.1 - Tue Jan 28 15:30:00 CET 2003
# *     version 0.2
# *     	- fixed bug when model context is set
# *

package RDFStore::Serializer::RDFXML;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.2';

use Carp;

use RDFStore::Serializer;

@RDFStore::Serializer::RDFXML::ISA = qw( RDFStore::Serializer );

sub new {
	my ($pkg) = shift;

	my $self = $pkg->SUPER::new(@_);

	bless $self,$pkg;
	};

sub write {
	my ($class, $model, $fh, $namespaces, $base ) = @_;

	$model = $class->{'model'}
		unless($model);

	# ignore model its context while dumping
	my $ctx = $model->getContext();
	$model->resetContext();

	# init
	$class->SUPER::write( $model, $fh, $namespaces );

	$class->{subjects_done} = {};

	# header
        $class->printContent( "<" . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":RDF" );
        $class->printContent( "\n\txmlns:" . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . "='". $RDFStore::Vocabulary::RDF::_Namespace . "'");
	
	# rdfstore namespace is alwasys put there
        $class->printContent( "\n\txmlns:" . $class->getNamespacePrefix($RDFStore::Vocabulary::RDFStoreContext::_Namespace) . "='". $RDFStore::Vocabulary::RDFStoreContext::_Namespace . "'");

        $class->printContent( "\n\txml:base='$base'")
		if(	(defined $base) &&
			($base ne '') );

        my $cc=0;
	foreach my $ns ( $model->namespaces ) {
		next
			if( $ns eq $RDFStore::Vocabulary::RDF::_Namespace );

		$class->setNamespacePrefix( $ns, 'voc'.($cc++) )
			unless( $class->getNamespacePrefix( $ns ) );

        	$class->printContent( "\n\txmlns:" . $class->getNamespacePrefix($ns) . "='". $ns . "'");
                };
        $class->printContent( ">");

	# we should try to group descriptions about the same thing (same subject)
	my $itr = $model->elements;
	while ( my $st = $itr->each ) {
		$class->_processDescription( $model, $st );
		};

	# footer
	$class->printContent( "\n</" .    $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":RDF>" );

	$class->{subjects_done} = {};

	# restore context
	$model->setContext( $ctx )
		if($ctx);

        return $class->returnContent;
	};

sub _processDescription {
	my ($class, $model, $statement ) = @_;

	my $context = $statement->context;
	my $ctx = $context->toString
		if($context);

	return
		if(exists $class->{subjects_done}->{ $statement->subject->toString . $ctx });

	$class->{subjects_done}->{ $statement->subject->toString . $ctx } = 1; # for very large model this might be a problem!!

	# group by subject in context
	my $itr = $model->find( $statement->subject, undef, undef, $context )->elements;

	return
		unless($itr->size > 0 );

        $class->printContent( "\n<" . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":Description " );
	if ( $statement->subject->isbNode ) {
        	$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":nodeID='" . $statement->subject->getLabel );
        } else {
        	$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":about='" . $class->xml_escape( $statement->subject->getURI,"'" ) );
        	};
	if ( $context ) {
		if ( $context->isbNode ) {
        		$class->printContent( "' " . $class->getNamespacePrefix($RDFStore::Vocabulary::RDFStoreContext::_Namespace) . ":contextnodeID='" . $context->getLabel );
        	} else {
        		$class->printContent( "' " . $class->getNamespacePrefix($RDFStore::Vocabulary::RDFStoreContext::_Namespace) . ":context='" . $class->xml_escape( $context->getURI,"'" ) );
        		};
		};
        $class->printContent("'>");
	
	# properly un-asserted statement?
	if (	($statement->subject->isa("RDFStore::Statement")) &&
		(! $model->contains( $statement->subject) ) ) { #it must be un-asserted
		$class->printContent( "\n\t<" .     $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":type " .
                                                $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":resource='".$RDFStore::Vocabulary::RDF::_Namespace ."Statement' />");

                $class->printContent( "\n\t<" .   $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":subject ");
		if ( $statement->subject->subject->isbNode ) {
                	$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":nodeID='" . $statement->subject->subject->getLabel );
        	} else {
                	$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":resource='" . $class->xml_escape( $statement->subject->subject->getURI,"'" ) );
                	};
                $class->printContent( "' />");
                $class->printContent( "\n\t<" .   $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":predicate ");
                $class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":resource='" . $class->xml_escape( $statement->subject->predicate->getURI,"'" ) . "' />" );

                $class->printContent( "\n\t<" .   $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":object ");
		if( $statement->subject->object->isa("RDFStore::Resource") ) {
			if ( $statement->subject->object->isbNode ) {
                		$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":nodeID='" . $statement->subject->object->getLabel );
        		} else {
                		$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":resource='" . $class->xml_escape( $statement->subject->object->getURI,"'" ) );
                		};
                	$class->printContent( "' />");
                } else {
        		$class->printContent( "xml:lang='" . $statement->subject->object->getLang . "'")
				if($statement->subject->object->getLang);
			if($statement->subject->object->getParseType) {
        			$class->printContent( " " . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":parseType='Literal'>");
        			$class->printContent( $statement->subject->object->getLabel );
			} else {
        			$class->printContent( " rdf:datatype='" . $statement->subject->object->getDataType . "'")
					if($statement->subject->object->getDataType);
        			$class->printContent( ">" . $class->xml_escape( $statement->subject->object->getLabel ) );
				};
                	$class->printContent( "</" .   $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":object>");
                	};
		};
	
	while ( my $st = $itr->each ) {
        	$class->printContent( "\n\t<" . $class->getNamespacePrefix( $st->predicate->getNamespace ).":".$st->predicate->getLocalName );
        	$class->printContent( " " . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":ID='" . $st->getURI . "'" )
			if( $st->isReified );

		if( $st->object->isa("RDFStore::Resource") ) {
        		$class->printContent( " " );
			if ( $st->object->isbNode ) {
                		$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":nodeID='" . $st->object->getLabel );
        		} else {
                		$class->printContent( $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":resource='" . $class->xml_escape( $st->object->getURI,"'" ) );
                		};
        		$class->printContent( "' />" );
		} else {
        		$class->printContent( " xml:lang='" . $st->object->getLang . "'")
				if($st->object->getLang);
			if($st->object->getParseType) {
        			$class->printContent( " " . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":parseType='Literal'>");
        			$class->printContent( $st->object->getLabel );
			} else {
        			$class->printContent( " rdf:datatype='" . $st->object->getDataType . "'")
					if($st->object->getDataType);
        			$class->printContent( ">" . $class->xml_escape( $st->object->getLabel ) );
				};
        		$class->printContent( "</" . $class->getNamespacePrefix( $st->predicate->getNamespace ) .":".$st->predicate->getLocalName . ">" );
			};
		};
        $class->printContent( "\n</" . $class->getNamespacePrefix($RDFStore::Vocabulary::RDF::_Namespace) . ":Description>" );

	if ($statement->subject->isa("RDFStore::Statement")) {
		if (	($statement->subject->subject->isa("RDFStore::Statement")) &&
			(! $model->contains( $statement->subject->subject) ) ) {
			$class->_processDescription( $model, $statement->subject );
			};
		if (	($statement->subject->object->isa("RDFStore::Statement")) &&
			(! $model->contains( $statement->subject->object) ) ) {
			$class->_processDescription( $model, $statement->object );
			};
		};
	};

1;
};

__END__

=head1 NAME

RDFStore::Serilizer::RDFXML - Serialise a model/graph to W3C RDF/XML syntax

=head1 SYNOPSIS

	use RDFStore::Serializer::RDFXML;

        my $model= new RDFStore::Model();
        $model->add($statement);
        $model->add($statement1);
        $model->add($statement2);

        my $serializer = new RDFStore::Serializer::RDFXML;

        my $rdf_strawman = $serializer->serialize( $model ); # serialise model to a string in-memory
	my $rdf_strawman = $serializer->serialize( $model, undef, {}, $base ); # using xml:base
        my $rdf_strawman = $serializer->serialize( $model, undef, { 'http://mynamespace.org/blaaa/' => blaa } ); # using my blaa namespace

        $serializer->serialize( $model, *STREAM ); # serialise model to a given descriptor (stream)

=head1 DESCRIPTION

An RDFStore::Model serializer to W3C RDF/XML syntax - see http://www.w3.org/TR/rdf-syntax-grammar/

=head1 CONSTRUCTORS
 
The following methods construct RDFStore::Serializer::RDFXML :

=item new ()

 Create an new RDFStore::Serializer object to serialize and RDFStore::Model.

=head1 METHODS

=item write ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )

 Write out the given MODEL to FILEHANDLE_REF (or in-memory string if not passed) using a given list of NAMESPACES and xml:base BASE if passed. The NAMESPACES hash ref contains a list of namespace values (URI refs) and prefix names - see RDFStore::Vocabulary::Generator(3). By default the output is returned from the method into a string otheriwse a valid (and opened) FILEHANLDE_REF can be passed, which will be being printed to.

=item serialize ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )

 Same as write method above.

=head1 SEE ALSO

 RDFStore::Model(3) RDFStore::Serializer(3)

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
