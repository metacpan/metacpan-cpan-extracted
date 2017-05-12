package TEI::Lite::Header;

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;

use strict;
use warnings;

use Date::Calc;
use XML::LibXML;
use TEI::Lite::Element;

our @ISA = qw( XML::LibXML::Element );

our $VERSION = "0.60";

our %METHOD = (
	'setAuthor'					=>	'//teiHeader/fileDesc/titleStmt/author',
	'setAuthority'				=>	'//teiHeader/fileDesc/publicationStmt' .
									'/authority',
	'setBibliographicCitation'	=>	'//teiHeader/fileDesc/sourceDesc/bibl',
	'setDistributor'			=>	'//teiHeader/fileDesc/publicationStmt' .
									'/distributor',
	'setFunder'					=>	'//teiHeader/fileDesc/titleStmt/funder',
	'setPrincipalResearcher'	=>	'//teiHeader/fileDesc/titleStmt/principal',
	'setPublisher'				=>	'//teiHeader/fileDesc/publicationStmt' .
									'/publisher',
	'setSponsor'				=>	'//teiHeader/fileDesc/titleStmt/sponsor',
	'setTitle'					=>	'//teiHeader/fileDesc/titleStmt/title'
);

no strict "refs";

## Loop through each element in the common method hash and build the
## associated methods.  Not all methods are of the cookie cutter variety,
## so we define those methods down below.
foreach my $method ( keys( %METHOD ) )
{
	*{ $method } = sub {
			my( $self, @data ) = @_;

			## Use XPath to search for the node that we need.
			my( $node ) = $self->_ensure_xpath( $METHOD{ $method } );

			## Grab the last part of the XPath expression.
			$METHOD{ $method } =~ /\/(\w+)$/;

			## Generate the correct function name ....
			my $tei_function = "tei_$1";
			
			## Generate the element.
			my $element = &$tei_function( {}, @data );

			## Replace the node.
			$node->replaceNode( $element );
			
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
	## We will use an anonymous hash as the base of the object.
	my $self = _generate_header_template( @_ );
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
##  appendRevisionEntry                         ##
##----------------------------------------------##
sub appendRevisionEntry
{
	my( $self, $date, $name, $title, @data ) = @_;
	
	## Attempt to decode the date ...
	my( $year, $month, $day ) = Decode_Date_US( $date );
	
	## Use XPath to search for the node that we need.
	my( $node ) = $self->_ensure_xpath( '//teiHeader/revisionDesc/' );

	my $element = tei_change( tei_date( { value => "$year-$month-$day" },
										Date_to_Text( $year, $month, $day ) ),
							  tei_respStmt( {}, tei_name( {}, $name ),
									  			tei_resp( {}, $title ) ),
							  map( tei_item( {}, $_ ), @data ) );

	if( $node->hasChildNodes() )
	{
		## We want our latest changes to be at the top.
		$node->insertBefore( $element, $node->firstChild );
	}
	else
	{
		## No children exist, so just append it.
		$node->appendChild( $element );
	}
					  
	return( $node );
}

##----------------------------------------------##
##  setDatePublished                            ##
##----------------------------------------------##
sub setDatePublished
{
	my( $self, $date ) = @_;

	## Attempt to decode the data ...
	my( $year, $month, $day ) = Decode_Date_US( $date );
	
	## Use XPath to search for the node that we need.
	my( $node ) = 
		$self->_ensure_xpath( '//teiHeader/fileDesc/publicationStmt/date' );

	my $element = tei_date( { value => "$year-$month-$day" },
							Date_to_Text( $year, $month, $day ) );
		
	$node->replaceNode( $element );
					
	return( $node );
}

##----------------------------------------------##
##  setDocumentAvailability                     ##
##----------------------------------------------##
sub setDocumentAvailability
{
	my( $self, $status, $copyright ) = @_;
	
	## If we don't have a status provided, set it to unknown.
	$status = "unknown" if !defined( $status );
	
	## Use XPath to search for the node that we need.
	my( $node ) = 
		$self->_ensure_xpath( '//teiHeader/fileDesc/publicationStmt/idno' );
		
	my $element = tei_availability( { status => $status }, $copyright );

	$node->replaceNode( $element );
	
	return( $node );
}

##----------------------------------------------##
##  setIdentificationNumber                     ##
##----------------------------------------------##
sub setIdentificationNumber
{
	my( $self, $type, $number ) = @_;
	
	## If we don't provide a specific type, then set it to unknown.
	$type = "unknown" if !defined( $type );
	
	## Use XPath to search for the node that we need.
	my( $node ) = 
		$self->_ensure_xpath( '//teiHeader/fileDesc/publicationStmt/idno' );
		
	my $element = tei_idno( { type => $type }, $number );

	$node->replaceNode( $element );
	
	return( $node );
}

##----------------------------------------------##
##  setKeywords                                 ##
##----------------------------------------------##
sub setKeywords
{
	my( $self, @data ) = @_;
	
	## Create a variable to temporarily hold our keywords.
	my @keywords;	
	
	## Use XPath to search for the node that we need.
	my( $node ) = 
		$self->_ensure_xpath( '//teiHeader/profileDesc/textClass/keywords' );

	## We need to generate <keywords><list><item>*</item></list></keywords>.
	my $element = tei_keywords( {},
								tei_list( {}, 
										  map( tei_item( {}, $_ ), @data ) ) );	

	$node->replaceNode( $element );
	
	return( $node );
}

##==================================================================##
##  Internal Function(s)                                            ##
##==================================================================##

##----------------------------------------------##
##  _ensure_xpath                               ##
##----------------------------------------------##
##  Recursive function that will build up the   ##
##  path that is required by an element.        ##
##----------------------------------------------##
sub _ensure_xpath
{
	my( $self, $xpath ) = @_;

	## Variable that will hold our search patch after we build it and
	## also a temp variable for a loop down below.
	my( @search, $last );
	
	$xpath =~ s/^\/\///g;
	
	## Break up the XPath statement.
	my @path = split( /\//, $xpath );

	for( my $loop = 0; $loop < scalar( @path ); $loop++ )
	{
		$search[ $loop ] = "/";

		foreach( my $loop2 = 0; $loop2 <= $loop; $loop2++ )
		{
			$search[ $loop ] .= "/" . $path[ $loop2 ];
		}
	}

	foreach( @search )
	{
		my( $node ) = $self->findnodes( $_ );

		## If it is defined then that is a good thing, but if it isn't
		## we need to create it.
		if( defined( $node ) )
		{
			$last = $node;
		}
		else
		{
			## Grab the last part of the XPath expression.
			$_ =~ /\/(\w+)$/;
			
			## Create an element ... add it to the node tree.
			$last = $last->appendChild( XML::LibXML::Element->new( $1 ) );
		}
	}

	return( $last );
}

##----------------------------------------------##
##  _generate_header_template                   ##
##----------------------------------------------##
##  Function to generate the most basic header  ##
##  that doesn't contain any "preset" data, yet ##
##  still be valid when validated.              ##
##----------------------------------------------##
sub _generate_header_template
{
	my( $self, %params ) = @_;

	##<teiHeader>
	##<fileDesc>
	##<titleStmt><title/></titleStmt>
	##<publicationStmt><publisher/><date/></publicationStmt>
	##<sourceDesc><p/></sourceDesc>
	##</fileDesc>
	##</teiHeader>
	my $header = tei_teiHeader( {}, tei_fileDesc( {}, 
												  tei_titleStmt( {}, 
														  		 tei_title() ),
								 	tei_publicationStmt( {}, 
														 tei_publisher(),
										 				 tei_date() ),
								 	tei_sourceDesc( {}, tei_bibl() ) ) );
	
	return( $header );
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

TEI::Lite::Header

=head1 SYNOPSIS

 ## $document is a TEI::Lite::Document.
 my $header = $document->addHeader();

 $header->setTitle( "Title of Document" );

=head1 DESCRIPTION

TEI::Lite::Header is part of the TEILite library designed specifically to
handle the headers of TEILite files.  It provides a set of convience
methods to access the most common header elements.

=head1 METHODS

=over 4

=item appendRevisionEntry

=item setAuthor

=item setAuthority

=item setBibliographicCitation

=item setDatePublished

=item setDistributor

=item setDocumentAvailability

=item setFunder

=item setIdentificationNumber

=item setKeywords

=item setPrincipalResearcher

=item setPublisher

=item setSponsor

=item setTitle

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<XML::Lite>, 
L<XML::Lite::Document>, 
L<XML::Lite::Element>, 
L<XML::Lite::Utility>, 
L<XML::LibXML>, 
L<XML::LibXML::Node>,
L<XML::LibXML::Element>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2005 D. Hageman (Dracken Technologies).
All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut

