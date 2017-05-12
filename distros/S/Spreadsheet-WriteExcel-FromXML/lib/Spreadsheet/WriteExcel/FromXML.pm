package Spreadsheet::WriteExcel::FromXML;
use strict;
use warnings;

our $VERSION = '1.1';
use Carp qw(confess cluck);

use Spreadsheet::WriteExcel::FromXML::Workbook;
use IO::Scalar;
use XML::Parser;

=head1 NAME

Spreadsheet::WriteExcel::FromXML - Create Excel Spreadsheet from XML

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Spreadsheet::WriteExcel::FromXML;
  my $fromxml = Spreadsheet::WriteExcel::FromXML->new( "file.xml" );
  $fromxml->parse;
  $fromxml->buildSpreadsheet;
  $fromxml->writeFile("file.xls");
  # or
  my $data = $fromxml->getSpreadsheetData;
  # then write $data to a file...or do with it as you wish

  # or, even simpler:
  my $data = Spreadsheet::WriteExcel::FromXML->BuildSpreadsheet( "file.xml" );

  # or, even simpler:
  Spreadsheet::WriteExcel::FromXML->XMLToXLS( "file.xml", "file.xls" );

=head1 DESCRIPTION

This module uses Spreadsheet::WriteExcel to turn a simple XML data
file into a binary Excel XLS file.

See also the FromXML.dtd file in the distribution.

=head1 API REFERENCE

=head2 new([$])

Param:  XML file name - name of file to be parsed.
Return: ToExcel object.

Constructor.  Optionally takes an XML file name.

=cut

sub new
{
  my($this,$xmlsource,$bigflag)  = @_;
  my $class = ref($this) || $this;
  my $self  = {};
  bless $self,$class;

  $self->_initializeXMLSource($xmlsource) if $xmlsource;
  $self->bigflag( $bigflag ) if $bigflag;

  return $self;
}

sub BuildSpreadsheet
{
    my($this,$file,$bigflag) = @_;
    my $fromxml = Spreadsheet::WriteExcel::FromXML->new($file,$bigflag);
    $fromxml->parse;
    $fromxml->buildSpreadsheet;
    return $fromxml->getSpreadsheetData;
}

sub XMLToXLS
{
    my($this,$source,$dest,$bigflag) = @_;
    my $fromxml = Spreadsheet::WriteExcel::FromXML->new($source,$bigflag);
    $fromxml->parse;
    $fromxml->buildSpreadsheet;
    return $fromxml->writeFile($dest);
}

=head2 private void _initializeXMLSource($)

Param:  XML file source (GLOB, IO::Handle, file name or XML as a string [or scalar ref])
Return: true
Throws: exception if unable to

Initializer method to check for existance of the XML file.

=cut

sub _initializeXMLSource
{
  my($self,$xmlsource) = @_;

  $self->_closeXMLSource;

  unless( defined $xmlsource && length($xmlsource) ) {
      confess "Error, \$xmlsource is a required parameter!\n";
  }

  if( UNIVERSAL::isa( $xmlsource, 'IO::Handle' ) || UNIVERSAL::isa( $xmlsource, 'GLOB' ) ) {
      $self->_debug("_initializeXMLSource: xmlsource:'$xmlsource' was an IO::Handle or GLOB");
      $self->_xmlfh( $xmlsource );
      $self->_shouldCloseSource(undef);
      return 1;
  }

  if( '.xml' eq substr($xmlsource, -4) && -r $xmlsource ) {
      $self->_debug("_initializeXMLSource: xmlsource:'$xmlsource' was a file path.");
      my $fh;
      unless( open $fh, $xmlsource ) {
          confess "Cannot open '$xmlsource' : $!\n";
      }

      $self->_xmlfh( $fh );
      $self->_shouldCloseSource(1);
      return 1;
  }

  if( UNIVERSAL::isa( $xmlsource, 'SCALAR' )  ) {
      $self->_debug( "_initializeXMLSource: xmlsource:'$xmlsource' was a scalar reference.");
      my $ioh = IO::Scalar->new( $xmlsource ) or confess "Error setting parsing from string: $!\n";
      $self->_xmlfh( $ioh );
      $self->_shouldCloseSource(1);
      return 1;
  }

  # assume a string of XML...
  if( 0 != index( $xmlsource, '<?xml' ) ) {
      confess "Error: xmlsource wasn't a file handle, glob, or a file ",
        "in the file system, and xmlsource(",substr($xmlsource,0,64),
        "...) doesn't look like XML to me (doesn't start with '<?xml')\n";
  }

  $self->_debug( "_initializeXMLSource: xmlsource(",length($xmlsource),") was a string." );
  my $ioh = IO::Scalar->new( \$xmlsource ) or confess "Error setting parsing from string: $!\n";
  $self->_xmlfh( $ioh );
  $self->_shouldCloseSource(1);

  return 1;
}

sub _closeXMLSource
{
  my($self) = @_;
  if( $self->_xmlfh && $self->_shouldCloseSource ) {
    close( $self->_xmlfh ) or confess "Error closing xmlsource! : $!\n";
    $self->_xmlfh(undef);
  }
  return 1;
}

sub DESTROY
{
  my($self) = @_;
  $self->_closeXMLSource;
}

=head2 parse

Param:  XML file name or an IO::Handle [optional].
Return: true
Throws: exception if xmlsource initialization fails, or if parsing fails

A method to make the necessary calls to parse the XML file.  Remember,
if a file handle is passed in the calling code is responsible for
closing it.

=cut

sub parse
{
  my($self,$xmlsource) = @_;

  $self->_initializeXMLSource( $xmlsource ) if $xmlsource;
  confess "Error, never initialized with an xml source!\n" unless $self->_xmlfh;

  $self->_parseXMLFileToTree;

  my $type = shift @{ $self->_treeData };
  my $ar   = shift @{ $self->_treeData };
  my $rownum = -1; my $colnum = -1;
  $self->_processTree( $ar, $type, \$rownum, \$colnum );

  return 1;
}

=head2 _parseXMLFileToTree

Param:  none.
Return: true

A method to parse an XML file into a tree-style data structure
using XML::Parser.

=cut
sub _parseXMLFileToTree
{
  my($self) = @_;

  eval {
      my $p = new XML::Parser( 'Style' => 'Tree' );
      $self->_treeData( $p->parse( $self->_xmlfh ) );

  };

  if($@) {
      confess "Error calling XML::Parser->parse threw exception: $@";
  }

  unless( defined $self->_treeData ) {
      confess "Error calling XML::Parser->parse.  No data was parsed!\n";
  }

  return 1;
}

=head2 _processTree

  Param: $ar         - child xml elements
  Param: $xmltag     - the xml tag name (string)
  Param: $rownum     - the current row number in the internal worksheet
  Param: $column     - the current column number in the current row
  Param: $rowformat
  Return: void.

A method for taking the tree-style data structure from XML::Parser and
sticking the data into our object structure & Spreadsheet::WriteExcel.
After this method is called, we have an Excel spreadsheet ready for
output.

=cut

sub _processTree
{
  my($self,$ar,$xmltag,$rownum,$colnum,$rowformat,$rowdatatype,$coldatatype) = @_;
  my $attr = shift @{ $ar } || {};

  if( 'workbook' eq $xmltag )
  {
    $self->workbook( Spreadsheet::WriteExcel::FromXML::Workbook->new($self->bigflag) );
  }
  elsif( 'worksheet' eq $xmltag )
  {
     unless( exists $attr->{'title'} && $attr->{'title'} ) {
       confess "Must define a title attribute for worksheet!\n";
     }
     $self->currentWorksheet( $self->workbook->addWorksheet( $attr->{'title'}, $attr->{'landscape'}, $attr->{'paper'}, $attr->{'header'}, $attr->{'header_margin'}, $attr->{'footer'}, $attr->{'footer_margin'} ) );
     ${ $rownum } = -1; # new worksheet, reset the row count.
  }
  elsif( 'row' eq $xmltag )
  {
    ++${ $rownum };
    ${ $colnum } = -1; # new row, reset the column count.
    $rowformat   = undef;
    $rowdatatype = undef;
    if( exists $attr->{'format'} )
    {
      $rowformat = $attr->{'format'};
    }
    if( exists $attr->{'type'} )
    {
      $rowdatatype = $attr->{'type'};
    }
  }
  elsif( 'cell' eq $xmltag )
  {
    ++${ $colnum };
    my $tmp  = shift @{ $ar };
    my $data = shift @{ $ar } || '';
    # Partial DTD validation
    # if( ref($data) )
    # {
    #   confess "Unexpected XML syntax.  <cell> tag should not contain any other tags (row ".(++${$rownum}).", col ".(++${$colnum}).").\n";
    # }

    my $format = $rowformat || undef;
    my $datatype = $rowdatatype || $coldatatype || 'string';
    if( exists $attr->{'format'} )
    {
      $format = $attr->{'format'};
    }
    if( exists $attr->{'type'} )
    {
      $datatype = $attr->{'type'};
    }
    $self->currentWorksheet->addCell( $data, $datatype, $rownum, $colnum, $format );
  }
  elsif( 'format' eq $xmltag )
  {
     unless( exists $attr->{'name'} && $attr->{'name'} ) {
       confess "Must define a name attribute for format!\n";
     }
     # $self->_debug( "Adding format ",$attr->{'name'} );;
     $self->workbook->addFormat( $attr );
  }
  # Range implements set_column functionality
  elsif ('range' eq $xmltag)
  {
    unless (exists $attr->{'first_col'}) {
      confess "Must define a first column for ranges!\n";
    }
    $self->currentWorksheet->addRange($attr->{'first_col'}, $attr->{'last_col'},
                                        $attr->{'width'}, $attr->{'format'},
                                        $attr->{'hidden'}, $attr->{'level'});
  }
  elsif ('margins' eq $xmltag)
  {
    my $tmp  = shift @{ $ar };
    my $data = shift @{ $ar } || undef;
    my $lr  = $attr->{'lr'} || undef;
    my $tb  = $attr->{'tb'} || undef;
    my $left = $attr->{'left'} || undef;
    my $right = $attr->{'right'} || undef;
    my $top = $attr->{'top'} || undef;
    my $bottom = $attr->{'bottom'} || undef;

    $self->currentWorksheet->setMargins($data, $lr, $tb, $left, $right, $top, $bottom);
  }
  else
  {
    cluck "Unrecognized type '$xmltag'.  Ignored.\n";
  }

  for( my $i = 0; $i < @{ $ar }; ++$i )
  {
    if( 'ARRAY' eq ref( $ar->[$i] ) )
    {
      $self->_processTree( $ar->[$i], $ar->[$i-1], $rownum, $colnum, $rowformat, $rowdatatype );
    }
  }
}

sub buildSpreadsheet
{
  my($self) = @_;
  unless ( $self->workbook ) {
    confess "Workbook is uninitialized.  Did you call parse?\n";
  }
  $self->workbook->buildWorkbook;
  return 1;
}

=head2 writeFile($)

Param:  filename - file name to output Excel data to.
Return: true/false
Throws: exception if unable to open the file.

writeFile takes a file name and writes the XLS data from the internal buffer
to the specified file.

=cut

sub writeFile
{
  my($self,$filename) = @_;
  unless( $filename ) {
    confess "Must pass writeFile a file name.\n";
  }

  $self->_debug("writing to file: $filename");
  my $fh;
  unless( open $fh, '>', $filename ) {
    confess "Cannot open '$filename': $!\n";
  }
  binmode $fh;
  print $fh $self->getSpreadsheetData;
  close $fh;
  return 1;
}

=head2 getSpreadsheetData

Once the spreadsheet has been generated, this method returns the
binary representation of the spreadsheet.

=cut

sub getSpreadsheetData
{
    my($self) = @_;
    return $self->workbook->getSpreadsheetData;
}

=head2 workbook([$])

Get/set method to reference our Workbook object.

=cut

sub workbook { @_>1 ? $_[0]->{'_workbook'} = $_[1] : $_[0]->{'_workbook'}; }

sub currentWorksheet { @_>1 ? $_[0]->{'_currentWorksheet'} = $_[1] : $_[0]->{'_currentWorksheet'}; }
sub currentWorkbook  { @_>1 ? $_[0]->{'_currentWorkbook'} = $_[1] : $_[0]->{'_currentWorkbook'}; }

=head2 _treeData([$])

Get/set method for the raw XML tree data.

=cut
sub _treeData { @_>1 ? $_[0]->{'_treeData'} = $_[1] : $_[0]->{'_treeData'}; }


=head2 _xmlfh([$])

Get/set method for the XML file that is being parsed.

=cut
sub _xmlfh { @_>1 ? $_[0]->{'_xmlfh'} = $_[1] : $_[0]->{'_xmlfh'}; }


{my $debug = 0;
sub debug { @_>1 ? $debug = $_[1] : $debug; }
sub _debug
{
    my($self,@msg) = @_;
    return undef unless $debug;
    my($p,$f,$l) = caller();
    print "$p->$f($l): ",@msg,"\n";
}
}


sub _shouldCloseSource { @_>1 ? $_[0]->{'_shouldCloseSource'} = $_[1] : $_[0]->{'_shouldCloseSource'}; }

=head2 bigflag([$])

Get/set method for large (>7mb) Excel spreadsheets.  If set, the code will make the
appriopriate calls to build a spreadsheet >7mb.  This requires a patch to
OLE::Storage_Lite.

=cut
sub bigflag { @_>1 ? $_[0]->{'_bigflag'} = $_[1] : $_[0]->{'_bigflag'}; }

1;


=head1 SEE ALSO

SpreadSheet::WriteExcel
SpreadSheet::WriteExcel::FromDB
OLE::Storage_Lite

=head1 AUTHORS

W. Justin Bedard juice [at] lerch.org

Kyle R. Burton mortis [at] voicenet.com, krburton [at] cpan.org

Brendan W. McAdams bwmcadams [at] cpan.org <Since 1.10>

=cut
