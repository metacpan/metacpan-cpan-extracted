package Spreadsheet::Compare::Reporter::XLSX;

use Mojo::Base 'Spreadsheet::Compare::Reporter', -signatures;
use Spreadsheet::Compare::Common;

use Excel::Writer::XLSX;

my %format_defaults = (
    fmt_head       => 'bold 1 align left',
    fmt_headerr    => 'bold 1 align left bg_color yellow',
    fmt_default    => 'color black',
    fmt_left_odd   => 'color blue',
    fmt_right_odd  => 'color red',
    fmt_diff_odd   => 'color green',
    fmt_left_even  => 'color blue  bg_color silver',
    fmt_right_even => 'color red   bg_color silver',
    fmt_diff_even  => 'color green bg_color silver',
    fmt_left_high  => 'color blue  bg_color yellow',
    fmt_right_high => 'color red   bg_color yellow',
    fmt_diff_high  => 'color black bg_color yellow',
    fmt_left_low   => 'color blue  bg_color lime',
    fmt_right_low  => 'color red   bg_color lime',
    fmt_diff_low   => 'color black bg_color lime',
);

has $_, $format_defaults{$_} for keys %format_defaults;

has report_filename => sub {
    ( my $title = $_[0]->title ) =~ s/[^\w-]/_/g;
    return "$title.xlsx";
};


sub add_stream ( $self, $name ) {

    $self->_open_wkb() unless $self->{wbk};

    $self->{ws}{$name} = $self->{wbk}->add_worksheet($name);
    $self->{ws}{$name}->add_write_handler( qr[\d], \&_write_with_infinity );
    $self->{row}{$name} = 0;

    return $self;
}


sub write_header ( $self, $name ) {

    $self->{ws}{$name}->write_row( $self->{row}{$name}++, 0, $self->header, $self->fmt_head );
    $self->{ws}{$name}->freeze_panes( 1, 0 );

    return $self;
}


sub mark_header ( $self, $name, $mask ) {

    my $smask = $self->strip_ignore($mask);
    my $off   = $self->head_offset;
    my $rhead = $self->record_header;
    for my $col ( 0 .. $#$rhead ) {
        $self->{ws}{$name}->write( 0, $col + $off, $rhead->[$col], $self->fmt_headerr )
            if $smask->[$col];
    }

    return $self;
}


sub write_row ( $self, $name, $robj ) {
    my($fnorm) = $self->_get_fmt( $name, $robj->side );
    $self->{ws}{$name}->write_row( $self->{row}{$name}++, 0, $self->output_record($robj), $fnorm );
    return $self;
}


sub _get_fmt ( $self, $name, $side ) {

    $self->{$name}{odd} ^= 1
        if $name eq 'Additional' and $side eq 'right'
        or $side eq 'left';

    my $oe = $self->{$name}{odd} ? 'odd' : 'even';

    my $fnorm = $self->{format}{$side}{$oe}  || $self->fmt_default;
    my $fhigh = $self->{format}{$side}{high} || $self->fmt_default;
    my $flow  = $self->{format}{$side}{low}  || $self->fmt_default;

    return ( $fnorm, $fhigh, $flow );
}


sub write_fmt_row ( $self, $name, $robj ) {

    my $data = $self->output_record($robj);
    my $mask = $self->strip_ignore( $robj->limit_mask );
    my $off  = $self->head_offset;
    my $row  = $self->{row}{$name}++;

    my( $fnorm, $fhigh, $flow ) = $self->_get_fmt( $name, $robj->side );

    for my $col ( 0 .. $#$data ) {
        my $idx  = $col - $off;
        my $flag = $idx < 0 ? 0 : $mask->[$idx];
        $self->{ws}{$name}->write(
            $row, $col, $data->[$col], $flag
            ? ( $flag == 1 ? $fhigh : $flow )
            : $fnorm,
        );
    }

    return $self;
}


sub _open_wkb ($self) {

    my $rfn = $self->report_fullname->stringify;
    INFO "opening report file $rfn";

    $self->{wbk} = Excel::Writer::XLSX->new($rfn)
        or LOGDIE "could not create >>$rfn<<, $!";

    for my $fname ( keys %format_defaults ) {
        my( undef, $side, $fmt ) = split( /_/, $fname );
        my $fobj = $self->{wbk}->add_format( split( /\s+/, $self->$fname ) );
        if ($fmt) {
            $self->{format}{$side}{$fmt} = $fobj;
        }
        else {
            $self->{$fname} = $fobj;
        }
    }

    return $self;
}


sub save_and_close ($self) {

    if ( $self->header->@* ) {
        for my $name ( keys $self->{ws}->%* ) {
            $self->{ws}{$name}->autofilter( 0, 0, $self->{row}{$name} - 1, $self->header->$#* );
        }
    }

    if ( $self->{wbk} ) {
        $self->{wbk}->close();
        delete $self->{wbk};
    }

    return $self;
}


sub write_summary ( $self, $summary, $filename ) {

    $filename .= '.xlsx' unless $filename =~ /\.xlsx$/i;

    my $sfn = $self->report_fullname($filename)->stringify;

    INFO "opening summary file $sfn";
    my $wbk = Excel::Writer::XLSX->new($sfn)
        or ERROR "could not create >>$sfn<<, $!";

    my $fhead = $wbk->add_format(qw/bold 1 align left/);
    my $head  = $self->stat_head;

    for my $suite ( sort keys %$summary ) {
        my $ws  = $wbk->add_worksheet($suite);
        my $row = 0;
        $ws->write_row( $row++, 0, $head, $fhead );
        $ws->freeze_panes( 1, 0 );
        for my $test ( @{ $summary->{$suite} } ) {
            my $result = $test->{result};
            $result->{title} = $test->{title};
            my $data = [ @$result{@$head} ];
            $ws->write_row( $row, 0, $data );
            $ws->write_url( $row, $#$head, "external:$test->{report}", undef, $test->{title} ) if $test->{report};
            $row++;
        }
    }

    $wbk->close();

    return $self;
}

my $qr_num = qr/^
    (?:[+-]?)
    (?=[0-9]|\.[0-9])
    [0-9]*
    (\.[0-9]*)?
    ([Ee]([+-]?[0-9]+))?
$/x;

sub _write_with_infinity {
    my $ws = shift;
    return $ws->write_string(@_) if $_[2] =~ /$qr_num/ and $_[2]+0 =~ /Inf/;
    return;
}


1;


=head1 NAME

Spreadsheet::Compare::Reporter::XLSX - XLSX Report Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

Handles writing Spreadsheet::Compare reports in XLSX format.

=head1 ATTRIBUTES

The format attributes have to be valid format strings used by L<Excel::Writer::XLSX>.
(see L<Excel::Writer::XLSX/CELL FORMATTING>)

The defaults for the attributes are:

    fmt_head       => 'bold 1 align left',
    fmt_headerr    => 'bold 1 align left bg_color yellow',
    fmt_default    => 'color black',
    fmt_left_odd   => 'color blue',
    fmt_right_odd  => 'color red',
    fmt_diff_odd   => 'color green',
    fmt_left_even  => 'color blue  bg_color silver',
    fmt_right_even => 'color red   bg_color silver',
    fmt_diff_even  => 'color green bg_color silver',
    fmt_left_high  => 'color blue  bg_color yellow',
    fmt_right_high => 'color red   bg_color yellow',
    fmt_diff_high  => 'color black bg_color yellow',
    fmt_left_low   => 'color blue  bg_color lime',
    fmt_right_low  => 'color red   bg_color lime',
    fmt_diff_low   => 'color black bg_color lime',

=head1 METHODS

see L<Spreadsheet::Compare::Reporter>

=cut
