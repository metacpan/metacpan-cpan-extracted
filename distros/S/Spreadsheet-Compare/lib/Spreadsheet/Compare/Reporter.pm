package Spreadsheet::Compare::Reporter;

use Mojo::Base -base, -signatures;
use Spreadsheet::Compare::Common;

#<<<
use Spreadsheet::Compare::Config {
    rootdir => '.',
    ( map { $_ => undef } qw(
        report_filename
        report_line_numbers
        report_line_source
        report_max_columns
        report_ignored_columns
    )),
    ( map { $_ => sub { croak 'attribute "$_" not implemented by subclass'; } } qw(
        fmt_head
        fmt_headerr
        fmt_default
        fmt_left_odd
        fmt_right_odd
        fmt_diff_odd
        fmt_left_even
        fmt_right_even
        fmt_diff_even
        fmt_left_high
        fmt_right_high
        fmt_diff_high
        fmt_left_low
        fmt_right_low
        fmt_diff_low
    )),
}, make_attributes => 1;
#>>>

#<<<
# attributes set by after_reader_setup
has [qw(ign record_header header)] => undef,                                                                ro => 1;
has stat_head   => sub { [qw/title left right same diff miss add dup limit link/] },                        ro => 1;
has max_hdr     => sub { $_[0]->report_max_columns ? [qw/ABS_FIELD ABS_VALUE REL_FIELD REL_VALUE/] : []; }, ro => 1;
has sln_hdr     => sub { $_[0]->report_line_numbers ? [qw/__SLN__/] : []; },                                ro => 1;
has src_hdr     => sub { $_[0]->report_line_source ? [qw/__SRC__/] : [] },                                  ro => 1;
has head_offset => sub { $_[0]->src_hdr->@* + $_[0]->sln_hdr->@* + $_[0]->max_hdr->@* },                    ro => 1;
#>>>


sub output_record ( $self, $robj ) {
    my @src = $self->report_line_source  ? $robj->side_name : ();
    my @sln = $self->report_line_numbers ? $robj->sln       : ();
    my @max = $robj->diff_info->@{ $self->max_hdr->@* };
    my $rec = $self->strip_ignore( $robj->rec );
    return [ @src, @sln, @max, @$rec ];
}

sub strip_ignore ( $self, $aref ) {
    my $ign = $self->ign;
    return [ map { $ign->{$_} ? () : $aref->[$_] } 0 .. $#$aref ];
}

sub _after_reader_setup ( $self, $look ) {    ## no critic (ProhibitUnusedPrivateSubroutines)
    $self->{__ro__ign}           = $self->report_ignored_columns ? {} : $look->{ign};
    $self->{__ro__record_header} = $self->strip_ignore( $look->{hdr} );
    $self->{__ro__header} = [ $self->src_hdr->@*, $self->sln_hdr->@*, $self->max_hdr->@*, $self->record_header->@* ];
    return $self;
}

sub report_fullname ( $self, $fn = undef ) {
    $fn //= $self->report_filename;
    my $pfn = path($fn);
    return $pfn if $pfn->is_absolute;
    return path( $self->rootdir, $fn );
}

# Methods that must/should be overridden by subclasses

sub setup ($self) { }

sub add_stream ( $self, $name ) {
    croak 'method "add_stream" not implemented by subclass';
}

sub write_row ( $self, $name, $robj ) {
    croak 'method "write_row" not implemented by subclass';
}

sub write_fmt_row ( $self, $name, $robj ) {
    croak 'method "write_fmt_row" not implemented by subclass';
}

sub write_header ( $self, $name ) {
    croak 'method "write_header" not implemented by subclass';
}

sub mark_header ( $self, $name, $mask ) {
    croak 'method "mark_header" not implemented by subclass';
}

sub write_summary ( $self, $stats, $filename ) {
    croak 'method "write_summary" not implemented by subclass';
}

sub save_and_close ($self) {
    croak 'method "save_and_close" not implemented by subclass';
}


1;

=head1 NAME

Spreadsheet::Compare::Reporter - Abstract Base Class for Reporters

=head1 DESCRIPTION

This module defines the methods and attributes that are provided for or need to be overrridden
by a Spreadsheet::Compare::Reporter subclass.

When subclassing consider using L<Spreadsheet::Compare::Common> for convenience.

=head1 ATTRIBUTES

All read write attributes can be set as options from the config file passed to L<Spreadsheet::Compare>
or L<spreadcomp>.

The defaults for the C<fmt_*> attributes are specific to the Reporter subclass and are documented there.

=head2 fmt_head

The format for the header line.

=head2 fmt_headerr

The format for marking headers of columns that contain differences.

=head2 fmt_default

The default format for a single cell.

=head2 fmt_left_odd

The default format for a cell on the left side of the comparison with an odd line index.

=head2 fmt_right_odd

The default format for a cell on the right side of the comparison with an odd line index.

=head2 fmt_diff_odd

The default format for a cell of the differences line with an odd line index.
(only with L</report_diff_row>)

=head2 fmt_left_even

The default format for a cell on the left side of the comparison with an even line index.

=head2 fmt_right_even

The default format for a cell on the right side of the comparison with an even line index.

=head2 fmt_diff_even

The default format for a cell of the differences line with an even line index.
(only with L</report_diff_row>)

=head2 fmt_left_high

Format set on the left side when a difference was detected and at least one limit was exceeded.

=head2 fmt_right_high

Format set on the right side when a difference was detected and at least one limit was exceeded.

=head2 fmt_diff_high

Format set in the differences line when a difference was detected and at least one limit was exceeded.
(only with L</report_diff_row>)

=head2 fmt_left_low

Format set on the left side when a difference was detected and all deviations are below their limits.

=head2 fmt_right_low

Format set on the right side when a difference was detected and all deviations are below their limits.

=head2 fmt_diff_low

Format sset in the differences line when a difference was detected and all deviations are below their limits.
(only with L</report_diff_row>)

=head2 report_diff_row

  possible values: 0|1
  default: 0

Add a row with the absolute (or relative if L<<Spreadsheet::Compare::Single/diff_relative>> is used ) differences
after each pair of data lines in the diff output.

=head2 report_filename

  possible values: <string>
  default: undef

The output filename for the generated report. This will be prepended with the directory
set with the L<Spreadsheet::Compare/rootdir> option unless it is an absolute filename.

=head2 report_ignored_columns

  possible values: 0|1
  default: 0

Per default ignored columns will not be written to reports. Setting this option will include
them. They will be marked as 'IGNORED' when L</report_diff_row> is set.

=head2 report_line_numbers

  possible values: 0|1
  default: 0

Add a column named '__SLN__' to the report output containing the record's line number
in the source file should the Reader module provide it.

=head2 report_line_source

  possible values: 0|1
  default: 0

Add a column named __SRC__ specifying the source name in the diff output. The
names set by the options "left" and "right" will be used. For diff lines it will be 'diff'.

=head2 report_max_columns

  possible values: 0|1
  default: 1

Add the columns ABS_FIELD, ABS_VALUE, REL_FIELD and REL_VALUE to the diff output.
They indicate the field names and maximal differences for absolute and
relative deviations for a line comparison.

=head2 rootdir

Set by L<Spreadsheet::Compare> during reporter initialisation.
Same as L<Spreadsheet::Compare/rootdir>.

=head2 stat_head

B<readonly>) A reference to an array with the column headers for statistics information

=head1 METHODS

The methods marked as B<event handler> have to implemented by subclasses to handle events
emitted by L<Spreadsheet::Compare::Single> (see L<Spreadsheet::Compare::Single/EVENTS>
for descriptions of the event parameters).

=head2 add_stream($name)

(B<event handler>)

=head2 mark_header($stream, $mask)

(B<event handler>)

=head2 output_record ($record_obj)

Return a reference to an array with all valid output values for a record according to the
current reporting attributes (e.g. L</report_ignored_colums>, L</report_max_columns>, ...)

=head2 report_fullname([$fn])

Return the full report filename by combining L</rootdir> and $fn (defaults to L</report_filename>).
Will just return the filename if it is absolute.

=head2 save_and_close()

Will be called by L<Spreadsheet::Compare> after a comparison has finished and the report_finished
event was emitted. The Reporter can safely close the report.

=head2 setup

Will be called by L<Spreadsheet::Compare> before starting a comparison. Does not need
to be implemented by subclasses.

=head2 strip_ignore ($record_aref)

Remove ignored columns from the referenced array. The array has to be the same
length as a source record.

=head2 write_header($stream)

(B<event handler>)

=head2 write_row($stream, $record_obj)

(B<event handler>)

=head2 write_fmt_row($stream, $record_obj)

(B<event handler>)

=head2 write_summary($stats, $filename)

Will be called by L<Spreadsheet::Compare> after completion of all comparisons when
L<Spreadsheet::Compare/summary> is set.

=cut
