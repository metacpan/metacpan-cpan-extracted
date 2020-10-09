package Mojo::PDF::Primitive::Table;

our $VERSION = '1.005003'; # VERSION

use List::AllUtils qw/sum uniq/;
use Types::Standard qw/
    HashRef ArrayRef  Tuple  InstanceOf  StrictNum  Str  CodeRef  Optional
/;
use Types::Common::Numeric qw/PositiveInt  PositiveOrZeroNum  PositiveNum/;
use Moo 2.000002;
use Tie::RangeHash 1.05;
use namespace::clean;

$Carp::Internal{ (__PACKAGE__) }++;

##### Required
has at => (
    is       => 'ro',
    required => 1,
    isa      => Tuple[ StrictNum, StrictNum ],
);
has data       => ( is => 'ro',   required => 1,  isa => ArrayRef,       );
has pdf => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf['Mojo::PDF'],
);

##### Defaults/Optional
has header => (
    is => 'ro',
    isa => Str,
);
has border => (
    is      => 'ro',
    default => sub { [.5, '#ccc'] },
    isa     => Tuple[PositiveOrZeroNum, Str],
);
has max_height => (
    is      => 'ro',
    default => '+Inf',
    coerce  => sub { ref $_[0] ? $_[0]->[0] : $_[0] },
    isa     => PositiveOrZeroNum,
);
has min_width      => ( is => 'ro',   default  => 0,  isa =>PositiveOrZeroNum);
has padding        => (
    is      => 'ro',
    default => sub { [3, 6] },
    isa     => Tuple[PositiveOrZeroNum,Optional[PositiveOrZeroNum],Optional[PositiveOrZeroNum],Optional[PositiveOrZeroNum]],
    coerce => sub {
        my $v = shift;
        return @$v == 4 ? [@$v]
            : @$v == 3 ? [ $v->[0], $v->[1], $v->[2], $v->[1] ]
            : @$v == 2 ? [ $v->[0], $v->[1], $v->[0], $v->[1] ]
            : [ (@$v) x 4 ];
    },
);
has row_height     => ( is => 'ro',   default  => 12, isa => PositiveNum,    );
has str_width_mult => (
    is => 'ro',
    default  => 1,
    isa => HashRef,
    coerce => sub {
        my ( $v ) = @_;

        tie my %widths, 'Tie::RangeHash';
        unless ( ref $v ) { $widths{'0,'} = $v; return \%widths; }

        my $prev = -1;
        for ( uniq map sprintf('%.f', $_), sort { $a <=> $b } keys %$v ) {
            $widths{"$prev.1,$_"} = $v->{$_};
            $prev = $_;
        }

        return \%widths;
    },
);
##### Internal
has _extra_row_h   => ( is => 'rw',   default  => 0,                         );
has _row_lines     => ( is => 'rw',   default  => 0,                         );
has _border_color  => ( is => 'lazy', builder  => sub { shift->border->[1]  });
has _border_width  => ( is => 'lazy', builder  => sub { shift->border->[0]  });
has _col_widths    => ( is => 'lazy',                                        );
has _cols          => ( is => 'lazy',                                        );
has _header_row    => ( is => 'lazy', builder  => sub { shift->data->[0]    });
has _rows          => ( is => 'lazy', builder  => sub {scalar @{shift->data}});
has _x             => ( is => 'lazy', builder  => sub { shift->at->[0]      });
has _y             => ( is => 'lazy', builder  => sub { shift->at->[1]      });

sub _build__cols {
    my $data = shift->data;
    my $col_num = 0;
    @$_ > $col_num and $col_num = @$_ for @$data;
    return $col_num;
}

sub _build__col_widths {
    my $self = shift;
    my $data = $self->data;
    my $col_num = $self->_cols;

    my @col_widths = (0) x $col_num;
    my $w_mult = $self->str_width_mult;
    for my $row ( @$data ) {
        for ( 0 .. $col_num - 1 ) {
            next unless my $l = length $row->[$_];
            my $w = 0;
            for ( split /\n/, $row->[$_] ) {
                my $mult = $w_mult->{ +length } // 1;
                my $new_w = $mult * $self->pdf->_str_width( $_ );
                $w = $new_w if $new_w > $w;
            }
            $col_widths[$_] = $w if $w > $col_widths[$_];
        }
    }

    my ( undef, $pad_xr, undef, $pad_xl ) = @{ $self->padding };
    $_ += $pad_xr + $pad_xl for @col_widths; # cell padding

    # Stretch largest column to fill table to its min_width
    if ( $self->min_width > sum @col_widths ) {
        my $idx = 0;
        for ( 0 .. $#col_widths ) {
           $idx = $_ if $col_widths[$_] > $col_widths[0]
        }
        $col_widths[$idx] += $self->min_width - sum @col_widths;
    }

    return \@col_widths;
}

####
#### METHODS
####

sub draw {
    my $self = shift;
    my $data = $self->data;

    $self->pdf->_stroke( $self->_border_width );

    for my $row ( 1 .. $self->_rows ) {
        $self->_draw_row( $row, $data->[$row-1] )
            or return (
                $self->header ? $self->_header_row : (),
                @$data[$row-1 .. $self->_rows-1],
            );
    }

    return;
}

sub _draw_row {
    my ( $self, $r_num, $cells ) = @_;

    my $row_lines = 1;
    for ( @$cells ) {
        my $cell_lines = 1 + tr/\n//;
        $row_lines = $cell_lines if $row_lines < $cell_lines;
    }
    $self->_row_lines( $row_lines );

    for my $cell ( 1 .. @$cells ) {
        $self->_draw_cell( $r_num, $cell, $cells->[$cell-1] )
            or return;
    }

    $self->_extra_row_h(
        $self->_extra_row_h + $self->row_height * ($row_lines-1)
    );

    return 1;
}

sub _draw_cell {
    my ( $self, $r_num, $c_num, $text ) = @_;
    my $pdf = $self->pdf;
    return 1 unless length $text;

    my ( $pad_yt, undef, $pad_yb, $pad_xl ) = @{ $self->padding };

    my $x1 = $self->_x;
    $x1   += $self->_col_widths->[$_] for 0 .. $c_num - 2;
    my $y1 = $self->_y + ($self->row_height + $pad_yt + $pad_yb)*($r_num-1)
        + $self->_extra_row_h;

    my $x2 = $x1 + $self->_col_widths->[$c_num-1];
    my $y2 = $y1 + $pad_yt + $pad_yb
        + ( $self->row_height * $self->_row_lines );

    return if $y2 > $self->max_height;

    my $saved_color = $pdf->_cur_color;
    $pdf->color( $self->_border_color );
    $pdf->_line( $x1, $y1, $x2, $y1 );
    $pdf->_line( $x2, $y1, $x2, $y2 );
    $pdf->_line( $x2, $y2, $x1, $y2 );
    $pdf->_line( $x1, $y2, $x1, $y1 );
    $pdf->color( @$saved_color );

    # Render table header
    if ( $r_num == 1 and $self->header ) {
        my $saved_font = $pdf->_cur_font;
        $pdf->font( $self->header );
        $pdf->text(
            $text,
            $x1 + ( .5*$self->_col_widths->[$c_num-1] ),
            $y1 + $self->row_height + $pad_yt - 2,
            'center',
        );
        $pdf->font( $saved_font );

        return 1;
    }

    $pdf->text(
        $text,
        $x1 + $pad_xl,
        $y1 + $self->row_height + $pad_yt - 2
    );

    return 1;
}

1;

__END__

=encoding utf8

=for stopwords Znet Zoffix

=for Pod::Coverage *EVERYTHING*

=head1 NAME

Mojo::PDF::Primitive::Table - table primitive for Mojo::PDF

=head1 DESCRIPTION

Class implementing a table primitive. See L<Mojo::PDF/"table">

=cut

