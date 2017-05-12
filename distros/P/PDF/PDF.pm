#
# PDF.pm, version 1.11 February 2000 antro
#
# Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 
#
# Free usage under the same Perl Licence condition.
#

package PDF;

$PDF::VERSION = "1.11";

require 5.005;

require PDF::Core;  
require PDF::Parse;  

use strict;
use Carp;
use Exporter ();

use vars qw(@ISA $Verbose);

#
# Verbose off by default
#
$Verbose = 0;

@ISA = qw(Exporter PDF::Core PDF::Parse);

1;

__END__

=head1 NAME

PDF - Library for PDF access and manipulation in Perl

=head1 SYNOPSIS

  use PDF;

  $pdf=PDF->new ;
  $pdf=PDF->new(filename);

  $result=$pdf->TargetFile( filename );

  print "is a pdf file\n" if ( $pdf->IsaPDF ) ;
  print "Has ",$pdf->Pages," Pages \n";
  print "Use a PDF Version  ",$pdf->Version ," \n";
  print "and it is crypted  " if ( $pdf->IscryptedPDF) ;

  print "filename with title",$pdf->GetInfo("Title"),"\n";
  print "and with subject ",$pdf->GetInfo("Subject"),"\n";
  print "was written by ",$pdf->GetInfo("Author"),"\n";
  print "in date ",$pdf->GetInfo("CreationDate"),"\n";
  print "using ",$pdf->GetInfo("Creator"),"\n";
  print "and converted with ",$pdf->GetInfo("Producer"),"\n";
  print "The last modification occurred ",$pdf->GetInfo("ModDate"),"\n";
  print "The associated keywords are ",$pdf->GetInfo("Keywords"),"\n";

  my (startx,starty, endx,endy) = $pdf->PageSize ($page) ;

=head1 DESCRIPTION

The main purpose of the PDF library is to provide classes and
functions that allow to read and manipulate PDF files with perl. PDF
stands for Portable Document Format and is a format proposed by Adobe.
A full description of this format can be found in the B<Portable
Document Reference Manual> by B<Adobe Systems Inc.>. For more details
about PDF, refer to:

B<http://www.adobe.com/>

The main idea is to provide some "basic" modules for access 
the information contained in a PDF file. Even if at this
moment is in an early development stage, the scripts in the 
example directory show that it is usable. 

B<is_pdf> script test a list of files in order divide the PDF file
from the non PDF using the info provided by the files 
themselves. It doesn't use the I<.pdf> extension, it uses the information
contained in the file.

B<pdf_version> returns the PDF level used for writing a file.

B<pdf_pages> gives the number of pages of a PDF file. 

B<pagedump.pl> prints some information about individual pages in a
PDF-file. Although the information as such are not very useful, it
demontrates well some more complex aspects of the library. Check the
function B<doprint> in this program on how to handle all possible data
occuring in a PDF.

The library is now splitted in 2 section :

B<PDF::Core> that contains the data structure, the constructor and low
level access fuctions;

B<PDF::Parse> all kind of functions to parse the PDF-files and
provide information about the content.

Check the help-files of these modules for more details.

=head1 Variables

There are 2 variables that can be accessed:

=over 4

=item B<$PDF::VERSION>

Contain the version of the library installed.

=item B<$PDF::Verbose>

This variable is false by default. Change the value if you want 
more verbose output messages from library.

=back 4

=head1 Copyright

  Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 Availability

The latest version of this library is likely to be available from:

http://www.geocities.com/CapeCanaveral/Hangar/4794/

and at any CPAN mirror

=head1 Greetings

Fabrizio Pivari ( pivari@geocities.com ) for all the suggestions about life, the universe and everything.
Brad Appleton ( bradapp@enteract.com ) for his suggestions about the module organization.
Thomas Drillich for the iso latin1 support 
Ross Moore ( ross@ics.mq.edu.au ) for ReadInfo fix

=cut


