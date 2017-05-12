#!/usr/bin/perl
######################################################################
##                                                                  ##
##  Script: html2tei.pl                                             ##
##  Author: D. Hageman <dhageman@dracken.com>                       ##
##                                                                  ##
##  Description:                                                    ##
##                                                                  ##
##  Utility to convert reasonably compliant HTML files to TEILite.  ##
##                                                                  ##
######################################################################

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;

use strict;
use warnings;

use TEI::Lite;
use XML::LibXML;

our $VERSION = "0.50";

##==================================================================##
##  Main Execution                                                  ##
##==================================================================##

{
	## Check to see if we are given a file to convert.
	if( scalar( @ARGV ) < 1 )
	{
		print_usage();
	}
	
	## Create a parser to pull in the HTML file.
	my $parser = XML::LibXML->new();

	## Parse the HTML file given to utility - if it is reasonably
	## compliant - it should work.
	my $html_file = $parser->parse_html_file( $ARGV[0] );
	my $html_root = $html_file->documentElement;

	my $tei_file = TEI::Lite::Document->new( 'Corpus' 	=> 	0,
											 'Composite'	=>	0 );

	## We need to add a header to document.
	my $tei_header = $tei_file->addHeader();

	## Grab the body element of the TEI document.
	my $tei_body = $tei_file->getBody();
	
	## Time to set the title.
	my $title = $html_root->findvalue( '//head/title' );
	
	## Clean up the title a bit ...
	$title =~ s/^\s+//g;
	$title =~ s/\s+$//g;
	
	## Set the title correctly
	$tei_header->setTitle( $title );

	my( $body ) = $html_root->findnodes( '//body' );

	my $body_string = tei_convert_html_fragment( 0, $body->toString() );

	my $doc = $parser->parse_string( $body_string );
	
	$tei_body->appendChild( $doc->documentElement );
	
	## Print the docuument ...
	print $tei_file->toString( 2 ) . "\n";

	## We are done, exit nicely and go away!
	exit(0);
}

##==================================================================##
##  Function(s)                                                     ##
##==================================================================##

##----------------------------------------------##
##  print_usage                                 ##
##----------------------------------------------##
##  Subroutine to print usage information.      ##
##----------------------------------------------##
sub print_usage
{
	print "\nUsage: html2tei.pl <html file>\n\n";
	exit( 1 );
}

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documenation (POD)                                    ##
##==================================================================##

__END__

=head1 NAME

html2tei.pl

=head1 SYNOPSIS

html2tei.pl <htmlfile>

=head1 DESCRIPTION

Utility to convert a HTML file to a TEI Lite file.

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<TEI::Lite>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2005 D. Hageman (Dracken Technologies).
All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut
