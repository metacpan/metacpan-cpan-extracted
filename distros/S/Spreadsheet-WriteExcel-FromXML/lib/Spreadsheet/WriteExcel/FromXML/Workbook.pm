package Spreadsheet::WriteExcel::FromXML::Workbook;
use strict;
use warnings;

our $VERSION = '1.1';

use Carp qw(confess cluck);
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Big;
use Spreadsheet::WriteExcel::FromXML::Worksheet;

=head1 NAME

Spreadsheet::WriteExcel::FromXML::Workbook

=head1 SYNOPSIS

  # inner class for use by FromXML

=head1 DESCRIPTION

Workbook object for FromXML.

=head1 API REFERENCE

=head2 new

Consturctor for Workbook object.

=cut
sub new
{
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = {};
  bless $self,$class;
  $self->_init(@_);
  return $self;
}

=head2 _init

Creates a new report buffer, file handle and Spreadsheet::WriteExcel
object.

=cut

sub _init
{
  my($self,$bigflag) = @_;
  my $buff = '';
  $self->_buffer( \$buff );
  $self->excelFh( IO::Scalar->new( $self->_buffer ) );
  my $workbook = '';
  if( $bigflag )
  {
    $workbook = Spreadsheet::WriteExcel::Big->new( $self->excelFh );
  }
  else
  {
    $workbook = Spreadsheet::WriteExcel->new( $self->excelFh );
  }
  $self->excelWorkbook( $workbook );
  unless( $self->excelWorkbook )
  {
    confess "Could not create a Spreadsheet::WriteExcel object.  This is bad!\n";
  }
  $self->worksheets( {} );
  $self->formats( {} );
  $self->worksheetOrder( [] );
}

=head2 addWorksheet($)

Param:  title - title for the worksheet that people will see in the Excel spreadsheet.
Return: void

Creates & adds a new worksheet to the spreadsheet.  It keeps track of the
order the worksheets were added and a hash table so one can easily reference
them later.

=cut
sub addWorksheet
{
  my($self,$title, $landscape, $paper, $header, $header_margin, $footer, $footer_margin) = @_;
  if( exists $self->worksheets->{ $title } )
  {
    confess "Worksheet already exists with name '$title'\n";
  }
  my $sheet = $self->excelWorkbook->add_worksheet( $title ) ;
  my $ws = Spreadsheet::WriteExcel::FromXML::Worksheet->new( $sheet );
  $self->worksheets->{ $title } = $ws;
  $sheet->set_landscape() if defined($landscape);
  $sheet->set_paper($paper) if defined($paper);
  unless( $self->worksheets->{ $title } )
  {
    confess "Couldn't create a new worksheet on ",$self->excelWorkbook,"??\n";
  }

  if (defined($header)) {
    #print "Header: $header\n";
    if (!defined($header_margin)) {
      $sheet->set_header($header);
    } else {
      $sheet->set_header($header, $header_margin);
    }
  }

  if (defined($footer)) {
    #print "Footer: $footer\n";
    if (!defined($footer_margin)) {
      $sheet->set_footer($footer);
    } else {
      $sheet->set_header($footer, $footer_margin);
    }
  }

  push @{ $self->worksheetOrder }, $title;
  return $self->worksheets->{ $title };
}

sub addFormat
{
  my($self,$attr) = @_;
  my $name = $attr->{'name'};
  if( exists $self->formats->{ $name } )
  {
    cluck "format with the name '$name' already exists.  Ignoring.\n";
    return 1;
  }
  delete $attr->{'name'};
  my $format = $self->excelWorkbook->add_format();
  foreach my $k ( keys %{ $attr } )
  {
    my $method = 'set_'.$k;
    # Hack for alignment
    if ($k eq 'align' && ($attr->{'valign'} || $attr->{'halign'})) {
      next; # ignore align if valign or halign are set...
    }
    elsif ($k eq 'halign' or $k eq 'valign')
    {
      $method = 'set_align';
    }
    # print STDERR "Adding format for $method to $format\n";
    $format->$method( $attr->{$k} );
  }
  $self->formats->{ $name } = $format;
  return 1;
}

=head2 getWorksheet($)

Param:  name  - hash table namespace for the worksheet.
Return: Worksheet object associated with name.

Accesses the hash table of worksheets and returns the worksheet with the
specified name.

=cut
sub getWorksheet
{
  my($self,$name) = @_;
  return undef unless exists $self->worksheets->{ $name };
  return $self->worksheets->{ $name };
}

sub getWorksheetsInOrder
{
  my($self) = @_;
  return @{ $self->worksheets }{ @{ $self->worksheetOrder } };
}

sub buildWorkbook
{
  my($self) = @_;
  foreach my $worksheet ( $self->getWorksheetsInOrder ) {
    $worksheet->buildWorksheet( $self->formats );
  }
  $self->excelWorkbook->close;
  return 1;
}

sub getFormat
{
  my($self,$name) = @_;
  return undef unless exists $self->formats->{ $name };
  return $self->formats->{ $name };
}

sub excelFh
{
  my $self = shift;
  if( @_ ) {
    $self->{'_excelFh'} = shift;
  }
  return $self->{'_excelFh'};
}

sub getSpreadsheetData
{
  my($self) = @_;
  return ${ $self->_buffer };
}

sub _buffer
{
  my $self = shift;
  if( @_ ) {
    $self->{'__buffer'} = shift;
  }
  return $self->{'__buffer'};
}

sub excelWorkbook
{
  my $self = shift;
  if( @_ ) {
    $self->{'_excelWorkbook'} = shift;
  }
  return $self->{'_excelWorkbook'};
}

sub worksheets
{
  my $self = shift;
  if( @_ ) {
    $self->{'_worksheets'} = shift;
  }
  return $self->{'_worksheets'};
}

sub formats
{
  my $self = shift;
  if( @_ ) {
    $self->{'_formats'} = shift;
  }
  return $self->{'_formats'};
}

sub worksheetOrder
{
  my $self = shift;
  if( @_ ) {
    $self->{'_worksheetOrder'} = shift;
  }
  return $self->{'_worksheetOrder'};
}

1;

=head1 SEE ALSO

SpreadSheet::WriteExcel::FromXML

=head1 AUTHORS

W. Justin Bedard juice@lerch.org

Kyle R. Burton mortis@voicenet.com, krburton@cpan.org

=cut
