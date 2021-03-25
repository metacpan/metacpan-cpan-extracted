package Spreadsheet::Compare::Reader::FIX;

use Mojo::Base 'Spreadsheet::Compare::Reader', -signatures;
use Spreadsheet::Compare::Common;
use Spreadsheet::Compare::Record;

#<<<
use Spreadsheet::Compare::Config {
    files              => sub {[]},
    has_lines          => 1,
    record_format      => undef,
    rootdir            => '.',
    skip_before_head   => 0,
    skip_after_head    => 0,
    strip_ws           => 0,
}, make_attributes => 1;

has filename    => undef, ro => 1;
has filehandle  => undef, ro => 1;
has _chunk_data => sub { {} }, ro => 1;
#>>>

my( $trace, $debug );


sub init ($self, @args) {
    $self->{__ro__can_chunk} = 1;
    return $self->SUPER::init(@args);
}


sub setup ($self) {

    ( $trace, $debug ) = get_log_settings();

    my $proot = path( $self->rootdir // '.' );
    my $fn    = path($self->files->[ $self->index ]);
    my $pfull = $self->{__ro__filename} = $fn->is_absolute ? $fn : $proot->child($fn);

    INFO "opening input file >>$pfull<<";
    $self->{__ro__filehandle} = $pfull->openr_raw;

    $self->{_read_size} = length( pack( $self->record_format, '' ) );

    $self->_read_record( undef, 'skip' ) for 1 .. $self->skip_before_head // 0;

    $self->_set_header;

    $self->_read_record( undef, 'skip' ) for 1 .. $self->skip_after_head // 0;

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
    my $fn     = $self->filename;
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
    }
    else {
        $debug and DEBUG "fetching max $size records";

        my $i       = 0;
        my $fh      = $self->filehandle;
        my $skipper = $self->skipper;
        while ( ++$i <= $size ) {
            my $rec = $self->_read_record();
            unless ($rec) {
                $debug and DEBUG "EOF for '$fn'";
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

    my $rec = $self->_read_record;

    $debug and DEBUG "setting header from record:", sub { Dump($rec) };
    if ( $self->has_header ) {
        $self->{__ro__header} = $rec;
    }
    else {
        $self->{__ro__header} = [ 0 .. $#$rec ];
        seek( $fh, $start_pos, 0 );
    }
    return $self;
}


sub _read_record ( $self, $rec_info = undef, $skip = undef ) {

    my $fh = $self->filehandle;
    my $fn = $self->filename;

    my $line;
    my $pos;
    my $len;
    my $sln;
    my $rcount;
    if ($rec_info) {
        seek( $fh, $rec_info->{pos}, 0 );
        $rcount = read( $fh, $line, $rec_info->{len} );
        LOGDIE "Error reading data from '$fn', $!" unless defined $rcount;
        $sln    = $rec_info->{sln};
    }
    else {
        $pos = tell($fh);
        if ( $self->has_lines ) {
            $line   = <$fh>;
            $rcount = length($line) if defined $line;
            LOGDIE "Error reading data from '$fn', $!"
                if not eof($fh)
                and not defined $rcount;
        }
        else {
            $rcount = read( $fh, $line, $self->{_read_size} );
            LOGDIE "Error reading data from '$fn', $!" unless defined $rcount;
        }
        $len = length($line);
        $sln = ++$self->{_sln};
    }

    $self->{read_bytes} += $rcount // 0;
    return if $skip;

    $line //= '';
    chomp($line);
    return unless $line =~ /\w/;

    $trace and TRACE "got line >>$line<<";

    my @rec = unpack( $self->record_format, $line );

    if ( $self->strip_ws ) {
        do { s/^\s+//; s/\s+$// }
            for @rec;
    }

    # when we are reading the header return the arrayref
    return \@rec unless $self->header;

    # else construct record
    $trace and TRACE "record array: ", sub { Dump( \@rec ) };
    my $robj = Spreadsheet::Compare::Record->new(
        rec    => \@rec,
        reader => $self,
    );
    $trace and TRACE "record id: ", $robj->id;

    #<<<
    $robj->{__INFO__} = {
        pos => $pos,
        len => $len,
        sln => $sln,
    } if $self->chunker and not $rec_info;
    #>>>

    return $robj;
}


sub DESTROY ( $self, @ ) {
    close( $self->filehandle ) if $self->filehandle;
    return;
}


1;


=head1 NAME

Spreadsheet::Compare::Reader::FIX - Fixed-Width File Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

This module provides a fetch interface for reading records from files with fixed width columns.

=head1 ATTRIBUTES

L<Spreadsheet::Compare::Reader::FIX> implements the following attributes.

=head2 filehandle

(B<readonly>) The filehandle for L</filename>.

=head2 filename

(B<readonly>) The filename of the used input file for this reader. Use L</files> for
filename specification.

=head2 files

  possible values: <list of exactly 2 files>
  default: undef

Example:

  files:
    - ./left_dir/data.fix
    - ./right_dir/data.fix

Relative filenames will be interpreted releative to L</rootdir>

=head2 has_lines

  possible values: <bool>
  default: 0

Indicate that the input file has newline characters at the end of each record.

=head2 record_format

  possible values: <perl unpack string>
  default: ''

Example:

  record_format: 'A3A5A25A31A20A20A3A1A8A8'

A perl unpack string to split the record into a list of values.

=head2 rootdir

Set by L<Spreadsheet::Compare> during reader initialisation.
Same as L<Spreadsheet::Compare/rootdir>.

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

L<Spreadsheet::Compare::Reader::FIX> inherits or overwrites all methods from L<Spreadsheet::Compare::Reader>.

=cut
