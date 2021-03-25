package Spreadsheet::Compare::Reader::CSV;

use Mojo::Base 'Spreadsheet::Compare::Reader', -signatures;
use Spreadsheet::Compare::Common;
use Text::CSV;

#<<<
use Spreadsheet::Compare::Config {
    csv_options        => sub { { allow_whitespace => 1 } },
    files              => sub {[]},
    fix_empty_header   => 1,
    make_header_unique => 0,
    rootdir            => '.',
    sep_auto           => undef,
    skip_before_head   => 0,
    skip_after_head    => 0,
}, make_attributes => 1;

has filename    => undef, ro => 1;
has filehandle  => undef, ro => 1;
has _chunk_data => sub { {} }, ro => 1;
has csv         => sub {
    my $csv = Text::CSV->new( $_[0]->csv_options );
    LOGDIE join( ',', Text::CSV->error_diag ) unless $csv;
    return $csv;
}, ro => 1;
#>>>

my( $trace, $debug );

sub init ( $self, @args ) {
    $self->{__ro__can_chunk} = 1;
    return $self->SUPER::init(@args);
}

sub setup ($self) {

    ( $trace, $debug ) = get_log_settings();

    my $proot = path( $self->rootdir // '.' );
    my $fn    = path($self->files->[ $self->index ]);
    my $pfull = $self->{__ro__filename} = $fn->is_absolute ? $fn : $proot->child($fn);

    INFO "opening input file >>$pfull<<";
    my $fh = $self->{__ro__filehandle} = $pfull->openr_raw;

    <$fh> for 1 .. $self->skip_before_head;

    $self->_set_header;

    <$fh> for 1 .. $self->skip_after_head;

    $self->_chunk_records() if $self->chunker;

    $self->{_sln} = 0;

    return $self;
}


sub _chunk_records ($self) {
    $debug and DEBUG "chunking side $self->{index}";
    my $skipper = $self->skipper;
    while ( my $rec = $self->_read_record ) {
        next if $skipper and $skipper->($rec);
        my $cname = $self->chunker->($rec);
        my $cdata = $self->_chunk_data->{$cname} //= [];
        push @$cdata, delete( $rec->{__INFO__} );
    }

    $debug and DEBUG "found chunks:", sub { Dump( [ sort keys $self->_chunk_data->%* ] ) };

    my $fh = $self->filehandle;
    seek( $fh, 0, 0 );
    return $self;
}


sub fetch ( $self, $size ) {

    my $result = $self->result;
    my $count  = 0;

    if ( $self->chunker ) {
        my $cdata = $self->_chunk_data;
        my $cname = ( sort keys %$cdata )[0];
        my $chunk = delete $cdata->{$cname};
        $self->{__ro__exhausted} = 1 unless keys %$cdata;
        $debug and DEBUG "Fetching data for chunk $cname";
        for my $rec_info (@$chunk) {
            if ( my $rec = $self->_read_record($rec_info) ) {
                push @$result, $rec;
                $count++;
            }
        }
        $debug and DEBUG "fetched $count records from chunk $cname";
    }
    else {
        $debug and DEBUG "fetching max $size records";

        my $i       = 0;
        my $fh      = $self->filehandle;
        my $skipper = $self->skipper;
        while ( ++$i <= $size ) {
            my $rec = $self->_read_record();
            unless ($rec) {
                $debug and DEBUG "EOF for $self->{__ro__filename}";
                $self->{__ro__exhausted} = 1;
                last;
            }
            next if $skipper and $skipper->($rec);
            push @$result, $rec;
            $count++;
        }

        if ( $size == ~0 ) {
            @$result = sort { $a->id cmp $b->id } @$result;
        }
    }

    $debug and DEBUG "fetched $count records";

    return $count;
}


sub _set_header ($self) {
    my $fh        = $self->filehandle;
    my $start_pos = tell($fh);

    my $tcx = $self->csv_options;
    my $csv = $self->csv;
    my $sep = $tcx->{sep} // $tcx->{sep_char};
    my $hd  = $self->has_header;

    my $sep_set = $sep ? [$sep] : $self->sep_auto;
    my @rec;

    if ( $sep and defined $hd and not $hd ) {
        @rec = $csv->getline($fh)->@*;
    }
    else {    # no separator defined and/or autodetect
        try {
            @rec = $csv->header(
                $fh, {
                    $sep_set ? ( sep_set => $sep_set ) : (),
                    munge_column_names => sub ($hcol) {
                        state $count = 0;
                        state $seen = {};
                        $hcol = 'unnamed_' . ++$count
                            if $hcol !~ /\S/ and $self->fix_empty_header;
                        if ( $self->make_header_unique ) {
                            $hcol .= "_$seen->{$hcol}" if $seen->{$hcol}++;
                        }
                        return $hcol;
                    },
                }
            );
            # very simple header detection: if it contains a naked numerical value
            #   => assume it is not a header
            $hd //= none { /^\d+[\.\,]?\d+$/ } @rec;
            INFO "Detected Separator: >>", $csv->sep, '<<' unless $sep;
        }
        catch {
            # exeption will be thrown if non unique fields are found (1013)
            #   => this is only fatal if we should have a header
            # or we found more than one seperator (1011)
            #   => this is always fatal
            LOGDIE "Error reading first line from csv, $_" if $hd or 0 + $csv->error_diag == 1011;

            # else read again with getline(), separator is detected
            INFO "Detected Separator: >>", $csv->sep, '<<';
            seek( $fh, $start_pos, 0 );
            @rec = $csv->getline($fh)->@*;
            $hd  = 0;                        # defined but 0 ==> we don't have a header
        };
    }


    $debug and DEBUG "setting header from record:", sub { Dump( \@rec ) };
    if ($hd) {
        $self->has_header(1);
        INFO "Setting header info from header line";
        $self->{__ro__header} = \@rec;
    }
    else {
        $self->has_header(0);
        INFO "Setting header info from column numbers";
        my @cols = 0 .. $#rec;
        $self->{__ro__header} = \@cols;
        $csv->column_names(@cols);
        seek( $fh, $start_pos, 0 );
    }

    return $self;
}


sub _read_record ( $self, $rec_info = undef ) {

    my $fh = $self->filehandle;

    my $rec;
    my $pos;
    my $sln;
    my $rcount;
    if ( defined $rec_info ) {
        seek( $fh, $rec_info->{pos}, 0 );
        try {
            $rec = $self->csv->getline($fh);
        }
        catch {
            LOGDIE "Error reading csv data, $_";
        };
        $sln    = $rec_info->{sln};
        $rcount = tell($fh) - $rec_info->{pos};
    }
    else {
        $pos = tell($fh);
        try {
            $rec = $self->csv->getline($fh);
        }
        catch {
            LOGDIE "Error reading csv data, $_";
        };
        $sln    = ++$self->{_sln};
        $rcount = tell($fh) - $pos;
    }

    return unless $rec;

    $self->{read_bytes} += $rcount // 0;

    $trace and TRACE "record array: ", sub { Dump($rec) };

    my $robj = Spreadsheet::Compare::Record->new(
        rec    => $rec,
        reader => $self,
        sln    => $sln,
    );

    $trace and TRACE "record id: ", $robj->id;

    #<<<
    $robj->{__INFO__} = {
        pos => $pos,
        sln => $sln,
    } if $self->chunker and not $rec_info;
    #>>>

    return $robj;
}


sub DESTROY ( $self, @ ) {
    close( $self->{fh} ) if $self->{fh};
    return;
}


1;

=head1 NAME

Spreadsheet::Compare::Reader::CSV - CSV File Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

This module provides a fetch interface for reading records from CSV files. It uses
L<Text::CSV|https://metacpan.org/pod/Text::CSV> to do the heavy lifting. This allows
the interface to have maximal flexibility.

=head1 ATTRIBUTES

If not stated otherwise, read write attributes can be set as options from the config file
passed to L<Spreadsheet::Compare> or L<spreadcomp>.

=head2 csv

(B<readonly>) The L<Text::CSV> instance.

=head2 csv_options

  possible values: <hash>
  default: { allow_whitespace : 1 }

Example:

  csv_options:
    allow_loose_quotes: 1
    allow_whitespace: 1
    sep: ';'

A reference to a hash with options for calling the L<Text::CSV> constructor.

=head2 filehandle

(B<readonly>) The filehandle for L</filename>.

=head2 filename

(B<readonly>) The filename of the used CSV file for this reader. Use L</files> for
filename specification.

=head2 files

  possible values: <list of exactly 2 filenames>
  default: []

Example:

  files:
    - ./left_dir/data.csv
    - ./right_dir/data.csv

Relative filenames will be interpreted releative to L</rootdir>

=head2 fix_empty_header

  possible values: <bool>
  default: 1

If a header entry does not contain at least one non space character replace it with
'unnamed_<n>' with a simple counter <n>;

=head2 make_header_unique

  possible values: <bool>
  default: 0

If there should be duplicate header names, append an counter '_<n>' to make the header name unique.

=head2 rootdir

Set by L<Spreadsheet::Compare> during reader initialisation.
Same as L<Spreadsheet::Compare/rootdir>.

=head2 sep_auto

  possible values: <list of possible separators>
  default: undef

Example:

  sep_auto: [ ";", ",", "|", "\t" ]

Set the list of possible separators in header detection. If left undefined the
value set by B<sep> or B<sep_char> in L</csv_options> will be used.
(see L<Text::CSV/sep_set>).

=head2 skip_after_head

  possible values: <integer>
  default: 0

Number of lines to skip after reading the header line.

=head2 skip_before_head

  possible values: <integer>
  default: 0

Number of lines to skip at the beginning of the files before reading the
header line.

=head1 METHODS

L<Spreadsheet::Compare::Reader::CSV> inherits or overwrites all methods from L<Spreadsheet::Compare::Reader>.

=cut
