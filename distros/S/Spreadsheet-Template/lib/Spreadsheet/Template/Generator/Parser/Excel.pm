package Spreadsheet::Template::Generator::Parser::Excel;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Generator::Parser::Excel::VERSION = '0.05';
use Moose::Role;

use DateTime::Format::Excel;
use JSON;

with 'Spreadsheet::Template::Generator::Parser';

requires '_create_workbook';

has _excel_dt => (
    is      => 'ro',
    isa     => 'DateTime::Format::Excel',
    lazy    => 1,
    default => sub { DateTime::Format::Excel->new },
);

sub parse {
    my $self = shift;
    my ($filename) = @_;
    my $book = $self->_create_workbook($filename);
    return $self->_parse_workbook($book);
}

sub _parse_workbook {
    my $self = shift;
    my ($book) = @_;

    my $data = {
        selection  => $book->{SelectedSheet}, # XXX
        worksheets => [],
    };

    if ($book->using_1904_date) {
        $self->_excel_dt->epoch_mac;
    }

    for my $sheet ($book->worksheets) {
        push @{ $data->{worksheets} }, $self->_parse_worksheet($book, $sheet);
    }

    return $data;
}

sub _parse_worksheet {
    my $self = shift;
    my ($book, $sheet) = @_;

    my $data = {
        name          => $sheet->get_name,
        row_heights   => [ $sheet->get_row_heights ],
        column_widths => [ $sheet->get_col_widths ],
        selection     => $sheet->{Selection}, # XXX
        cells         => [],
    };

    my ($rmin, $rmax) = $sheet->row_range;
    my ($cmin, $cmax) = $sheet->col_range;

    splice @{ $data->{row_heights} }, $rmax + 1;
    splice @{ $data->{column_widths} }, $cmax + 1;

    for my $row (0..$rmin - 1) {
        push @{ $data->{cells} }, [];
    }

    for my $row ($rmin..$rmax) {
        my $row_data = [];
        for my $col (0..$cmin - 1) {
            push @$row_data, {};
        }
        for my $col ($cmin..$cmax) {
            if (my $cell = $sheet->get_cell($row, $col)) {
                push @$row_data, $self->_parse_cell($book, $cell);
            }
            else {
                push @$row_data, {};
            }
        }
        push @{ $data->{cells} }, $row_data
    }

    return $data;
}

sub _parse_cell {
    my $self = shift;
    my ($book, $cell) = @_;

    my $contents = $cell->unformatted;
    my $type = $cell->type;
    my $formula = $cell->{Formula}; # XXX
    my $format = $cell->get_format;

    if ($type eq 'Numeric') {
        $type = 'number';
    }
    elsif ($type eq 'Text') {
        $type = 'string';
    }
    elsif ($type eq 'Date') {
        $type = 'date_time';
        $contents = $self->_excel_dt->parse_datetime($contents)->iso8601
            if defined $contents && length $contents;
    }
    else {
        die "unknown type $type";
    }

    my $format_data = {};
    if ($format) {
        my %halign = (
            0 => 'none',
            1 => 'left',
            2 => 'center',
            3 => 'right',
            4 => 'fill',
            5 => 'justify',
            6 => 'center_across',
            # XXX this isn't supported by Spreadsheet::WriteExcel
            7 => 'distributed',
        );

        my %valign = (
            0 => 'top',
            1 => 'vcenter',
            2 => 'bottom',
            3 => 'vjustify',
            # XXX this isn't supported by Spreadsheet::WriteExcel
            4 => 'vdistributed',
        );

        my %border = (
            0  => 'none',
            1  => 'thin',
            2  => 'medium',
            3  => 'dashed',
            4  => 'dotted',
            5  => 'thick',
            6  => 'double',
            7  => 'hair',
            8  => 'medium_dashed',
            9  => 'dash_dot',
            10 => 'medium_dash_dot',
            11 => 'dash_dot_dot',
            12 => 'medium_dash_dot_dot',
            13 => 'slant_dash_dot',
        );

        my %fill = (
            0  => 'none',
            1  => 'solid',
            2  => 'medium_gray',
            3  => 'dark_gray',
            4  => 'light_gray',
            5  => 'dark_horizontal',
            6  => 'dark_vertical',
            7  => 'dark_down',
            8  => 'dark_up',
            9  => 'dark_grid',
            10 => 'dark_trellis',
            11 => 'light_horizontal',
            12 => 'light_vertical',
            13 => 'light_down',
            14 => 'light_up',
            15 => 'light_grid',
            16 => 'light_trellis',
            17 => 'gray_125',
            18 => 'gray_0625',
        );

        if (!$format->{IgnoreFont}) {
            $format_data->{size} = $format->{Font}{Height};
            $format_data->{color} = $format->{Font}{Color}
                unless lc($format->{Font}{Color}) eq '#ffffff'; # XXX
            $format_data->{bold} = JSON::true
                if $format->{Font}{Bold};
            $format_data->{italic} = JSON::true
                if $format->{Font}{Italic};
        }
        if (!$format->{IgnoreFill}) {
            if ($format->{Fill}[0] != 0) {
                $format_data->{pattern}  = $fill{$format->{Fill}[0]};
                # XXX this seems pretty wrong, but... not sure what the
                # actually right way is, and this works for now
                if ($format_data->{pattern} eq 'solid') {
                    $format_data->{bg_color} = $format->{Fill}[1];
                }
                else {
                    $format_data->{fg_color} = $format->{Fill}[1];
                    $format_data->{bg_color} = $format->{Fill}[2];
                }
            }
        }
        if (!$format->{IgnoreBorder}) {
            $format_data->{border_color} = $format->{BdrColor};
            if (grep { $_ != 0 } @{ $format->{BdrStyle} }) { # XXX
                $format_data->{border} = [
                    map { $border{$_} } @{ $format->{BdrStyle} }
                ];
            }
        }
        if (!$format->{IgnoreAlignment}) {
            $format_data->{align} = $halign{$format->{AlignH}}
                unless $format->{AlignH} == 0;
            $format_data->{valign} = $valign{$format->{AlignV}}
                unless $format->{AlignV} == 2;
            $format_data->{text_wrap} = JSON::true
                if $format->{Wrap};
        }
        if (!$format->{IgnoreNumberFormat}) {
            $format_data->{num_format} = $book->{FormatStr}{$format->{FmtIdx}}
                unless $book->{FormatStr}{$format->{FmtIdx}} eq 'GENERAL';
        }
    }

    my $data = {
        contents => $contents,
        type     => $type,
        ($formula ? (formula => $formula) : ()),
        (keys %$format_data ? (format => $format_data) : ()),
    };

    return $data;
}

no Moose::Role;

=begin Pod::Coverage

  parse

=end Pod::Coverage

=cut

1;
