package TEI::Lite::Utility;
######################################################################
##                                                                  ##
##  Package:  Utility.pm                                            ##
##  Author:   D. Hageman <dhageman@dracken.com>                     ##
##                                                                  ##
##  Description:                                                    ##
##                                                                  ##
##  Perl object designed to assist the user in the creation and     ##
##  manipulation of TEILite documents.                              ##
##                                                                  ##
######################################################################

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;
require Exporter;

use strict;
use warnings;

use XML::LibXML;
use TEI::Lite::Element;

our @ISA = qw( Exporter );

our @EXPORT = qw( tei_convert_html_fragment );

our $VERSION = "0.60";

our %HTML2TEI = (
	'a'				=>	[ 'link' ],
	'abbr'			=>	[ 'tei_abbr', {} ],
	'acronym'		=>	[ 'tei_abbr', {} ],
	'address'		=>	[ 'tei_address', {} ],
	'applet'		=>	[ undef ],
	'area'			=>	[ undef ],
	'b'				=>	[ 'tei_hi', { rend => 'bold' } ],
	'base'			=>	[ undef ],
	'basefont'		=>	[ undef ],
	'bdo'			=>	[ undef ],
	'big'			=>	[ 'tei_hi', { rend => 'bold' } ],
	'blockquote'	=>	[ 'tei_div', {} ],
	'br'			=>	[ 'tei_lb', {} ],
	'center'		=>	[ 'tei_hi', { rend => 'center' } ],
	'cite'			=>	[ 'tei_cit', {} ],
	'code'			=>	[ 'tei_code', {} ],
	'col'			=>	[ undef ],
	'colgroup'		=>	[ undef ],
	'comment'		=>	[ 'comment' ],
	'dd'			=>	[ undef ],
	'del'			=>	[ undef ],
	'dfn'			=>	[ undef ],
	'div'			=>	[ undef ],
	'dl'			=>	[ undef ],
	'dt'			=>	[ undef ],
	'em'			=>	[ 'tei_emph', {} ],
	'fieldset'		=>	[ undef ],
	'font'			=>	[ undef ],
	'h1'			=>	[ 'tei_head', {} ],
	'h2'			=>	[ 'tei_head', {} ],
	'h3'			=>	[ 'tei_head', {} ],
	'h4'			=>	[ 'tei_head', {} ],
	'h5'			=>	[ 'tei_head', {} ],
	'h6'			=>	[ 'tei_head', {} ],
	'hr'			=>	[ 'tei_pb', { rend => 'hr' } ],
	'i'				=>	[ 'tei_hi', { rend => 'italic' } ],
	'img'			=>	[ 'figure' ],
	'ins'			=>	[ undef ],
	'isindex'		=>	[ undef ],
	'kbd'			=>	[ undef ],
	'legend'		=>	[ undef ],
	'li'			=>	[ 'tei_item', {} ],
	'link'			=>	[ undef ],
	'ol'			=>	[ 'tei_list', { type => 'ordered' } ],
	'p'				=>	[ 'tei_p', {} ],
	'pre'			=>	[ undef ],
	'q'				=>	[ 'tei_hi', { rend => 'quoted' } ],
	's'				=>	[ undef ],
	'samp'			=>	[ 'tei_hi', { rend => 'italic' } ],
	'small'			=>	[ 'tei_hi', { rend => 'normal' } ],
	'span'			=>	[ undef ],
	'strike'		=>	[ 'tei_hi', { rend => 'strike-through' } ],
	'strong'		=>	[ 'tei_hi', { rend => 'bold' } ],
	'style'			=>	[ undef ],
	'sub'			=>	[ undef ],
	'table'			=>	[ 'tei_table', {} ],
	'tbody'			=>	[ undef ],
	'td'			=>	[ 'tei_cell', {} ],
	'tfoot'			=>	[ undef ],
	'th'			=>	[ undef ],
	'thead'			=>	[ undef ],
	'tr'			=>	[ 'tei_row', {} ],
	'tt'			=>	[ 'tei_h', { rend => 'monotype' } ],
	'u'				=>	[ 'tei_hi', { rend => 'underline' } ],
	'ul'			=>	[ 'tei_list', { type => 'bulleted' } ],
	'var'			=>	[ 'tei_hi', { rend => 'italic' } ]
);

##==================================================================##
##  Function(s)                                                     ##
##==================================================================##

##----------------------------------------------##
##  tei_convert_html_fragment                   ##
##----------------------------------------------##
sub tei_convert_html_fragment ($$@)
{
	my( $user_conversions, $format, @html ) = @_;
	
	## Define a variable to hold our HTML DOM tree.
	my $html = join( '', @html );
	
	## Create a new document to hold our data.
	my $dom = XML::LibXML::Document->new( '1.0' );
	
	## Default the format to be '0' if it isn't defined.
	$format = 0 if !defined( $format );
	
	## Create a new XML::LibXML parser to play with.
	my $parser = XML::LibXML->new();

	eval
	{
		## Attempt to parse the html data into a workable DOM tree.
		$html = $parser->parse_html_string( $html );
	};

	if( $@ )
	{
		return( undef );
	}
	else
	{
		## Create a document fragment to insert our nodes into.
		my $dom_fragment = $dom->createDocumentFragment;
	
		foreach( $html->documentElement->findnodes( "//body/*" ) )
		{
			my( @elements ) = 
				_convert_html_element_to_tei_element( $user_conversions, $_ );

			foreach my $element ( @elements )
			{
				$dom_fragment->appendChild( $element );
			}
		}

		return( $dom_fragment->toString( $format ) );
	}
}

##==================================================================##
##  Private Function(s)                                             ##
##==================================================================##

##----------------------------------------------##
##  _convert_html_element_to_tei_element        ##
##----------------------------------------------##
##  Private helper function for the TEI to      ##
##  HTML conversion function.                   ##
##----------------------------------------------##
sub _convert_html_element_to_tei_element 
{
	my( $user_conversions, $node ) = @_;

	## Define an element to hold our scratch data and other elements.
	my @result;
	my $function,
	my %attributes;
	
	## Simplest case is if the data is text - we can just return that to
	## be appended.
	if( ref( $node ) eq ( "XML::LibXML::Text" ) )
	{
		return( $node );
	}

	## Determine which html node we are really dealing with ...
	my $name = lc( $node->nodeName );

	## Grab the conversion routine for this element from the converstion
	## hash we have already defined.
	if( ( defined( $user_conversions ) ) && 
		( ref( $user_conversions ) eq "HASH" ) )
	{
		$function = @{ $user_conversions->{ $name } }[0];

		if( !defined( $function ) )
		{
			$function = @{ $HTML2TEI{ $name } }[0];
		}
	}
	else
	{
		$function = @{ $HTML2TEI{ $name } }[0];
	}

	## Check to see if the conversion function is defined our not.
	if( ( !defined( $function ) ) && ( $node->hasChildNodes() ) )
	{
		if( $node->hasChildNodes() )
		{
			my( @children ) = $node->childNodes();
	
			foreach( @children )
			{
				push( @result, 
					  _convert_html_element_to_tei_element( 
							$user_conversions, $_ ) );
			}
		}
		else
		{
			return( XML::LibXML::Text->new( " " ) );
		}
	}

	## This is our true main case ... almost all the converstion elements
	## get done on this code branch.
	if( ( defined( $function ) ) && ( $function =~ /tei/ ) )
	{
		if( defined( @{ $user_conversions->{ $name } }[1] ) )
		{
			%attributes = %{ @{ $user_conversions->{ $name } }[1] };
		}
		elsif( defined( @{ $HTML2TEI{ $name } }[1] ) )
		{
			## Grab the attributes out of our converstion hash.
			%attributes = %{ @{ $HTML2TEI{ $name } }[1] };
		}

		no strict 'refs';
		$result[0] = &$function( \%attributes);
		use strict 'refs';

		## Loop through each of the child nodes ...
		foreach( $node->childNodes() )
		{
			my( @children ) = 
				_convert_html_element_to_tei_element( $user_conversions, $_ );
			
			## Loop through each of those child nodes ...
			foreach my $child ( @children )
			{
				$result[0]->appendChild( $child );
			}
		}
	}

	## We have a special case for comment nodes.
	if( ( defined( $function ) ) && ( $function eq "comment" ) )
	{
		$result[0] = XML::LibXML::Comment->new();

		foreach( $node->childNodes() )
		{
			$result[0]->appendChild( $_ );
		}
	}

	## We have a special case for linking nodes.
	if( ( defined( $function ) ) && ( $function eq "link" ) )
	{
		my $href = $node->getAttribute( "href" );

		$result[0] = tei_xref( { url => $href } );

		foreach( $node->childNodes() )
		{
			my( @children ) = 
				_convert_html_element_to_tei_element( $user_conversions, $_ );
			
			## Loop through each of those child nodes ...
			foreach my $child ( @children )
			{
				$result[0]->appendChild( $child );
			}
		}
	}

	## We have a special case for images as well ...
	if( ( defined( $function ) ) && ( $function eq "figure" ) )
	{
		my $src = $node->getAttribute( "src" ) || "";
		my $alt = $node->getAttribute( "alt" ) || "";

		$result[0] = tei_figure( { url => $src } );

		if( $alt ne "" )
		{
			$result[0]->appendChild( tei_figDesc( {}, $alt ) );
		}
	}
	
	return( @result );
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

TEI::Lite::Utility

=head1 DESCRIPTION

TEI::Lite is a DOM wrapper designed to ease the creation and modification
of XML documents based on the Text Encoding Initiative markup variant
called TEILite.  TEILite is generally considered to contain enough tags 
and markup flexibility to be able to handle most document types.

=head1 FUNCTIONS

=over 4

=item tei_convert_html_fragment ( $FORMAT, @HTML )

This function will take a chunk of HTML formated data and convert it
to a reasonable representation of TEILite.  The $FORMAT paramater is
the indenting level of you want in the output.  The @HTML is an 
array of HTML data.

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<TEI::Lite>,
L<TEI::Lite::Document>, 
L<TEI::Lite::Element>
L<TEI::Lite::Header>, 
L<XML::LibXML>, 
L<XML::LibXML::Node>,
L<XML::LibXML::Element>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2005 D. Hageman (Dracken Technologies).
All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut
