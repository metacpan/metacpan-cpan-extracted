package TEI::Lite::Document;

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;

use strict;
use warnings;

use Carp;
use XML::LibXML;
use TEI::Lite::Element;
use I18N::LangTags qw( is_language_tag );

our $AUTOLOAD;

our $VERSION = "0.60";

##==================================================================##
##  Constructor(s)/Deconstructor(s)                                 ##
##==================================================================##

##----------------------------------------------##
##  new                                         ##
##----------------------------------------------##
sub new
{
	## Pull in what type of an object we will be.
	my $type = shift;
	## Grab a copy of our parameters.
	my %params = @_;
	## Declare a variable that will later become our object instance.
	my $self;
	## Check to see if a filename is defined, if it is then attempt to load
	## it ... otherwise just init a blank object.
	if( defined( $params{ 'Filename' } ) )
	{
		$self = _load_teilite_file( %params );
	}
	elsif( defined( $params{ 'String' } ) )
	{
		$self = _load_teilite_string( %params );
	}
	else
	{
		$self = _init_object_instance( %params );
	}
	## Determine what exact class we will be blessing this instance into.
	my $class = ref( $type ) || $type;
	## Bless the class for it is good [tm].
	bless( $self, $class );
	## Send it back to the caller all happy like.
	return( $self );
}

##----------------------------------------------##
##  DESTROY                                     ##
##----------------------------------------------##
sub DESTROY
{
	## This is mainly a placeholder to keep things like mod_perl happy.
	return;
}

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

##----------------------------------------------##
##  addBackMatter                               ##
##----------------------------------------------##
sub addBackMatter
{
	my $self = shift;

	## We need to look to see if we are a corpus document.
	if( $self->{ "Corpus" } != 0 )
	{
		croak( "Corpus documents do not contain back matter." );
	}

	## Look to see if a back matter is already defined for this active text.
	if( !defined( $self->{ "back" }->{ $self->{ "active" } } ) )
	{
		## Create the back matter element.
		my $back = tei_back();

		## Insert the back matter after the body element.
		$self->{ "text" }->{ $self->{ "active" } }->appendChild( $back );

		## Stick a reference into the hash tree.
		$self->{ "back" }->{ $self->{ "active" } } = $back;

		return( $back );
	}	
	else
	{
		carp( "The specified text has a pre-existing back element. " .
			  "Only one back element may exist per text. " );
	
	  	return;
	}
}

##----------------------------------------------##
##  addCompositeBackMatter                      ##
##----------------------------------------------##
sub addCompositeBackMatter
{
	my $self = shift;

	## Do some error checking ...
	if( ( $self->{ "Corpus" } != 0 ) || ( $self->{ "Composite" } != 0 ) )
	{
		croak( "This method only works on TEI composite documents." );
	}

	## Look to see if a back matter is already defined for this active text.
	if( !defined( $self->{ "back" }->{ "Composite" } ) )
	{
		## Create the back matter element.
		my $back = tei_back();

		## Find the top text node and the last child of that node.
		my( $node ) = $self->{DOM}->findnodes( '//TEI.2/text' );

		## Append the back element onto the text node.
		$node->appendChild( $back );

		## Stick a reference into the hash tree.
		$self->{ "back" }->{ $self->{ "Composite" } } = $back;

		return( $back );
	}
	else
	{
		carp( "The specified text has a pre-existing composite back element. " .
			  "Only one back element may exist per composite document. " );
	
	  	return;
	}
}

##----------------------------------------------##
##  addCompositeFrontMatter                     ##
##----------------------------------------------##
sub addCompositeFrontMatter
{
	my $self = shift;

	## Do some error checking ...
	if( ( $self->{ "Corpus" } != 0 ) || ( $self->{ "Composite" } != 0 ) )
	{
		croak( "This method only works on TEI composite documents." );
	}

	## Look to see if a back matter is already defined for this active text.
	if( !defined( $self->{ "front" }->{ "Composite" } ) )
	{
		## Create the back matter element.
		my $front = tei_front();

		## Find the top text node and the first child of that node.
		my( $node ) = $self->{DOM}->findnodes( '//TEI.2/text' );
		my $child = $node->firstChild;
		
		## Insert the front element before all the rest of the child nodes.
		$node->insertBefore( $front, $child );

		## Stick a reference into the hash tree.
		$self->{ "front" }->{ $self->{ "Composite" } } = $front;

		return( $front );
	}
	else
	{
		carp( "The specified text has a pre-existing composite " .
			  "front element. Only one back element may exist per " .
			  "composite document. " );
	
	  	return;
	}
}

##----------------------------------------------##
##  addDocument                                 ##
##----------------------------------------------##
sub addDocument
{
	my $self = shift;
	
	## Do some error checking to ensure that we are operating on a
	## corpus document.
	if( $self->{ "Corpus" } == 0 )
	{
		croak( "Can only add additional documents to TEI corpus documents." );
	}
	
	## Create a new TEI document.
	$self->{ "document" }->{ $self->{ "Corpus" } } =
		TEI::Lite::Document->new();
	
	## Add the document to the corpus DOM.
	$self->{ "DOM" }->documentElement->appendChild( 
		$self->{ "document" }->{ $self->{ "Corpus" } }->documentElement() );
	
	##  Increment the corpus document count.
	$self->{ "Corpus" }++;

	## Return the new corpus document count.
	return( $self->{ "Corpus" } );
}

##----------------------------------------------##
##  addFrontMatter                              ##
##----------------------------------------------##
sub addFrontMatter
{
	my $self = shift;

	## We need to look to see if we are a corpus document.
	if( $self->{ "Corpus" } != 0 )
	{
		croak( "Corpus documents do not contain front matter." );
	}

	## Look to see if a back matter is already defined for this active text.
	if( !defined( $self->{ "front" }->{ $self->{ "active" } } ) )
	{
		## Create the back matter element.
		my $front = tei_front();

		## Insert the back matter after the body element.
		$self->{ "text" }->{ $self->{ "active" } }->
			insertBefore( $front, $self->{ "body" }->{ $self->{ "active" } } );

		## Stick a reference into the hash tree.
		$self->{ "front" }->{ $self->{ "active" } } = $front;

		return( $front );
	}	
	else
	{
		carp( "The specified text has a pre-existing back element. " .
			  "Only one back element may exist per text. " );
	
	  	return;
	}
}

##----------------------------------------------##
##  addHeader                                   ##
##----------------------------------------------##
sub addHeader
{
	my $self = shift;

	## Determine what type of header we are adding.
	if( $self->{ "Corpus" } != 0 )
	{
		## Call the default constructor for a TEI::Lite::Header.
		my $header = TEI::Lite::Header->new( Type	=> 'Corpus' );
		
		## Stick a reference to this in the document hash for easy
		## access later.
		$self->{ "header" } = $header;
	
		## Find the root element of a document.
		my $root = shift( @{ $self->{ "DOM" }->find( "teiCorpus.2" ) } );
	
		## We need to find the firstChild of this root element.
		my $child = $root->firstChild;
	
		## Finally insert into the document before the firstChild.
		$root->insertBefore( $header, $child );

		return( $header );
	}
	else
	{
		## Call the default constructor for a TEI::Lite::Header.
		my $header = TEI::Lite::Header->new();
	
		## Stick a reference to this in the document hash for easy
		## access later.
		$self->{ "header" } = $header;
	
		## Find the root element of a document.
		my $root = shift( @{ $self->{ "DOM" }->find( "TEI.2" ) } );
	
		## We need to find the firstChild of this root element.
		my $child = $root->firstChild;
	
		## Finally insert into the document before the firstChild.
		$root->insertBefore( $header, $child );
	
		return( $header );
	}
}

##----------------------------------------------##
##  addText                                     ##
##----------------------------------------------##
sub addText
{
	my $self = shift;
	
	if( ( $self->{ "Corpus" } != 0 ) || ( $self->{ "Composite" } == 0 ) )
	{
		croak( "Can only add additional texts to a TEI composite document." );
	}
			
	## Create a new text node for inclusion ...
	$self->{ "text" }->{ $self->{ "Composite" } } = tei_text();
	
	## Find the group element in the DOM tree.
	my( $node ) = $self->{ "DOM" }->findnodes( '//TEI.2/text/group' );
	
	## Append the child into the tree.
	$node->appendChild( $self->{ "text" }->{ $self->{ "Composite" } } );
	
	##  Increment the corpus document count.
	$self->{ "Composite" }++;

	## Return the new corpus document count.
	return( $self->{ "Composite" } );
} 

##----------------------------------------------##
##  AUTOLOAD                                    ##
##----------------------------------------------##
sub AUTOLOAD
{
	my $self = shift;
	
	## Pull in AUTOLOAD ...
	my $function = ( split( /::/, $AUTOLOAD ) )[3];
	
	## Return the AUTOLOAD call on the DOM tree.
	return( $self->{ "DOM" }->$function( @_ ) );
}

##----------------------------------------------##
##  getActiveDocument                           ##
##----------------------------------------------##
sub getActiveDocument
{
	my $self = shift;

	if( $self->{ "Corpus" } == 0 )
	{
		croak( "TEI composite and unitary documents do not contain other " .
			   "TEI documents."	);
	}

	## Return the active text ...
	return( $self->{ "active" } );
}

##----------------------------------------------##
##  getActiveText                               ##
##----------------------------------------------##
sub getActiveText
{
	my $self = shift;

	if( $self->{ "Corpus" } != 0 )
	{
		croak( "TEI corpus documents do not contain texts." );
	}

	## Return the active text ...
	return( $self->{ "active" } );
}

##----------------------------------------------##
##  getBackMatter                               ##
##----------------------------------------------##
sub getBackMatter
{
	my $self = shift;

	if( $self->{ "Corpus" } != 0 )
	{
		carp( "TEI corpus documents do not directly contain back matter. " .
			  "Please acccess each individual document contained within " .
			  "the corpus document to get the back matter for that " .
			  "document." );
	}

	return( $self->{ "back" }->{ $self->{ "active" } } );
}

##----------------------------------------------##
##  getBody                                     ##
##----------------------------------------------##
sub getBody
{
	my $self = shift;

	if( $self->{ "Corpus" } != 0 )
	{
		carp( "TEI corpus documents do not directly contain body elements. " .
			  "Please acccess each individual document contained within " .
			  "the corpus document to get the body elements for that " .
			  "document." );
	}
	
	return( $self->{ "body" }->{ $self->{ "active" } } );
}

##----------------------------------------------##
##  getCompositeBackMatter                      ##
##----------------------------------------------##
sub getCompositeBackMatter
{
	my $self = shift;

	if( $self->{ "Corpus" } != 0 )
	{
		carp( "TEI corpus documents do not directly contain back matter. " .
			  "Please acccess each individual document contained within " .
			  "the corpus document to get the back matter for that " .
			  "document." );
	}

	return( $self->{ "back" }->{ $self->{ "Composite" } } );
}

##----------------------------------------------##
##  getCompositeFrontMatter                     ##
##----------------------------------------------##
sub getCompositeFrontMatter
{
	my $self = shift;

	if( $self->{ "Corpus" } != 0 )
	{
		carp( "TEI corpus documents do not directly contain front matter. " .
			  "Please acccess each individual document contained within " .
			  "the corpus document to get the front matter for that " .
			  "document." );
	}

	return( $self->{ "front" }->{ $self->{ "Composite" } } );
}

##----------------------------------------------##
##  getDocument                                 ##
##----------------------------------------------##
sub getDocument
{
	my $self = shift;

	## We need to do a simple sanity check.
	if( $self->{ "Corpus" } == 0 )
	{
		croak( "TEI corpus documents are the only document type containing " .
			   "other TEI documents. " );
	}
	
	## Return the document associated with the value in "active".
	return( $self->{ "document" }->{ $self->{ "active" } } );
}

##----------------------------------------------##
##  getDocuments                                ##
##----------------------------------------------##
sub getDocuments
{
	my $self = shift;

	## We need to do a simple sanity check.
	if( $self->{ "Corpus" } == 0 )
	{
		croak( "TEI corpus documents are the only document type containing " .
			   "other TEI documents. " );
	}
	
	## Declare a variable to hold our results.
	my @documents;

	## Loop through each of the documents and return a reference to
	## that document.
	foreach( keys( %{ $self->{ "document" } } ) )
	{
		push( @documents, $self->{ "document" }->{ $_ } );
	}

	## If we call ourselves in a scalar context, return the
	## number of corpus documents.
	return( wantarray ? @documents : scalar( @documents ) );
}

##----------------------------------------------##
##  getDocumentLang                             ##
##----------------------------------------------##
sub getDocumentLang
{
	my $self = shift;

	return( $self->{ "DOM" }->documentElement->getAttribute( "lang" ) );
}

##----------------------------------------------##
##  getFrontMatter                              ##
##----------------------------------------------##
sub getFrontMatter
{
	my $self = shift;
	
	if( $self->{ "Corpus" } != 0 )
	{
		carp( "TEI corpus documents do not directly contain front matter. " .
			  "Please acccess each individual document contained within " .
			  "the corpus document to get the front matter for that " .
			  "document." );
	}

	return( $self->{ "front" }->{ $self->{ "active" } } );
}

##----------------------------------------------##
##  getHeader                                   ##
##----------------------------------------------##
sub getHeader
{
	my $self = shift;

	return( $self->{ "header" } );
}

##----------------------------------------------##
##  getText                                     ##
##----------------------------------------------##
sub getText
{
	my $self = shift;

	## Do some basic error checking ...
	if( $self->{ "Corpus" } != 0 )
	{
		croak( "TEI composite and unitary documents are the only document " .
			   "types of the TEI specification that contain texts." );
	}
	
	## Declare a variable to hold our results.
	my @texts;

	return( $self->{ "text" }->{ $self->{ "active" } } );
}

##----------------------------------------------##
##  getTexts                                    ##
##----------------------------------------------##
sub getTexts
{
	my $self = shift;

	## Do some basic error checking ...
	if( $self->{ "Corpus" } != 0 )
	{
		croak( "TEI composite and unitary documents are the only document " .
			   "types of the TEI specification that contain texts." );
	}
	
	## Declare a variable to hold our results.
	my @texts;

	## Loop through each of the texts and return a reference to
	## that document.
	foreach( keys( %{ $self->{ "text" } } ) )
	{
		push( @texts, $self->{ "text" }->{ $_ } );
	}

	## If we call ourselves in a scalar context, return the
	## number of corpus texts.
	return( wantarray ? @texts : scalar( @texts ) );
}

##----------------------------------------------##
##  setActiveDocument                           ##
##----------------------------------------------##
sub setActiveDocument
{
	my( $self, $active ) = @_;

	## If the passed in $active modifier is not a number,
	## then that is obviously an error.
	if( $active !~ /^\d+$/ )
	{
		croak( "The specified active document must be in numeric form." );
	}
		
	## Corpus texts do not have active documents as they
	## are viewed as Document object containing more
	## document objects.
	if( $self->{ "Corpus" } == 0 )
	{
		croak( "TEI corpus documents are the only document type containing " .
			   "other TEI documents." );
	}

	## If our $active text is greater then the number of
	## texts in our composite document, then that is
	## obviously an error.
	if( $self->{ "Corpus" } < $active )
	{
		croak( "The specified active document does not exist in this TEI " .
			   "corpus document." );
	}

	## Set the instance variable ...
	$self->{ "active" } = $active;

	return( $self->{ "active" } );
}

##----------------------------------------------##
##  setActiveText                               ##
##----------------------------------------------##
sub setActiveText
{
	my( $self, $active ) = @_;

	## If the passed in $active modifier is not a number,
	## then that is obviously an error.
	if( $active !~ /^\d+$/ )
	{
		croak( "The specified active text must be in numeric form." );
	}
		
	## Corpus texts do not have active documents as they
	## are viewed as Document object containing more
	## document objects.
	if( $self->{ "Corpus" } > 0 )
	{
		croak( "TEI composite and unitary documents are the only document " .
			   "types containing other texts." );
	}

	## If our $active text is greater then the number of
	## texts in our composite document, then that is
	## obviously an error.
	if( $self->{ "Composite" } < $active )
	{
		croak( "The specified active text does not exist in this " .
	   		   "TEI document." );
	}

	## Set the instance variable ...
	$self->{ "active" } = $active;

	return( $self->{ "active" } );
}

##----------------------------------------------##
##  setDocumentLang                             ##
##----------------------------------------------##
sub setDocumentLang
{
	my( $self, $lang ) = @_;

	if( is_language_tag( $lang ) )
	{
		$self->{ "DOM" }->documentElement->setAttribute( "lang", $lang );
		return( 1 );
	}

	return( 0 );
}

##==================================================================##
##  Internal Function(s)                                            ##
##==================================================================##

##----------------------------------------------##
##  _init_object_instance                       ##
##----------------------------------------------##
##  Internal function to initialize the object  ##
##  instance.                                   ##
##----------------------------------------------##
sub _init_object_instance
{
	## Pull in the parameters ...
	my %params = @_;
	
	## Create an anonymous hash to hold the basis of our object.
	my $self = {};

	## We also define some variables that we will fill in later.
	my( $root_node );
	
	## We need to clean up our two main augmentation parameters.

	## Clean up the Corpus modifier ...
	## Corpus: 0 == false, # > 0 = Number of combined texts
	if( defined( $params{ "Corpus" } ) )
	{
		$params{ "Corpus" } = 0 if( $params{ "Corpus" } < 0 );
	}
	else
	{
		$params{ "Corpus" } = 0;
	}
	
	## Stick it in our hash object.
	$self->{ "Corpus" } = $params{ "Corpus" };
	
	## Clean up the Composite modifier ...
	## Composite: 0 == false, # > 0 = Number of group "segments"
	if( defined( $params{ "Composite" } ) )
	{
		$params{ "Composite" } = 0 if( $params{ "Composite" } < 0 );		
	}
	else
	{
		$params{ "Composite" } = 0;
	}
	
	## Stick it in our hash object.
	$self->{ "Composite" } = $params{ "Composite" };
	
	## Begin the construction of our internal DOM tree ...
	$self->{ "DOM" } = XML::LibXML::Document->new( "1.0", "UTF8" );
	
	if( $params{ "Corpus" } > 0 )
	{
		$root_node = XML::LibXML::Element->new( "teiCorpus.2" );
	}
	else
	{
		$root_node = XML::LibXML::Element->new( "TEI.2" );
	}

	## Make the $root_node the real root node.
	$self->{ "DOM" }->setDocumentElement( $root_node );

	## Now we need to setup the rest of the basic document based on the
	## given parameters.
	if( $params{ "Corpus" } > 0 )
	{
		## TEI Corpus Document
		foreach( my $loop = 0; $loop < $params{ "Corpus" }; $loop++ )
		{
			$self->{ "document" }->{ $loop } = TEI::Lite::Document->new();
			$root_node->appendChild( 
					$self->{ "document" }->{ $loop }->documentElement() );
		}

	}
	elsif( $params{ "Composite" } > 0 )
	{
		my $text = tei_text();
		my $group = tei_group();

		foreach( my $loop = 0; $loop < $params{ "Composite" }; $loop++ )
		{
			$self->{ "text" }->{ $loop } = tei_text();
			$self->{ "body" }->{ $loop } = tei_body();
			$self->{ "text" }->{ $loop }->
				appendChild( $self->{ "body" }->{ $loop } );
			$group->appendChild( $self->{ "text" }->{ $loop } );
		}

		$root_node->appendChild( $text );
		$text->appendChild( $group );
	}
	else
	{
		## TEI Unitary Document
		$self->{ "text" }->{ "0" } = tei_text();
		$self->{ "body" }->{ "0" } = tei_body();
		$self->{ "text" }->{ "0" }->appendChild( $self->{ "body" }->{ "0" } );
		$root_node->appendChild( $self->{ "text" }->{ "0" } );
	}

	## Setup a default text to be active ... as in all operations by
	## default act upon this text.
	$self->{ "active" } = 0;
	
	## Return what we have constructed.
	return( $self );
}

##----------------------------------------------##
##  _load_teilite_file                          ##
##----------------------------------------------##
##  Attempts to load a document that is in the  ##
##  TEILite schema format.                      ##
##----------------------------------------------##
sub _load_teilite_file
{
	my %params = @_;
	
	## We need a variable to hold our instance variable.
	my $self = {};
	
	## Create an instance of the LibXML parser to load the file.
	my $parser = XML::LibXML->new();

	## Attempt to load the file.
	my $doc = $parser->parse_file( $params{ 'Filename' } );

	## Grab the document element ...
	my $root = $doc->getDocumentElement();

	## Determine whaat type of document we are working with now.
	if( $root->nodeName eq "teiCorpus.2" )
	{
		$self = _parse_teicorpus_document( $doc );
	}
	elsif( $root->nodeName eq "TEI.2" )
	{
		$self = _parse_tei_document( $doc );
	}
	else
	{
		croak( "The specified file is not a recognized TEILite document.\n" );
	}
	
	return( $self );
}

##----------------------------------------------##
##  _load_teilite_string                        ##
##----------------------------------------------##
##  Attempts to load a document that is in the  ##
##  TEILite schema format.                      ##
##----------------------------------------------##
sub _load_teilite_string
{
	my %params = @_;
	
	## We need a variable to hold our instance variable.
	my $self = {};
	
	## Create an instance of the LibXML parser to load the file.
	my $parser = XML::LibXML->new();

	## Attempt to load the file.
	my $doc = $parser->parse_string( $params{ 'String' } );

	## Grab the document element ...
	my $root = $doc->getDocumentElement();

	## Determine whaat type of document we are working with now.
	if( $root->nodeName eq "teiCorpus.2" )
	{
		$self = _parse_teicorpus_document( $doc );
	}
	elsif( $root->nodeName eq "TEI.2" )
	{
		$self = _parse_tei_document( $doc );
	}
	else
	{
		croak( "The specified file is not a recognized TEILite document.\n" );
	}

	return( $self );
}

##----------------------------------------------##
##  _parse_tei_document                         ##
##----------------------------------------------##
##  Function to break-apart a TEILite document  ##
##  into the instance variable structure.       ##
##----------------------------------------------##
sub _parse_tei_document
{
	my $doc = shift;

	## We use an anonymous hash as our internal structure.
	my $self = {};
	
	## Grab the root element of the document.
	my $root = $doc->getDocumentElement();

	## We set the entire DOM tree into the DOM key.
	$self->{ "DOM" } = $doc;
	
	## We are not a corpus document.
	$self->{ "Corpus" } = 0;

	## We now need to determine if we are a composite or unitary document.
	my( @texts ) = $root->findnodes( "//text" );

	## Loop through each of the texts loading them into our internal struct.
	for( my $i = 0; $i < scalar( @texts ); $i++ )
	{
		## Set the Composite document counter.
		$self->{ "Composite" } = $i;

		## Set the base "text" element.
		$self->{ "text" }->{ $i } = $texts[ $i ];

		## Grab the children of the text element.
		my( @children ) = $texts[ $i ]->childNodes;

		foreach( @children )
		{
			if( $_->nodeName eq "front" )
			{
				$self->{ "front" }->{ $i } = $_;
			}
			elsif( $_->nodeName eq "body" )
			{
				$self->{ "body" }->{ $i } = $_;
			}
			elsif( $_->nodeName eq "back" )
			{
				$self->{ "back" }->{ $i } = $_;
			}
		}
	}
	
	return( $self );
}

##----------------------------------------------##
##  _parse_teicorpus_document                   ##
##----------------------------------------------##
##  Function to break-apart a TEILite document  ##
##  into the instance variable structure.       ##
##----------------------------------------------##
sub _parse_teicorpus_document
{
	my $doc = shift;

	## We use an anonymous hash as our internal structure.
	my $self = {};
	
	## We set the entire DOM tree into the DOM key.
	$self->{ "DOM" } = XML::LibXML::Document->new();
	
	my $root = XML::LibXML::Element->new( "teiCorpus.2" );
	
	$self->{ "DOM" }->setDocumentElement( $root );
	
	## We are not a composite document.
	$self->{ "Composite" } = 0;

	## We now need to determine if we are a composite or unitary document.
	my( @texts ) = $doc->getDocumentElement()->findnodes( "//TEI.2" );

	## Loop through each of the texts loading them into our internal struct.
	for( my $i = 0; $i < scalar( @texts ); $i++ )
	{
		## Set the Composite document counter.
		$self->{ "Corpus" } = $i;

		## Set the base "text" element.
		$self->{ "document" }->{ $i } = 
			TEI::Lite::Document->new( String =>	$_->toString() );

		$root->appendChild( $self->{ "document" }->{ $i }->documentElement );
	}

	return( $self );
}

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

TEI::Lite::Document - TEI::Lite::Document Object

=head1 SYNOPSIS

 my $document = TEI::Lite::Document->new( 'Corpus'    => 0,
                                          'Composite' => 0 );

 my $header = $document->addHeader();

=head1 DESCRIPTION

TEI::Lite::Document is a object oriented interface to the 
'global' structure of a TEI document.

=head1 METHODS

=over 4

=item addBackMatter

Adds a back matter component to a <text> element that is currently
"active".

=item addCompositeBackMatter

Adds a back matter component to a composite document.

=item addCompositeFrontMatter

Adds a front matter component to a composite document.

=item addDocument

Adds another document to a corpus document.

=item addFrontMatter

Adds a front matter component to a <text> element that is currently
"active".

=item addHeader

Creates a default header in a TEI document.

=item addText

Adds another <text> to a composite document.

=item getActiveDocument

Returns the active document to the caller.

=item getActiveText

Returns the active text to the caller.

=item getBackMatter

Returns the back matter of the active document to the caller.

=item getBody

Returns the <body> element of the active document to the caller.

=item getCompositeBackMatter

Returns the back matter of the composite document to the caller.

=item getCompositeFrontMatter

Returns the front matter of the composite document to the caller.

=item getDocument

Returns the active document to the caller.

=item getDocuments

Returns an array of TEI Lite documents contained within a corpus document.

=item getFrontMatter

Returns the front matter of the active document to the caller.

=item getHeader

Returns the header node of a document.

=item getText

Returns the active <text> node of a document.

=item getTexts

Returns an array of <text> nodes of a document.

=item setActiveDocument

Gets/Sets the active document in a TEI corpus document.

=item setActiveText

Gets/Sets the text node that is considered active in a document.

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<TEI::Lite>, 
L<TEI::Lite::Element>, 
L<TEI::Lite::Header>, 
L<TEI::Lite::Utility>, 
L<XML::LibXML>, 
L<XML::LibXML::Node>,
L<XML::LibXML::Element>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2005 D. Hageman (Dracken Technologies).
All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut
