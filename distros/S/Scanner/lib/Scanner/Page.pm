#================================= Page.pm ===================================
# Filename:  	       Page.pm
# Description:         Physical Page Class for Scanners.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:31:44 $ 
# Version:             $Revision: 1.3 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Scanner::Format;

package Scanner::Page;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				CLASS METHODS
#=============================================================================
$Scanner::Page::DEFAULT_NAME_VERIFIER = undef;

sub defaultNameVerifierIs {
  my ($class, $obj) = @_; 
  if (!defined $obj) {
    $Scanner::Page::DEFAULT_NAME_VERIFIER = undef;
    return 1;
  }
  ref ($obj) || (return 0);
  $Scanner::Page::DEFAULT_NAME_VERIFIER = $obj;
  return 1;
}

#-----------------------------------------------------------------------------

sub new {
  my $class  = shift;
  my %params = @_;
  my $self   = bless {}, $class;
  
  $self->_setFormat   (\%params) || return undef;
  $self->_setPageName (\%params) || return undef;
  
  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub pagetitle {
  my $s = shift;
  my @list;
  
  my ($date, $title, $pageid, $subtitle) = 
    @$s{'date','title','pageid','subtitle'};
  ($pageid = "p" . $pageid) if ($pageid);
  
  foreach ( $date, $title, $pageid, $subtitle) {$_ && push @list, $_; }
  return undef if ($#list == -1);
  
  my $t = $list[0]; 
  for (my $i=1; $i < $#list+1; $i++) {$t .= "-" . $list[$i]; }
  return $t;
}

#-----------------------------------------------------------------------------

sub info ($) {
  my $self = shift;
  printf  "[Page]\n" . 
	  "Page Title:                %s\n" .
	  "Date:                      %s\n" .
	  "Title:                     %s\n" .
	  "PageId:                    %s\n" .
	  "Subtitle:                  %s\n",
	  $self->pagetitle,
	  $self->{'date'},
	  $self->{'title'},
	  $self->{'pageid'},
	  $self->{'subtitle'};
  print "\n";
  $self->{'format'}->info ("Scan");
  return $self;
}

#-----------------------------------------------------------------------------

sub landscape      { shift->{'format'}->landscape;      }
sub portrait       { shift->{'format'}->portrait;       }
sub ScanDimensions {(shift->{'format'}->ScanDimensions);}
sub date           { shift->{'date'};                   }
sub title          { shift->{'title'};                  }
sub pageid         { shift->{'pageid'};                 }
sub subtitle       { shift->{'subtitle'};               }

#=============================================================================
#			INTERNAL CLASS METHODS
#=============================================================================
# Verify that the list of elements can be used to create a page title.

sub _validateName {
  my ($self,$date,$title,$pageid,$subtitle) = @_;
  
  ((length($date) + length($title) + length($pageid) + length ($subtitle)) > 0) 
    || return 0;
  
  if ($Scanner::Page::DEFAULT_NAME_VERIFIER) {
    $Scanner::Page::DEFAULT_NAME_VERIFIER->validateName
      ( @$self{'date','title','pageid','subtitle'} ) || (return 0);
  }
  return 1;
}

#=============================================================================
#			INTERNAL OBJECT METHODS
#=============================================================================

sub _setPageName {
  my ($self, $params) = @_;

  @$self{'date','title', 'pageid','subtitle'} = ("", "", "", "" );
  ($self->{'date'}    = $params->{'date'})     if defined $params->{'date'};
  ($self->{'title'}   = $params->{'title'})    if defined $params->{'title'};
  ($self->{'pageid'}  = $params->{'pageid'})   if defined $params->{'pageid'};
  ($self->{'subtitle'}= $params->{'subtitle'}) if defined $params->{'subtitle'};
  
  Scanner::Page->_validateName ( @$self{'date','title','pageid','subtitle'} )
      || (return 0);
  return 1;
}

#-----------------------------------------------------------------------------

sub _setFormat {
  my ($self, $params) = @_;
  defined $params->{'format'} or return 0;
  
  $self->{'format'} = $params->{'format'};
  return 1;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Scanner::Page - Representation of a Page to be passed to a Scanner.

=head1 SYNOPSIS

 use Scanner::Page;

 $obj  = Scanner::Page->new ( list of named arguments );
 $bool = Scanner::Page->defaultNameVerifierIs ( $myverifierobj );

 $pagetitle        = $obj->pagetitle;
 $date             = $obj->date;
 $title            = $obj->title;
 $pageid           = $obj->pageid;
 $subtitle         = $obj->subtitle;
 ($width, $height) = $obj->ScanDimensions;
 $flg              = $obj->landscape;
 $flg              = $obj->portrait;
 $obj              = $obj->info;

=head1 Inheritance

 UNIVERSAL

=head1 Description

Pages are transient objects used to pass information to Scanner::Device and
Document::Directory objects.

=head1 Examples

 use File::Spec::Scanner::Page;

 my $flg = Scanner::Page->defaultNameVerifierIs ( $myvfyobj );

 my $pg  = Scanner::Page->new ( 'format'      => $fmt,
				'date'        => "20080818",
                                'title'       => "DailyBoggle",
                                'pageid'      => "001",
                               );

 if ($pg->landscape) {print "It is a landscape page.\n";}
 if ($pg->portrait ) {print "It is a portrait  page.\n";}

 my ($x,$y) = $pg->ScanDimensions;
 my $pt     = $obj->pagetitle;
 my $date   = $obj->date;
 my $title  = $obj->title;
 my $pgnum  = $obj->pageid;
 my $stitle = $obj->subtitle;

=head1 Class Variables

 DEFAULT_NAME_VERIFIER      Class used for verifying a page name 
                            consisting of  the a set or subset of 
                            date-title-pageid-subtitle. Default is undef.

=head1 Instance Variables

 format         A Scanner::Format object.
 date           The date part of the page name, eg 19941224.
 title          The document title portion of the name.
 pageid         The pageid, usually a simple page number: 104.
 subtitle       The page title portion of the name.

=head1 Class Methods

=over 4

=item B<$bool = Scanner::Page-E<gt>defaultNameVerifierIs ( $obj )>

Sets the default verifier object. Returns true if it succeeded. A false return
could indicate $obj is not a ref. undef is a valid value and will restore the
default behavior of the class, ie to do not much of anything about checking
the name related fields.

A Scanner::Page has several fields for the input of strings used in
constructing a full page name. The actual format of these is not directly
enforced by this object other than a requirement that the concatenation of
them all generate a nonzero string length. 

In practice it is desirable to check that these fields have strings which will
create valid file names when put together in the form:

	date-title-pageid-subtitle

and from which the scanner will eventually create:

	date-title-pageid-subtitle.jpeg

If you wish each new object to check these fields rather than blindly use them
as it does by default, you may load a default object with this Class method.
Your object must have a method like this:

  $bool = $myobj->validateName ( $date, $title, $pageid, $subtitle )

If you do nothing, only the simplest of checks, as noted earlier, are done.
This may be adequate for many applications which only wish to use the 'title'
field and nothing else.

=item B<$obj = Scanner::Page-E<gt>new ( named argument list )>

This is the Class method for creating new Scanner::Page objects. It may have
many different arguments. They are in short:

		format     -> $fmtobj         [REQUIRED]
		date       -> date string     [OPT: default is ""]
		title      -> title string    [OPT: default is ""]
		pageid     -> pageid string   [OPT: default is ""]
		subtitle   -> subtitle string [OPT: default is ""]

'format' => <Scanner::Format object>

A format object that defines the orientation and size of the page.

'date' => <date string>

A date to be included as the first part of the page name, where a  single date
is represented as:

	yyyymmdd
	yyyymmddhhmmss

and mm and dd may be 00 to represent 'the whole month' or the  'whole year' as
in a monthly magazine or a yearly report, or to  represent uncertainty, 'it
was from sometime in that year'. there may optionally be two dates, so as to
represent a period  of time associated with the page:

	date1-date2

The default is the null string: "".

'title' => <title string>

The title associated with the document of which this page is a part or whole
if there is only one page. eg

	ModernQuantumTheory

The default is the null string: "".

'pageid' => <pageid string>

If the document is part of a multi-page document, a representation of the page
number is needed. There may be two adjacent pages if the current page is an
opened booklet on the scanner. Pageid's may look like the following:

		000a
		001
		043.01
		001-002

The default is the null string: "".

'subtitle'  => <subtitle string>

An individual title for the page, the name of an article within a  magazine, a
comment about the contents of the page... 

	TheCatDied-SmithAndWesson-itsNotDeadYet

The default is the null string: "".

It returns either a pointer to the newly created and initialized object or
undef if the object could not be created.

=back 4

=head1 Instance Methods

=over 4

=item B<$date = $obj-E<gt>date>

Return the date string.

=item B<($width, $height) = $obj-E>gt>ScanDimensions>

Retrieve the page dimensions to be used for scanning. The height may include
extra space for calibration devices as earlier discussed in the
Scanner::Page->setDefaultCalibratorFlag section:

	(width, height+calibratorheight)

The scanner might of course have something to say about the height or width we
have selected! That, however, is not the Page's problem. It is what it is and
it might be too large for the scanner you have.

=item B<$obj = $obj-E<gt>info>

Print info on the Scanner::Page to stdout. 

=item B<$flg = $obj-E<gt>landscape>

Return true if it uses a landscape page format.

=item B<$pageid = $obj-E<gt>pageid>

Return the pageid string.

=item $pagetitle = $obj->pagetitle

Generate the full page title. There are four possible elements, any of which
might be null. The page title is built from whichever of date, title, pageid
and subtitle are non-null. The title is built up in the order:

	<date>-<title>-p<pageid>-<subtitle>

Possible pagetitles are:

 20040819
 20040819-QuantumTheory
 20040819-p001
 20040819-20100918-QuantumTheoryAdvances-p005-010-ForwardByMartians

If somehow all four are null, undef is returned instead of a string.

[Internal code question: how should I handle the  'p' that goes before a
pageid?]

=item B<$flg = $obj-E<gt>portrait>

Return true if it uses a portrait page format.

=item B<$subtitle = $obj-E<gt>subtitle>

Return the subtitle string.

=item B<$title = $obj-E<gt>title>

Return the title string.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Page.pm,v $
# Revision 1.3  2008-08-28 23:31:44  amon
# Major rewrite. Shuffled code between classes and add lots of features.
#
# Revision 1.2  2008-08-07 19:52:48  amon
# Upgrade source format to current standard.
#
# Revision 1.1.1.1  2006-06-15 22:06:59  amon
# Classes for scanner use abstractions.
#
# 20060615	Dale Amon <amon@islandone.org>
#		Added check for an attempt to set a zero hieght or width.
# 20040818	Dale Amon <amon@islandone.org>
#		Created.
1;
