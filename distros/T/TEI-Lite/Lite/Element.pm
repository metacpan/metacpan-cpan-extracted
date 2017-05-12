package TEI::Lite::Element;

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;
require Exporter;

use strict;
use warnings;

use XML::LibXML;
use I18N::LangTags qw( is_language_tag );

our $VERSION = "0.60";

our @EXPORT = qw( %TEI_ELEMENT );

our @ISA = qw( Exporter XML::LibXML::Element );

## Global array containing all of the global attributes of TEI Lite elements.
our @G_ATTR = qw( ana corresp id lang n next prev rend );

## Global hash that contains all of the TEI Lite elements and their
## associated attributes.
our %TEI_ELEMENT = (
	'abbr'				=>	[ 'type', 'expan' ],
	'add'				=>	[ 'place' ],
	'address'			=>	[],
	'addrLine'			=>	[],
	'anchor'			=>	[],
	'argument'			=>	[],
	'author'			=>	[],
	'authority'			=>	[],
	'availability'		=>	[ 'status' ],
	'back'				=>	[],
	'bibl'				=>	[],
	'biblFull'			=>	[],
	'biblScope'			=>	[],
	'body'				=>	[],
	'byline'			=>	[],
	'catDesc'			=>	[],
	'category'			=>	[],
	'catRef'			=>	[ 'target' ],
	'cell'				=>	[ 'role', 'cols', 'rows' ],
	'change'			=>	[],
	'cit'				=>	[],
	'classCode'			=>	[ 'scheme' ],
	'classDecl'			=>	[],
	'closer'			=>	[],
	'code'				=>	[],
	'corr'				=>	[ 'sic', 'resp', 'cert' ],
	'creation'			=>	[],
	'date'				=>	[ 'calendar', 'value' ],
	'dateline'			=>	[],
	'del'				=>	[ 'type', 'status', 'hand' ],
	'distributer'		=>	[],
	'div'				=>	[ 'type' ],
	'div0'				=>	[ 'type' ],
	'div1'				=>	[ 'type' ],
	'div2'				=>	[ 'type' ],
	'div3'				=>	[ 'type' ],
	'div4'				=>	[ 'type' ],
	'div5'				=>	[ 'type' ],
	'div6'				=>	[ 'type' ],
	'div7'				=>	[ 'type' ],
	'divGen'			=>	[ 'type' ],
	'docAuthor'			=>	[],
	'docDate'			=>	[],
	'docEdition'		=>	[],
	'docImprint'		=>	[],
	'docTitle'			=>	[],
	'edition'			=>	[],
	'editionStmt'		=>	[],
	'editor'			=>	[ 'role' ],
	'editorialDecl'		=>	[],
	'eg'				=>	[],
	'emph'				=>	[],
	'encodingDesc'		=>	[],
	'epigraph'			=>	[],
	'extent'			=>	[],
	'figDesc'			=>	[],
	'figure'			=>	[ 'entity', 'url' ],
	'fileDesc'			=>	[],
	'foreign'			=>	[],
	'formula'			=>	[ 'notation' ],
	'front'				=>	[],
	'funder'			=>	[],
	'gap'				=>	[ 'desc', 'resp' ],
	'gi'				=>	[],
	'gloss'				=>	[ 'target' ],
	'group'				=>	[],
	'head'				=>	[],
	'hi'				=>	[],
	'ident'				=>	[],
	'idno'				=>	[ 'type' ],
	'imprint'			=>	[],
	'index'				=>	[ 'level1', 'level2', 'level3', 
							  'level4', 'index' ],
	'interp'			=>	[ 'type', 'value', 'resp', 'inst' ],
	'interpGrp'			=>	[],
	'item'				=>	[],
	'keywords'			=>	[ 'scheme' ],
	'kw'				=>	[],
	'l'					=>	[ 'part' ],
	'label'				=>	[],
	'langUsage'			=>	[],
	'lb'				=>	[ 'ed' ],
	'lg'				=>	[],
	'list'				=>	[ 'type' ],
	'listBibl'			=>	[],
	'mentioned'			=>	[],
	'milestone'			=>	[ 'ed', 'unit' ],
	'name'				=>	[ 'type', 'key', 'reg' ],
	'note'				=>	[ 'type', 'resp', 'place', 
							  'target', 'targetEnd', 'anchored' ],
	'noteStmt'			=>	[],
	'num'				=>	[ 'type', 'value' ],
	'opener'			=>	[],
	'orig'				=>	[ 'reg', 'resp' ],
	'p'					=>	[ 'type' ],
	'pb'				=>	[],
	'principal'			=>	[],
	'profileDesc'		=>	[],
	'projectDesc'		=>	[],
	'ptr'				=>	[ 'type', 'target', 'targType', 
							  'crDate', 'resp' ],
	'publicationStmt'	=>	[],
	'publisher'			=>	[],
	'pubPlace'			=>	[],
	'q'					=>	[ 'type', 'who' ],
	'ref'				=>	[ 'type', 'target', 'targType', 
							  'crDate', 'resp' ],
	'refsDecl'			=>	[],
	'reg'				=>	[ 'orig', 'resp' ],
	'rendition'			=>	[],
	'resp'				=>	[],
	'respStmt'			=>	[],
	'revisionDesc'		=>	[],
	'row'				=>	[ 'role' ],
	'rs'				=>	[ 'type', 'key', 'reg' ],
	's'					=>	[ 'type' ],
	'salute'			=>	[],
	'samplingDecl'		=>	[],
	'seg'				=>	[ 'type' ],
	'series'			=>	[],
	'seriesStmt'		=>	[],
	'sic'				=>	[ 'corr', 'resp', 'cert' ],
	'signed'			=>	[],
	'soCalled'			=>	[],
	'sourceDesc'		=>	[],
	'sp'				=>	[ 'who' ],
	'speaker'			=>	[],
	'sponsor'			=>	[],
	'stage'				=>	[ 'type' ],
	'table'				=>	[ 'rows', 'cols' ],
	'tagsDecl'			=>	[],
	'tagUsage'			=>	[ 'gi', 'occurs' ],
	'taxonomy'			=>	[],
	'teiHeader'			=>	[],
	'term'				=>	[],
	'text'				=>	[],
	'textClass'			=>	[],
	'time'				=>	[ 'value' ],
	'title'				=>	[ 'type', 'level' ],
	'titlePage'			=>	[],
	'titlePart'			=>	[ 'title' ],
	'titleStmt'			=>	[],
	'trailer'			=>	[],
	'unclear'			=>	[ 'reason', 'resp' ],
	'xptr'				=>	[ 'target', 'type', 'targType', 'crDate',
							  'resp', 'doc', 'from', 'to', 'url' ],
	'xref'				=>	[ 'target', 'type', 'targType', 'crDate',
							  'resp', 'doc', 'from', 'to', 'url' ]
);

no strict "refs";

## Loop through each entry in our element hash and build a
## closure for that element.
foreach my $element ( keys( %TEI_ELEMENT ) )
{
	## Add each of these elements to the default export list.
	## I can't use the below function because of the warnings it
	## will generate.  What good is it?
	#Exporter::export_tags( "tei_$element" );
	push( @EXPORT, "tei_$element" );
	
	*{ "tei_$element" } = sub {
		my $attributes = shift;
		my @children = @_;

		## Need to set the type argument so the constructor knows
		## what to create.
		$$attributes{ '__type__' } = $element;
			
		## Call the default constructor
		my $node = TEI::Lite::Element->new( $attributes, @children );
		
		return( $node );
	}
}

use strict "refs";
	
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
	## Pull in the parameters, $attributes should be an array ref
	## and the rest of it should be children of the element.
	my $attributes = shift;
	my @children = @_;
	## We will use an XML::LibXML::Element object as the basis for our object.
	my $self = XML::LibXML::Element->new( $$attributes{__type__} );
	## Determine what exact class we will be blessing this instance into.
	my $class = ref( $type ) || $type;
	## Bless the class for it is good [tm].
	bless( $self, $class );
	## Set the attributes of the element.
	$self->setAttributes( $attributes );
	$self->appendChildren( @children );
	## Send it back to the caller all happy like.
	return( $self );
}

##----------------------------------------------##
##  TIEARRAY                                    ##
##----------------------------------------------##
sub TIEARRAY
{
	my( $class, $self ) = @_;

	bless( $self, $class );

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

##----------------------------------------------##
##  UNTIE                                       ##
##----------------------------------------------##
sub UNTIE
{
	## This is mainly a placeholder to keep things like mod_perl happy.
	return;
}

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

##----------------------------------------------##
##  appendChildren                              ##
##----------------------------------------------##
sub appendChildren
{
	my( $self, @children ) = @_;

	## Loop through each of the children and determine what type of
	## data element they are ...
	foreach( @children )
	{
		if( ( defined( $_ ) ) && ( $_ ne "" ) )
		{
			if(	( ref ) && ( $_->isa( "XML::LibXML::Node" ) ) )
			{
				## If it is one of the items above, we should be able to
				## safely append it to our DOM tree.
				$self->appendChild( $_ );
			}
			else
			{
				## If it isn't one of the items above, assume that it is
				## text data.
				$self->appendText( $_ );
			}
		}
	}

	return;
}

##----------------------------------------------##
##  CLEAR                                       ##
##----------------------------------------------##
sub CLEAR
{
	my $self = shift;

	## Grab all the nodes of our element ...
	my @childnodes = $self->childNodes;

	## Run through all of the nodes and remove each one.
	foreach( @childnodes )
	{
		$self->removeChild( $_ );
	}

	return( $self );
}

##----------------------------------------------##
##  DELETE                                      ##
##----------------------------------------------##
sub DELETE
{
	my( $self, $index ) = @_;

	## Grab all of the nodes of our element ...
	my @childnodes = $self->childNodes;

	## Remove the requested node at $index.
	$self->removeChild( $childnodes[ $index ] );

	return;
}

##----------------------------------------------##
##  EXISTS                                      ##
##----------------------------------------------##
sub EXISTS
{
	my( $self, $index ) = @_;

	## Grab all of the nodes of our element ...
	my @childnodes = $self->childNodes;

	## Check to see if we have a node at the $index.
	if( defined( $childnodes[ $index ] ) )
	{
		return( 1 );
	}
	else
	{
		return( 0 );
	}
}

##----------------------------------------------##
##  EXTEND                                      ##
##----------------------------------------------##
sub EXTEND
{
	## We don't do anything with this in our implementataion.
	return;
}

##----------------------------------------------##
##  FETCH                                       ##
##----------------------------------------------##
sub FETCH
{
	my( $self, $index ) = @_;

	## Grab all of the nodes of our element ...
	my @childnodes = $self->childNodes;

	return( $childnodes[ $index ] );
}

##----------------------------------------------##
##  FETCHSIZE                                   ##
##----------------------------------------------##
sub FETCHSIZE
{
	my $self = shift;

	## Grab the number of elements attached to our element.
	my @childnodes = $self->childNodes;
	my $size = scalar( @childnodes );

	return( $size );
}

##----------------------------------------------##
##  POP                                         ##
##----------------------------------------------##
sub POP
{
	my $self = shift;

	## Remove the last child and return it.
	return( $self->removeChild( $self->lastChild ) );
}

##----------------------------------------------##
##  PUSH                                        ##
##----------------------------------------------##
sub PUSH
{
	my( $self, @elements ) = @_;

	## We will just call our trusty function to do the 
	## pushing.
	$self->appendChildren( @elements );

	return( $self->FETCHSIZE() );
}

##----------------------------------------------##
##  setAttributes                               ##
##----------------------------------------------##
sub setAttributes
{
	my( $self, $attributes ) = @_;

	## Grab the type of element.
	my $element = $self->nodeName;

	## Loop through the global attributes and the element specific
	## attributes.
	foreach( @G_ATTR, @{ $TEI_ELEMENT{ $element } } )
	{
		## If it is defined in our attribute hash, then go ahead and 
		## set it.
		if( defined( $$attributes{ $_ } ) )
		{
			$self->setAttribute( $_, $$attributes{ $_ } );
		}
	}

	return;
}

##----------------------------------------------##
##  setLang                                     ##
##----------------------------------------------##
sub setLang
{
	my( $self, $lang ) = @_;

	if( is_language_tag( $lang ) )
	{
		$self->setAttribute( "lang", $lang );
		return( 1 );
	}

	return( 0 );
}

##----------------------------------------------##
##  SHIFT                                       ##
##----------------------------------------------##
sub SHIFT
{
	my $self = shift;

	## Grab the first element, remove it and then
	## send it back to the caller.
	return( $self->removeChild( $self->firstChild ) );
}

##----------------------------------------------##
##  STORE                                       ##
##----------------------------------------------##
sub STORE
{
	my( $self, $index, $value ) = @_;
	
	## Grab the number of elements attached to our element.
	my @childnodes = $self->childNodes;
	my $size = scalar( @childnodes );
	
	## Check to see if our $index is greater then our current size.
	if( $index >= ( $size - 1 ) )
	{
		## Determine if we need to add "buffer" space to make
		## the insertion at the correct index.
		my $blanknodes = $index - $size;

		for( my $i = 0; $i < $blanknodes; $i++ )
		{
			$self->appendTextNode( " " );
		}
	
		## We shall call our convience function to determine if
		## the data is text or another element.
		$self->appendChildren( $value );	
	}
	else
	{
		## Determine what type of node we have and take the 
		## appropriate function.
		if( ( defined( $value ) ) && ( $value ne "" ) )
		{
			if( ( ref( $value ) ) && ( $value->isa( "XML::LibXML::Node" ) ) )
			{
				$childnodes[$index]->replaceNode( $value );
			}
			else
			{
				my $node = XML::LibXML::Text->new( $value );
				$childnodes[$index]->replaceNode( $node );
			}
		}
	}

	return;
}

##----------------------------------------------##
##  UNSHIFT                                     ##
##----------------------------------------------##
sub UNSHIFT
{
	my( $self, @list ) = @_;

	foreach( @list )
	{
		my $first = $self->firstChild;
		
		if( $_->isa( "XML::LibXML::Node" ) )
		{
			$self->insertBefore( $_, $first );
		}
		else
		{
			my $node = XML::LibXML::Text->new( $_ );
			$self->insertBefore( $node, $first );
		}
	}

	return;
}

##==================================================================##
##  Internal Functions                                              ##
##==================================================================##

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

TEI::Lite::Element

=head1 SYNOPSIS

 my $tei_p = tei_p();

 tie( my @p, 'TEI::Lite::Element', $tei_p );

 push( @p, tei_head( "Example Head Element" ),
           "Regular body of the paragraph ..." );

 untie( @p );

 print $tei_p->toString( 2 ) . "\n";

=head1 DESCRIPTION

TEI::Lite::Element is wrapper for the document object model implemented
using a subroutine named after the TEI element it creates with a prefix
of tei_ attached.  Each subroutine returns a DOM element that can be
included in a DOM tree.

=head1 METHODS

Each function returns an object based on an instance of a 
XML::LibXML::Element.  All methods associated with XML::LibXML::Element
objects will work with the objects returned by the functions listed below.

=head1 FUNCTIONS

Until I have time to document each individual element, please see
the TEILite specification and the example programs included in 
the distribution.

=over 4

=item tei_abbr

=item tei_addrLine

=item tei_dateline

=item tei_principal

=item tei_revisionDesc

=item tei_pubPlace

=item tei_num

=item tei_del

=item tei_biblScope

=item tei_interpGrp

=item tei_availability

=item tei_stage

=item tei_editor

=item tei_mentioned

=item tei_catDesc

=item tei_titlePage

=item tei_classDecl

=item tei_name

=item tei_salute

=item tei_respStmt

=item tei_cell

=item tei_biblFull

=item tei_keywords

=item tei_cit

=item tei_rs

=item tei_publicationStmt

=item tei_series

=item tei_unclear

=item tei_body

=item tei_projectDesc

=item tei_distributer

=item tei_encodingDesc

=item tei_l

=item tei_creation

=item tei_p

=item tei_editionStmt

=item tei_emph

=item tei_q

=item tei_kw

=item tei_xref

=item tei_s

=item tei_closer

=item tei_sic

=item tei_classCode

=item tei_sp

=item tei_docDate

=item tei_docImprint

=item tei_lb

=item tei_authority

=item tei_catRef

=item tei_lg

=item tei_foreign

=item tei_interp

=item tei_argument

=item tei_date

=item tei_docEdition

=item tei_ref

=item tei_reg

=item tei_teiHeader

=item tei_eg

=item tei_front

=item tei_address

=item tei_noteStmt

=item tei_note

=item tei_head

=item tei_sourceDesc

=item tei_figure

=item tei_milestone

=item tei_div0

=item tei_list

=item tei_div1

=item tei_category

=item tei_div2

=item tei_div3

=item tei_fileDesc

=item tei_div4

=item tei_div5

=item tei_xptr

=item tei_div6

=item tei_div7

=item tei_div8

=item tei_opener

=item tei_resp

=item tei_taxonomy

=item tei_trailer

=item tei_div

=item tei_bibl

=item tei_titleStmt

=item tei_group

=item tei_item

=item tei_refsDecl

=item tei_titlePart

=item tei_back

=item tei_idno

=item tei_rendition

=item tei_langUsage

=item tei_ident

=item tei_gap

=item tei_ptr

=item tei_add

=item tei_editorialDecl

=item tei_textClass

=item tei_speaker

=item tei_docAuthor

=item tei_gi

=item tei_divGen

=item tei_epigraph

=item tei_formula

=item tei_index

=item tei_signed

=item tei_gloss

=item tei_sponsor

=item tei_label

=item tei_profileDesc

=item tei_text

=item tei_seg

=item tei_row

=item tei_seriesStmt

=item tei_samplingDecl

=item tei_time

=item tei_tagUsage

=item tei_corr

=item tei_table

=item tei_author

=item tei_hi

=item tei_funder

=item tei_listBibl

=item tei_pb

=item tei_byline

=item tei_imprint

=item tei_code

=item tei_title

=item tei_anchor

=item tei_soCalled

=item tei_orig

=item tei_edition

=item tei_docTitle

=item tei_extent

=item tei_term

=item tei_publisher

=item tei_tagsDecl

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<TEI::Lite>, 
L<TEI::Lite::Document>, 
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
