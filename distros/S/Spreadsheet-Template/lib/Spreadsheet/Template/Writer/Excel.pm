package Spreadsheet::Template::Writer::Excel;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Writer::Excel::VERSION = '0.05';
use Moose::Role;

use Class::Load 'load_class';
use List::Util 'first';

with 'Spreadsheet::Template::Writer';

requires 'excel_class';

has excel => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $self = shift;
        load_class($self->excel_class);
        $self->excel_class->new($self->_fh);
    },
);

has _fh => (
    is      => 'ro',
    isa     => 'FileHandle',
    lazy    => 1,
    default => sub {
        my $self = shift;
        open my $fh, '>', $self->_output
            or die "Failed to open filehandle: $!";
        binmode $fh;
        return $fh;
    },
);

has _output => (
    is      => 'ro',
    isa     => 'ScalarRef[Maybe[Str]]',
    default => sub { \(my $str) },
);

has _colors => (
    is      => 'ro',
    isa     => 'HashRef[Int]',
    default => sub {
        {
            black   => 8,
            blue    => 12,
            brown   => 16,
            cyan    => 15,
            gray    => 23,
            green   => 17,
            lime    => 11,
            magenta => 14,
            navy    => 18,
            orange  => 53,
            pink    => 33,
            purple  => 20,
            red     => 10,
            silver  => 22,
            white   => 9,
            yellow  => 13,

        }
    },
);

has _formats => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub write {
    my $self = shift;
    my ($data) = @_;

    $self->_write_workbook($data);

    $self->excel->close;
    return ${ $self->_output };
}

sub _write_workbook {
    my $self = shift;
    my ($data) = @_;

    # XXX no way to write default cell properties

    if (exists $data->{properties}) {
        $self->excel->set_properties(%{ $data->{properties} });
    }

    for my $sheet (@{ $data->{worksheets} }) {
        $self->_write_worksheet($sheet);
    }

    if (exists $data->{selected}) {
        $self->excel->sheets($data->{selected})->activate;
    }
}

sub _write_worksheet {
    my $self = shift;
    my ($data) = @_;

    my $sheet = $self->excel->add_worksheet(
        exists $data->{name} ? ($data->{name}) : ()
    );

    if (exists $data->{tab_color}) {
        $sheet->set_tab_color($self->_color($data->{tab_color}));
    }

    if (exists $data->{zoom}) {
        $sheet->set_zoom($data->{zoom});
    }

    if (exists $data->{hidden}) {
        # XXX this won't work on the first worksheet, since you can't hide
        # active worksheets - need to restructure things a bit to fix this
        $sheet->hide;
    }

    if (exists $data->{selection}) {
        $sheet->set_selection(@{ $data->{selection} });
    }

    if (exists $data->{freeze}) {
        $sheet->freeze_panes(@{ $data->{freeze} });
    }

    if (exists $data->{split}) {
        $sheet->split_panes(@{ $data->{split} });
    }

    if (exists $data->{column_widths}) {
        for my $i (0..$#{ $data->{column_widths} }) {
            # XXX hidden columns?
            $sheet->set_column($i, $i, $data->{column_widths}[$i]);
        }
    }

    if (exists $data->{row_heights}) {
        for my $i (0..$#{ $data->{row_heights} }) {
            # XXX hidden rows?
            $sheet->set_row($i, $data->{row_heights}[$i]);
        }
    }

    for my $row (0..$#{ $data->{cells} }) {
        for my $col (0..$#{ $data->{cells}[$row] }) {
            $self->_write_cell($data->{cells}[$row][$col], $sheet, $row, $col);
        }
    }

    if (exists $data->{merge}) {
        for my $merge (@{ $data->{merge} }) {
            $self->_write_merge($merge, $sheet);
        }
    }

    if (exists $data->{autofilter}) {
        for my $autofilter (@{ $data->{autofilter} }) {
            $sheet->autofilter(
                $autofilter->[0][0],
                $autofilter->[0][1],
                $autofilter->[1][0],
                $autofilter->[1][1],
            );
        }
    }
}

sub _write_cell {
    my $self = shift;
    my ($data, $sheet, $row, $col) = @_;

    my $write_method = 'write';
    if (exists $data->{type}) {
        $write_method = "write_$data->{type}";
    }

    my $format;
    if (exists $data->{format}) {
        $format = $self->_munge_format($data->{format});
    }

    if (defined $data->{formula}) {
        $sheet->write_formula(
            $row, $col,
            $data->{formula},
            (defined $format ? ($format) : (undef)),
            (defined $data->{contents}
                ? ($data->{contents})
                : ()),
        );
    }
    else {
        $sheet->$write_method(
            $row, $col,
            $data->{contents},
            (defined $format ? ($format) : ()),
        );
    }
}

sub _write_merge {
    my $self = shift;
    my ($data, $sheet) = @_;

    my $format;
    if (exists $data->{format}) {
        $format = $self->_munge_format($data->{format});
    }

    if (exists $data->{formula}) {
        $sheet->merge_range_type(
            'formula',
            @{ $data->{range}[0] },
            @{ $data->{range}[1] },
            $data->{formula},
            (defined $format ? ($format) : (undef)),
            (defined $data->{contents}
                ? ($data->{contents})
                : ()),
        );
    }
    else {
        $sheet->merge_range_type(
            $data->{type},
            @{ $data->{range}[0] },
            @{ $data->{range}[1] },
            $data->{contents},
            (defined $format ? ($format) : ()),
        );
    }
}

sub _munge_format {
    my $self = shift;
    my ($format) = @_;

    my %border = (
        none                => 0,
        thin                => 1,
        medium              => 2,
        dashed              => 3,
        dotted              => 4,
        thick               => 5,
        double              => 6,
        hair                => 7,
        medium_dashed       => 8,
        dash_dot            => 9,
        medium_dash_dot     => 10,
        dash_dot_dot        => 11,
        medium_dash_dot_dot => 12,
        slant_dash_dot      => 13,
    );

    my $properties = { %$format };

    if (my $border = delete $properties->{border}) {
        $properties = {
            left   => $border->[0],
            right  => $border->[1],
            top    => $border->[2],
            bottom => $border->[3],
            %$properties,
        };
    }

    if (my $border_color = delete $properties->{border_color}) {
        $properties = {
            left_color   => $border_color->[0],
            right_color  => $border_color->[1],
            top_color    => $border_color->[2],
            bottom_color => $border_color->[3],
            %$properties,
        };
    }

    $properties = {
        map {
            my $v = $properties->{$_};
            $_ => JSON::is_bool($v) ? ($v ? 1 : 0)
                : $_ eq 'left'      ? $border{$v}
                : $_ eq 'right'     ? $border{$v}
                : $_ eq 'top'       ? $border{$v}
                : $_ eq 'bottom'    ? $border{$v}
                : $_ =~ /color/     ? $self->_color($v)
                :                     $v
        } keys %$properties
    };

    return $self->_format($properties);
}

sub _color {
    my $self = shift;
    my ($color) = @_;

    return 64 if !defined($color);

    if (exists $self->_colors->{$color}) {
        return $self->_colors->{$color};
    }
    else {
        my $hex = qr/[0-9a-fA-F]/;
        my ($r, $g, $b) = $color =~ /^#($hex$hex)($hex$hex)($hex$hex)$/;

        my %used_colors = reverse %{ $self->_colors };
        my $new_idx = first { !exists $used_colors{$_} } 8..63;
        die "too many colors" unless defined $new_idx;

        $self->excel->set_custom_color(
            $new_idx,
            map { oct("0x$_") } $r, $g, $b
        );
        $self->_colors->{$color} = $new_idx;

        return $new_idx;
    }
}

sub _format {
    my $self = shift;
    my ($format_properties) = @_;

    my %pattern = (
        none             => 0,
        solid            => 1,
        medium_gray      => 2,
        dark_gray        => 3,
        light_gray       => 4,
        dark_horizontal  => 5,
        dark_vertical    => 6,
        dark_down        => 7,
        dark_up          => 8,
        dark_grid        => 9,
        dark_trellis     => 10,
        light_horizontal => 11,
        light_vertical   => 12,
        light_down       => 13,
        light_up         => 14,
        light_grid       => 15,
        light_trellis    => 16,
        gray_125         => 17,
        gray_0625        => 18,
    );

    if (exists $format_properties->{pattern}) {
        $format_properties->{pattern} = $pattern{$format_properties->{pattern}}
            unless $format_properties->{pattern} =~ /^\d+$/;
    }

    my $key = JSON->new->canonical->encode($format_properties);
    if (exists $self->_formats->{$key}) {
        return $self->_formats->{$key};
    }
    else {
        my $format = $self->excel->add_format(%$format_properties);
        $self->_formats->{$key} = $format;
        return $format;
    }
}

no Moose::Role;

=begin Pod::Coverage

  write

=end Pod::Coverage

=cut

1;
