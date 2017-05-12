package OpenOffice::Parse::SXC;

use 5.006;
use strict;
use warnings;
use XML::Parser;
use IO::File;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenOffice::Parse::SXC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parse_sxc csv_quote dump_sxc_file
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);
our $VERSION = '0.03';

my %valid_options	= ( worksheets	=> 1,
			    no_trim	=> 1,
			  );

##################################################################
# EXPORT_OK methods:

sub csv_quote {
  my $text		= shift;
  return ""		if( ! defined $text );
  $text =~ s/\n//g;	# Remove all newlines!
  $text =~ s/\"/\"\"/g;
  if( $text =~ /[,"']/ ) {
    $text		= "\"$text\"";
  }
  return $text;
}

sub parse_sxc {
  my $sxc_filename		= shift;
  my %options			= @_;
  my $SXC			= OpenOffice::Parse::SXC->new( %options );
  # OpenOffice::Parse::SXC implements the 'data_handler' interface, so we can
  # create an object to use itself as a data handler.
  $SXC->set_data_handler( $SXC );
  $SXC->parse_file( $sxc_filename );
  return $SXC->parse_sxc_rows;
}

# Used for debugging, dump_sxc_file parses a file and dumps the resultant objects
# onto STDOUT.  This is a good way to view just what's going on behind the scenes.

sub dump_sxc_file {
  my $filename		= shift;
  my $Parser		= XML::Parser->new( Style	=> "Objects" );

  my $results		= $Parser->parsefile( $filename );
  print Dumper( $results );
}

##################################################################
# The data_handler routines:
#
# These are provided to provide the simple interface parse_sxc()
#
# See parse_sxc() for more details

sub row {
  my $self		= shift;
  shift;
  my $row		= shift;
  push @{$self->{parse_sxc_rows}}, $row;
#  print join(",", @$row ),"\n";
}

sub worksheet {
  my $self		= shift;
  shift;
  my $worksheet		= shift;
  if( ! $self->{parse_sxc_rows} ) {
    $self->{parse_sxc_rows}	= [];
  }
#  print "IN WORKSHEET '$worksheet'.\n";
}

sub workbook {
  my $self		= shift;
  shift;
  my $workbook		= shift;
#  print "IN WORKBOOK '$workbook'.\n";
}

sub parse_sxc_rows {
  my $self		= shift;
  return @{$self->{parse_sxc_rows}};
}

sub clear_parse_sxc_rows {
  my $self		= shift;
  $self->{parse_sxc_rows}	= [];
}


# End data_handler routines
##################################################################

##################################################################
# Main OpenOffice::Parse::SXC methods:

sub new {
  my $type		= shift;
  my $self		= { options	=> {},
			  };
  bless $self, $type;
  my %options		= @_;
  $self->set_options( %options )	if( %options );
  $self->repeat_following_cell( 1 );	# Times the cell is to be repeated
  $self->repeat_following_row( 1 );	# Times the row is to be repeated
  $self->reset_cell_list;		# Clear out the cell list
  # If the user hasn't supplied a row handler, set up a default one for
  # him which prints out the data to STDOUT.
  if( ! $self->get_data_handler ) {
    $self->set_data_handler( $self );
  }
  $self->accept_rows( 0 );		# By default, start off accepting NOTHING
  $self->accept_cells( 0 );
  $self->accept_text( 0 );
  return $self;
}

# PUBLIC parse() accepts a filehandle

sub parse {
  my $self		= shift;

  my $SXC_FH		= shift;	# Data source

  # We need to use closures to provide a true object-oriented way of doing things.  This can
  # be considered a memory leak, but only a few bytes per parse call:
  my $Parser		= XML::Parser->new
    ( Handlers	=> { Start	=> sub { $self->start_handler( @_ ); },
		     Char	=> sub { $self->char_handler( @_ ); },
		     End	=> sub { $self->end_handler( @_ ); },
		   },
    );
  my $results		= $Parser->parse( $SXC_FH );
  return $results;
}

# PUBLIC calls parse() after opening a filehandle

sub parse_file {
  my $self		= shift;
  my $filename		= shift || die "No file to parse";

  if( ! -f $filename ) {
    die "Could not find file '$filename' to parse";
  }
  my $SXC_FH		= IO::File->new( "unzip -p $filename content.xml|" )
    || die "Could not open pipe: 'unzip -p $filename content.xml'";
  $self->get_data_handler->workbook( $self, $filename );
  return $self->parse( $SXC_FH );
}

# The XML::Parser handler for ending of tags.
# It's used to trigger the end of cell and end of row actions.

sub end_handler {
  my $self		= shift;

  my $Expat		= shift;
  my $type		= shift;

  if( $type eq "table:table-row" ) {
    if( $self->accept_rows ) {
      $self->accept_cells( 0 );
      $self->end_row;			# The row is done
    }
  }
  elsif( $type eq "table:table-cell" ) {
    if( $self->accept_cells ) {
      if( $self->accept_text ) {
	$self->end_cell;		# The cell is done
      }
      $self->accept_text( 0 );
    }
  }
  elsif( $type eq "text:p" ) {
    # Kludging along to infinity...  The data in each cell
    # comes in <text:p></text:p> tags.  Each is assumed to NOT end in
    # a newline, however, if a newline is added (<Alt-Return>) it ends
    # the previous <text:p> block and starts a new one.
    #
    # I'll add a newline after the end of each <text:p> tag, and then
    # remove the last newline on the list when the cell is 'closed'.
    if( $self->accept_text ) {
      $self->append_cell_data( "\n" );
    }
  }
}

# E() implements an "Object O Exists in list L" boolean function

sub E {
  my $item	= shift;
  my @set	= @_;
  for( @set ) {
    return 1	if( $item eq $_ );
  }
  return 0;
}

# The start_handler for XML::Parser.
# It's responsible for things such as the following:
#
# - Locking and allowing the parsing of worksheets, rows, and cells.
# - 

sub start_handler {
  my $self		= shift;
  my $Expat	= shift;

  my $type	= shift;
  my %args	= @_;
  if( $type eq "table:table" ) {
    # Restrict processing of a 'worksheet' if the user has specified worksheets that he wants:
    if( ! $self->get_option( "worksheets" ) or E( $args{"table:name"}, @{$self->get_option( "worksheets" )} ) ) {
      # Ok, we process this worksheet:
      $self->accept_rows( 1 );	# Accept rows
      $self->set_current_worksheet_name( $args{"table:name"} );
      $self->get_data_handler->worksheet( $self, $args{"table:name"} );
    }
    else {
      $self->accept_rows( 0 );	# Do not accept row data
    }
  }
  elsif( $type eq "table:table-row" ) {		# ROW

    if( $self->accept_rows ) {
      if( $args{"table:number-rows-repeated"} ) {
	# Cause next row to be repeated...
	$self->repeat_following_row( $args{"table:number-rows-repeated"} );
      }
      $self->accept_cells( 1 );
    }
  }
  elsif( $type eq "table:table-cell" ) {	# CELL

    if( $self->accept_cells ) {
      # Cell repeat
      if( $args{"table:number-columns-repeated"} ) {
	$self->repeat_following_cell( $args{"table:number-columns-repeated"} );
      }
      $self->accept_text( 1 );
    }
  }
  elsif( $type eq "text:s" ) {			# TEXT
    # NOTE: Text type 'text:s' = space, I assume!  OpenOffice uses this tag to
    # represent spaces that are longer than 2 characters.  There may be other
    # special 'text' elements, but I'm unaware of them currently.  This is the
    # routine to modify to handle them though!
    if( $self->accept_text ) {
      my $multiplier	= $args{"text:c"} || 1;				# Number of characters
      $self->append_cell_data( " " x $multiplier );
    }
  }
  elsif( $type eq "text:p" ) {
    # Yikes, I initially wrote this without text:p in the start handler, instead
    # relying on char_handler.  I SHOULD change the restrictions layer to handle
    # accept_text_p... maybe when I have the energy
  }
}

# The XML::Parser character handler.  It builds up cells piece by piece

sub char_handler {
  my $self		= shift;

  if( $self->accept_text ) {
    my $Expat		= shift;
    my $text		= shift;
    $self->append_cell_data( $text );	# Build up cell data from multiple bits of text
  }
}

##################################################################
# These routines restrict what gets processed.  They each
# take a boolean value, turning the switch on or off.  There
# are 3 levels of restriction: rows, cells, and text.

sub accept_cells {
  my $self		= shift;
  my $value		= shift;
  if( ! defined $value ) {
    return $self->{accept_cells};
  }
  else {
    $self->{accept_cells}	= $value;
  }
}
sub accept_rows {
  my $self		= shift;
  my $value		= shift;
  if( ! defined $value ) {
    return $self->{accept_rows};
  }
  else {
    $self->{accept_rows}	= $value;
  }
}
sub accept_text {
  my $self		= shift;
  my $value		= shift;
  if( ! defined $value ) {
    return $self->{accept_text};
  }
  else {
    $self->{accept_text}	= $value;
  }
}

##################################################################

sub set_current_worksheet_name {
  my $self		= shift;
  $self->{current_worksheet_name}	= shift;
}

# PUBLIC, returns the name of the current worksheet.

sub get_current_worksheet_name {
  my $self		= shift;
  return $self->{current_worksheet_name};
}


# Reset the list of cells to the empty list

sub reset_cell_list {
  my $self		= shift;
  $self->{cells}	= [];
}

# PUBLIC Set some options via a hash

sub set_options {
  my $self			= shift;
  my %options			= @_;

  # Check to ensure the options are valid
  for( keys %options ) {
    if( ! $valid_options{$_} ) {
      die "Invalid option: '$_' ($options{$_}) passed as an option to ".ref $self."->set_options()";
    }
  }

  $self->{options}		= { %{$self->{options}}, %options };
}

# PUBLIC Get an option

sub get_option {
  my $self			= shift;
  my $opt_name			= shift;
  return $self->{options}{$opt_name};
}

sub append_cell_data {
  my $self			= shift;
  $self->{current_cell_data}	.= shift;
}

sub clear_cell {
  my $self			= shift;
  $self->{current_cell_data}	= "";
}

# Specify that a cell is to be repeated N times.  N is usually 1.

sub repeat_following_cell {
  my $self		= shift;
  $self->{cell_repeat}	= shift;
}

# See repeat_following_cell()

sub repeat_following_row {
  my $self		= shift;
  $self->{row_repeat}	= shift;
}

# The data_handler is how we use this module.

sub set_data_handler {
  my $self		= shift;
  my $data_handler	= shift || die "No row handler provided";

  $self->{data_handler}	= $data_handler;
}

sub get_data_handler {
  my $self		= shift;
  return $self->{data_handler};
}

# The end of the row has been reached, we call the data_handler:

sub end_row {
  my $self		= shift;
  my $cells		= $self->{cells};

  # OpenOffice actually specifies ALL the cells in the spreadsheet, some 32000 of
  # them, but using a repeat.  This bit of code detects the repeat, and can either
  # ignore it, since there likely won't be any data after a long repeat value, or
  # print them all out, if the "no_trim" option has been supplied.
  if( $self->{row_repeat} < 500 or $self->get_option( "no_trim" ) ) {
    for( 1 .. $self->{row_repeat} ) {
      $self->get_data_handler->row( $self, $cells );	# Assume the row handler is an object
    }
  }
  $self->repeat_following_row( 1 );	# Default 1
  $self->reset_cell_list;		# Clear out cells
}

# Ends the current cell.  It will be added to the cell list.

sub end_cell {
  my $self		= shift;
  chomp $self->{current_cell_data};	# remove the last newline
  for( 1 .. $self->{cell_repeat} ) {
    push @{$self->{cells}}, $self->{current_cell_data};
  }
  $self->repeat_following_cell( 1 );	# Default to 1
  $self->clear_cell;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

OpenOffice::Parse::SXC - Perl extension for parsing OpenOffice SXC files

=head1 SYNOPSIS

  use OpenOffice::Parse::SXC qw( parse_sxc );

  # Non-OO way:

  my @rows	= parse_sxc( "file.sxc" );
  for( @rows ) {
    print join(",", $_ ),"\n";
  }

  # OO way:

  package MyDataHandler;	# Set up a handler object
  sub new {
    my $type		= shift;
    my $self		= {};
    bless $self, $type;
    return $self;
  }
  sub row {
    my $self		= shift;
    my $SXC		= shift;
    my $row_data	= shift;
    print $self->{worksheet},": ",join(",", $_),"\n";	# Simple csv values printed...
  }
  sub worksheet {
    my $self		= shift;
    my $SXC		= shift;
    my $worksheet	= shift;
    $self->{worksheet}	= $worksheet;
  }
  sub workbook {
    my $self		= shift;
    my $SXC		= shift;
    my $workbook	= shift || "unknown_workbook";
  }
  1;

  package Main;

  my $SXC	= OpenOffice::Parse::SXC->new( OPTIONS );
  $SXC->set_data_handler( MyDataHandler->new );
  $SXC->parse_file( "file.sxc" );


=head1 DESCRIPTION

OpenOffice::Parse::SXC parses an SXC file (OpenOffice spreadsheet)
and passes data back through
a callback object that you register with the SXC object.

The major benefit of being able to read directly from an OpenOffice
spreadsheet is that it allows SXC files to be directly used as a development
tool.

The data returned contains no formatting or formula information, only what
text is displayed in the spreadsheet.

This module requires XML::Parser and the compression utility unzip to be
installed.

=head1 DATA CONVERSIONS

The data that this module will provide you with is exactly the same as
what you would B<see> in the OpenOffice application.  This could be different
than what you entered.  For example, this module would provide the results
of a function, not the function itself.  If you enter 19.95 into a cell, and
format that cell as a currency type, you would see $19.95 (for example), and
that is what you would get using this module to parse the spreadsheet.

=head1 EXPORT

None by default.

=head1 EXPORT_OK

=item parse_sxc SXC_FILENAME:

Parses an SXC file returning a list of lists containing the cell data.

=item csv_quote STRING:

Quotes a string in "CSV format".  The transformation converts each double-quote
to two double-quotes,
then double-quoting the entire string.  B<All newlines are removed!>

=item dump_sxc_file SXC_FILENAME:

Prints out a Dumper'ed version of the entire SXC XML tree.  Used for
debugging.


=head1 PUBLIC METHODS

=item new OPTIONS

Create a new SXC object.

=item parse FILEHANDLE

Parse file FILENAME.  This method calls parse_file().

=item parse_file SXC_FILENAME

Parse the data in filehandle SXC_FILEHANDLE.

=item get_current_worksheet_name

Returns the name of the current worksheet.  This is only useful
to the DATA HANDLER object (ie: during processing)

=item get_option OPTION_NAME

Gets an option.

=item set_options OPTION_NAME => VALUE, ...

Set one or more options

=item set_data_handler

Sets the DATA HANDLER.  See the synopsis, and the DATA HANDLER section
for details.

=item get_data_handler

Gets the DATA HANDLER.

=head1 OPTIONS

The following options can be used (in new() or set_options()):

=item worksheets	=> [ LIST_OF_WORKSHEETS_TO_PROCESS ]

An SXC 'workbook' consists of multiple 'worksheets',
(internally refered to as tables)  You can specify
which worksheets you would like to process, or ALL
of them if this option is not used.

=item no_trim	=> 1

If NOT specified, the trailing empty cells in each
row will be spliced out.


=head1 DATA HANDLER

The DATA HANDLER is what the SXC object calls upon do do work while
it parses an SXC file.  It expects the DATA HANDLER object to implement
the following methods:

=item row:

Handle row data

=item worksheet:

Called each time a new worksheet is encountered.
Note: there is no callback for when a worksheet ends.


=item workbook:

Called each time a new workbook is encountered.
(This helps when the same SXC object is used to
process multiple files.  As with worksheet(), there
is no callback for the end of a workbook.

Each method gets the SXC object as the first argument, and the data as the
second argument: worksheet gets the name of the worksheet, workbook gets the
filename of the SXC file, and row receives a list reference to all the cells
in that row.

The interesting callback is the row() function, and often it's the only
function of any interest.  If you want to avoid creating a class and just
want to implement a row() callback, you can do something like this:

  sub Whatever::row {
    my($self, $SXC, $row_data) = @_;
    print join(",", map { csv_quote( $_ ) } @$row_data ),"\n";
  }
  sub Whatever::worksheet {}
  sub Whatever::workbook {}
  $SXC->set_data_handler( bless {}, "Whatever" );
  $SXC->parse_file( ... );

=head1 AUTHOR

Desmond Lee <deslee@shaw.ca>

=head1 SEE ALSO

L<sxc2csv>.

=cut
