package Spreadsheet::Compare::Reader::WB;

use Mojo::Base 'Spreadsheet::Compare::Reader', -signatures;
use Spreadsheet::Compare::Common;
use Spreadsheet::Read;

#<<<
use Spreadsheet::Compare::Config {
    data_row       => 1,
    data_col       => 0,
    sheets         => sub {[]},
    header_row     => 1,
    header_col     => 0,
    rootdir        => '.',
    sr_options     => sub { {} },
}, make_attributes => 1;

has filename  => undef, ro => 1;
has last_row  => undef, ro => 1;
has sheet     => undef, ro => 1;
has sheetname => undef, ro => 1;
has wb        => sub ($self) {
    my $fn = $self->filename;
    INFO "opening workbook >>$fn<<";
    my $wb = Spreadsheet::Read->new( $fn->stringify, $self->sr_options->%* );
    LOGDIE "could not create Spreadsheet::Read instance, $@" unless $wb;
    return $wb;
}, ro => 1;
#>>>

my( $trace, $debug );


sub setup ($self) {
    ( $trace, $debug ) = get_log_settings();

    my $proot      = path( $self->rootdir // '.' );
    my $sheet_full = $self->sheets->[ $self->index ];
    my( $fn, $sn ) = split( /::/, $sheet_full, 2 );
    $fn = path($fn);

    LOGDIE "no worksheet name given" unless $self->{__ro__sheetname} = $sn;
    my $pfull = $self->{__ro__filename} = $fn->is_absolute ? $fn : $proot->child($fn);

    INFO "getting data for sheet >>$sn<<";
    $self->{__ro__sheet} = $self->wb->sheet($sn);

    LOGDIE "worksheet >>$sn<< not found in >>$pfull<<" unless $self->sheet;

    $self->_set_header;

    return $self;
}


sub _set_header ($self) {

    if ( $self->has_header ) {
        my @row = $self->sheet->cellrow( $self->header_row );
        $self->{__ro__header} = [ @row[ $self->header_col .. $#row ] ];
    }
    else {
        my @row = $self->sheet->cellrow( $self->data_row );
        $self->{__ro__header} = [ $self->data_col .. $#row ];
    }

    $debug and DEBUG "set header to ", sub { Dump( $self->header ) };

    return $self;
}


sub fetch ( $self, $size ) {

    $debug and DEBUG "fetching $size records";

    my $header = $self->header;
    my $d0     = $self->data_col;
    my $d1     = @$header - 1;

    my $result  = $self->result;
    my $skipper = $self->skipper;
    my $ridx    = $self->last_row // $self->data_row - 1;
    my $rmax    = $ridx + $size;
    while ( ++$ridx <= $rmax ) {
        my @row = ( $self->sheet->cellrow($ridx) )[ $d0 .. $d1 ];
        unless (@row) {
            $self->{__ro__exhausted} = 1;
            last;
        }
        my $robj = Spreadsheet::Compare::Record->new(
            rec    => \@row,
            reader => $self,
        );
        next if $skipper and $skipper->($robj);
        $debug and DEBUG "got record", Dump( $robj->rec );
        push @$result, $robj;
    }

    $self->{__ro__last_row} = $ridx - 1;
    my $count = @$result;

    $debug and DEBUG "fetched $count records";

    return $count;
}


sub DESTROY ($self) {
    $self->sth->finish     if $self->{sth};
    $self->dbh->disconnect if $self->{dbh};
    return;
}


1;


=head1 NAME

Spreadsheet::Compare::Reader::WB - Workbook Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

This module provides a fetch interface for various spreadsheet workbook formats
(Excel/OpenOffice/LibreOffice). It uses L<Spreadsheet::Read> for reading the
spreadsheet data. L<Spreadsheet::Read> will not be installed as a hard dependency
for L<Spreadsheet::Compare>, so it has to be manually installed.

=head1 ATTRIBUTES

If not stated otherwise, read write attributes can be set as options from the config file
passed to L<Spreadsheet::Compare> or L<spreadcomp>.

=head2 data_row

  possible values: <integer>
  default: 1

The starting row number of record data

=head2 data_col

  possible values: <integer>
  default: 0

The starting column number of record data

=head2 header_row

  possible values: <integer>
  default: 0

The row containing the header line (if L<Spreadsheet::Compare::Reader/has_header>) is set.

=head2 header_col

  possible values: <integer>
  default: 0

The starting column number of header data (if L<Spreadsheet::Compare::Reader/has_header>) is set.

=head2 rootdir

Set by L<Spreadsheet::Compare> during reader initialisation.
Same as L<Spreadsheet::Compare/rootdir>.

=head2 sheet

(B<readonly>) The sheet object.

=head2 sheetname

(B<readonly>) The sheetname for this reader. Use L</sheets> for
filename/sheetname specification.

=head2 sheets

  possible values: <list of exactly 2 filename::sheetname specifications>
  default: []

Example:

  sheets:
    - ./left_dir/data.ods::MyDataSheet
    - ./right_dir/data.ods::MyDataSheet

or

  sheets:
    - ./data.xlsx::Sheet_001
    - ./data.xlsx::Sheet_002

Relative filenames will be interpreted releative to L</rootdir>

=head2 sr_options

  possible values: <hash>
  default: {}

Example:

  sr_options:
    dtfmt: 'yyyy-mm-dd'

A reference to a hash with options for calling the L<Spreadsheet::Read> constructor.

=head2 wb

(B<readonly>) The L<Spreadsheet::Read> instance.


=head1 METHODS

L<Spreadsheet::Compare::Reader::WB> inherits or overwrites all methods from L<Spreadsheet::Compare::Reader>.

=cut
