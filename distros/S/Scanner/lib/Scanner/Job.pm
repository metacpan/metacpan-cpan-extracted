#================================= Job.pm ====================================
# Filename:  	       Job.pm
# Description:         Handle a scanning job, where job is usually a document.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:31:44 $ 
# Version:             $Revision: 1.3 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use File::Spec;
use Fault::DebugPrinter;
use Fault::ErrorHandler;
use Fault::Logger;

use Document::Directory;
use Document::PageIterator;
use Document::PageId;

use Scanner::Device;
use Scanner::Format;
use Scanner::Page;

package Scanner::Job;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub new {
  my ($class,$scanner,$firstpage,$format,$Spine_Width_Inches,$Total_Sheets,
      $path,$date,$publication) = @_;
  my $self                      = bless {}, $class;

  my $pgformat = Scanner::Format->new ('format' => $format);
  if (!defined $pgformat) {
    Fault::ErrorHandler->warn ("Invalid page format");
    return undef;
  }

  if ($Total_Sheets <= 0) {
    Fault::ErrorHandler->warn ("Total Sheets cannot be zero!");
    return undef;
  }

  if ($Spine_Width_Inches <= 0.0) {
    Fault::ErrorHandler->warn ("Spine Width cannot be 0.0 inches!");
    return undef;
  }

  my ($w,$h) = $pgformat->UserDimensions;
  my $so     = $pgformat->orientation;
  my $sw     = ($pgformat->portrait)  ? $Spine_Width_Inches : $w;
  my $sh     = ($pgformat->landscape) ? $Spine_Width_Inches : $h;
  my $spine  = Scanner::Format->new ('format' => "${so}:${sw}x${sh}");

  my @parse  = Document::PageId->parse ($firstpage);

  if ( !($parse[0] and !$parse[1])) {
    Fault::ErrorHandler->warn 
	("First page is not in a recognizable format: \"$firstpage\"");
    return undef;
  }

  $self->{'scanner'}      = $scanner;
  $self->{'FirstPage'}    = $firstpage;
  $self->{'PageFormat'}   = $pgformat;
  $self->{'SpineFormat'}  = $spine;
  $self->{'Total_Sheets'} = $Total_Sheets;

  $self->{'pgspersheet'} = 1;
  $self->{'batchlen'}	 = 1;
  $self->{'batchcnt'}	 = 0;
  $self->{'PageTitle'}   = "cover";
  $self->{'FirstPageId'} = ($firstpage == 0) ? 
                               "000a" : sprintf "%03d",$firstpage;

  $self->{'curpgobj1'} = Document::PageIterator->new ($self->{'FirstPageId'});
  $self->{'curpgobj2'} = Document::PageIterator->new ($self->{'FirstPageId'});
  $self->{'document'}  = Document::Directory->open ($path,$date,$publication);

  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub scan ($) {
  my $self = shift;
  my $fs   = $self->{'document'}->filespec;
  my ($pageid, $format, $title);

  if ($self->isSpine) {
    $pageid = "000.spine";
    $format = $self->{'SpineFormat'};
    $title  = "spine";
  }
  else {
    $pageid = $self->pageid;
    $format = $self->{'PageFormat'};
    $title  = $self->{'PageTitle'};
  }
  
  my $curpage = Scanner::Page->new
    ( 'date'   => $fs->dates,
      'title'  => $fs->undated_filename,
      'pageid' => $pageid,
      'format' => $format
      );
  $self->{'scanner'}->scan ($curpage, $fs->pathname);
  
  Fault::DebugPrinter->dbg (2, "Scan page " . $pageid);

  $self->{'document'}->add ($pageid,($title) );
  return $self;
}

#-----------------------------------------------------------------------------

sub nextPageNumbers {
  my $self                   = shift;
  my ($curpgobj1,$curpgobj2) = @$self{'curpgobj1','curpgobj2'};

  if ($self->{'pgspersheet'} == 1) {
    $curpgobj1->nextid(1);
  }
  else {
    $curpgobj1->setpageid ($curpgobj2->get);
    $curpgobj1->nextid    (1);
    $curpgobj2->setpageid ($curpgobj1->get);
    $curpgobj2->nextid    (1);
  }
  return $self;
}

#-----------------------------------------------------------------------------

sub pageid {
  my ($self)           = shift;
  my ($pgobj1,$pgobj2) = @$self{'curpgobj1','curpgobj2'};

  my $pg1 = (defined $pgobj1) ? $pgobj1->get : "UNDEF";
  my $pg2 = (defined $pgobj2) ? $pgobj2->get : "UNDEF";
  return ($self->{'pgspersheet'} == 1) ? $pg1 : "$pg1-$pg2";
}

#-----------------------------------------------------------------------------

sub guessPageTitle {
  my ($self)           = shift;
  my ($pgobj1,$pgobj2) = @$self{'curpgobj1','curpgobj2'};
  my $str;

  if ( $pgobj1->get eq "000.spine") {$str = "spine";}
  else {$str = ($pgobj1->get eq $self->{'FirstPageId'}) ? "cover" : "";}

  $self->{'PageTitle'} = $str;
  return $str;
}

#-----------------------------------------------------------------------------

sub setPagesPerSheet {
  my ($self,$pgs) = (shift,shift); 
  if ($pgs < 0 or $pgs > 2) {return undef;}
  $self->{'pgspersheet'} = $pgs;
  if ($pgs == 2) {
    $self->{'curpgobj2'}->setpageid ($self->{'curpgobj1'}->get);
    $self->{'curpgobj2'}->nextid    (1);
  }
  return $self->{'pgspersheet'};
}

#-----------------------------------------------------------------------------

sub setPagesPerSheetAsIn {
  my ($self,$line) = (shift,shift); 
  my ($pgobj1,$pgobj2) = @$self{'curpgobj1','curpgobj2'};

  my ($one,$two) = split (/-/, $line, 2);
  if (defined $one) {
    $pgobj1->setpageid ($one);
    $self->setPagesPerSheet (1);
    if (defined $two) {$pgobj2->setpageid ($two);}
    else              {$pgobj2->setpageid ($one);}
    
    $self->{'pgspersheet'} = ($pgobj1->get eq $pgobj2->get) ? 1 : 2;
  }
  return $self->{'pgspersheet'};
}

#-----------------------------------------------------------------------------

sub setBatchLength {
  my ($self,$n) = (shift,shift);
  $n=1 if ($n == 0);

  $self->{'batchlen'}=$n;
  return $n;
}

#-----------------------------------------------------------------------------

sub info ($) {
  my $self = shift;

  printf "[Job]\n" . 
         "First page:                %s\n" .
         "Pages Per Sheet:           %d\n" .
         "Total Sheets:              %d\n" .
         "Batch Length:              %d\n" .
         "Batch Down Counter:        %d\n",
	   @$self{'FirstPage', 'pgspersheet', 
		  'Total_Sheets', 'batchlen', 'batchcnt'};

  printf ("\n"); $self->{'scanner'}->info;
  printf ("\n"); $self->{'document'}->info;
  printf ("\n"); $self->{'PageFormat'}->info  ("Page");
  printf ("\n"); $self->{'SpineFormat'}->info ("Spine");
  printf ("\n");

  return $self;
}

#-----------------------------------------------------------------------------

sub isSpine         {my $self = shift; 
		     return ($self->{'PageTitle'} eq "spine");}

sub setPageTitle    {my $self = shift; $self->{'PageTitle'} = shift; 
		     return $self->{'PageTitle'};}

sub initBatchCnt    {my $self=shift; $self->{'batchcnt'}=$self->{'batchlen'}; 
		     return $self->{'batchcnt'};}

sub decBatchCnt     {my $self = shift; 
		     if (--$self->{'batchcnt'} < 0) {$self->{'batchcnt'}=0;}
		     return $self->{'batchcnt'};}

sub pageTitle       {return shift->{'PageTitle'};}
sub totalSheets     {return shift->{'Total_Sheets'};}
sub batchLength     {return shift->{'batchlen'};}
sub pagesPerSheet   {return shift->{'pgspersheet'};}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Scanner::Job - Handle a scanning job, where job is usually a document.

=head1 SYNOPSIS

 use Scanner::Job;
 $obj = Scanner::Job->new($scanner,$firstpage,$format,$spine_width_inches,$total_sheets,$path,$date,$publication);

 $obj = $obj->scan;
 $obj = $obj->nextPageNumbers;
 $str = $obj->pageid;
 $str = $obj->guessPageTitle;
 $num = $obj->setPagesPerSheet ($pgs);
 $num = $obj->setPagesPerSheetAsIn ($line);
 $num = $obj->setBatchLength ($num);
 $flg = $obj->isSpine;
 $str = $obj->setPageTitle;
 $num = $obj->initBatchCnt;
 $num = $obj->decBatchCnt;
 $str = $obj->pageTitle;
 $num = $obj->totalSheets;
 $num = $obj->batchLength;
 $num = $obj->pagesPerSheet;

=head1 Inheritance

 UNIVERSAL

=head1 Description

 Handle a scanning job, where job is usually a document.

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

  FirstPage          String identifying the number portion of the first 
                     page scanned. eg "000"
  FirstPageId        String identifying the the first page scanned, including
                     subpage numbers and such. eg "000a"
  FormatPage         Scanner::Format object for pages
  SpineFormat        Scanner::Format object for spine.
  scanner            Scanner object.
  Total_Sheets       Total sheets in document. Not really used yet.
  pgspersheet        Pages per scanned sheet. Usually 1 or 2.
  batchlen	     Number of pages in ADF scan batch.
  batchcnt	     Page count of ADF scan batch.
  PageTitle          Type of page. cover, backcover, contents...
  curpgobj1	     Document::PageIterator for the page, or of the left
		     hand page if there are two.
  curpgobj2	     Document::PageIterator for the page, or of the right
		     hand page if there are two.

=head1 Class Methods

=over 4

=item B<$obj = Scanner::Job-E<gt>new ($scanner,$firstpage,$format,$spine_width_inches,$total_sheets,$path,$date,$publication)>

Create and initialize instances of Scanner::Job.

 scanner              A Scanner object.
 firstpage            Page number to begin scanning at.
 format               A page format string, ie "L:10x12"
 spine_width_inches   Width of the document spine.
 total_sheets         Total sheets in the document. Not really used yet.
 path                 Where to put the document.
 date                 Date of the document.
 publication          Name of the publication, title and author of book or
                      paper, etc.

=head1 Instance Methods

=over 4

=item B<$obj = $obj-E<gt>scan>

Set up the information for the next page of the document and scan it. The
page will be named, placed in its document directory and logged and added
to the table of contents file there.

If the page name is the special token 'spine', then the special pageid of
"000.spine" is used instead of the current pageid and the document scan
format is set for the width of the spine in whichever dimension on the
scanbed is appropriate: scanner height if landscape; scanner width if
portrait.

Returns self.

=item B<$num = $obj-E<gt>nextPageNumbers>

Increment the page number or numbers.

Returns self.

=item B<$str = $obj-E<gt>pageid>

Return a pageid string made up from info from one or two pageid objects.
Returns <pageid1> or <pageid1>-<pageid2>

=item B<$str = $obj-E<gt>guessPageTitle>

Make our best guess at what the user is going to want for the title.
Returns PageTitle.

=item B<$num = $obj-E<gt>setPagesPerSheet ($pgs)>

Set the number of pages per sheet and return the value when done.

=item B<$num = $obj-E<gt>setPagesPerSheetAsIn ($line)>

Set the pages per sheet to match $line and return the result of doing so.

=item B<$num = $obj-E<gt>setBatchLength ($n)>

Set the batch length and return the result of doing so.

=item B<$flg = $obj-E<gt>isSpine>

Return true if the page is the document spine, ie the page number is 000.spine.

=item B<$str = $obj-E<gt>setPageTitle>

Set the page title and return the result of doing so.

=item B<$num = $obj-E<gt>initBatchCnt>

Set the batch count to the batch length and return the result.

=item B<$num = $obj-E<gt>decBatchCnt>

Decrement the batch count until it reaches 0. Returns the value
after the decrement.

=item B<$str = $obj-E<gt>pageTitle>

Returns the page title.

=item B<$num = $obj-E<gt>totalSheets>

Returns the total sheets.

=item B<$num = $obj-E<gt>batchLength>

Returns the batch length.

=item B<$num = $obj-E<gt>pagesPerSheet>

Returns the pages per sheet.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Document::LogFile, Document::TocFile, Document::Toc, Document::PageIterator,
Scanner, Scanner::Page

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Job.pm,v $
# Revision 1.3  2008-08-28 23:31:44  amon
# Major rewrite. Shuffled code between classes and add lots of features.
#
# Revision 1.2  2008-08-07 19:52:48  amon
# Upgrade source format to current standard.
#
# Revision 1.1.1.1  2008-08-06 21:36:11  amon
# Classes for scanner use abstractions.
#
# 20070511   Dale Amon <amon@islandone.org>
#	     Created.
1;
