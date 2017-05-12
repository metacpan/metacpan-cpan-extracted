package TEI::Lite;

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;
require Exporter::Cluster;

use strict;
use warnings;

our @ISA = qw( Exporter::Cluster );

our %EXPORT_CLUSTER = ( 'TEI::Lite::Document'	=>	[],
						'TEI::Lite::Element'	=>	[],
						'TEI::Lite::Header'		=>	[],
						'TEI::Lite::Utility'	=>	[], );

our $VERSION = "0.60";

##==================================================================##
##  Constructor(s)/Deconstructor(s)                                 ##
##==================================================================##

##
##  None.
##

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

##
##  None.
##

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

TEI::Lite

=head1 DESCRIPTION

TEI::Lite is a DOM wrapper designed to ease the creation and modification
of XML documents based on the Text Encoding Initiative markup variant
called TEI Lite.  TEI Lite is generally considered to contain enough tags 
and markup flexibility to be able to handle most document types.

The Text Encoding Initiative website can be found at http://www.tei-c.org/.

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

L<TEI::Lite::Document>, 
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
