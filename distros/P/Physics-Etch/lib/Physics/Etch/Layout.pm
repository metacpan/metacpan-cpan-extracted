package Physics::Etch::Layout;

use strict;
use warnings;
use Carp qw(croak);

use Physics::Etch::GDSII;

our $VERSION = '0.01';

# ===========================================================================
# Geometric analysis of a mask layer for etch modelling.
#
# Construct from a GDSII object + layer, or from a list of polygons.
# Polygons are stored internally in microns.
#
#   tone : 'clear' -> drawn polygons ARE the etch openings (default)
#          'dark'  -> drawn polygons are the mask; openings = field - drawn
#   field: [w, h] in microns (defaults to the polygon bounding box)
# ===========================================================================
sub new {
    my ( $class, %a ) = @_;

    my @polys;
    if ( $a{gdsii} ) {
        @polys = $a{gdsii}->polygons(
            layer     => $a{layer},
            structure => $a{structure},
            unit      => 'um',
        );
    }
    elsif ( $a{polygons} ) {
        @polys = @{ $a{polygons} };
    }
    else {
        croak "Layout: need 'gdsii' or 'polygons'";
    }

    my $self = bless {
        polygons => \@polys,
        tone     => $a{tone} // 'clear',
        field    => $a{field},          # [w,h] um or undef
        layer    => $a{layer},
    }, $class;

    $self->_compute_bbox;
    return $self;
}

sub from_gdsii_file {
    my ( $class, $file, %a ) = @_;
    my $g = Physics::Etch::GDSII->read($file);
    return $class->new( gdsii => $g, %a );
}

sub polygons { @{ $_[0]->{polygons} } }
sub count    { scalar @{ $_[0]->{polygons} } }
sub tone     { $_[0]->{tone} }

# ---------------------------------------------------------------------------
# Bounding box / field  (microns)
# ---------------------------------------------------------------------------
sub _compute_bbox {
    my ($self) = @_;
    my ( $xmin, $ymin, $xmax, $ymax );
    for my $p ( @{ $self->{polygons} } ) {
        for my $pt (@$p) {
            $xmin = $pt->[0] if !defined $xmin || $pt->[0] < $xmin;
            $ymin = $pt->[1] if !defined $ymin || $pt->[1] < $ymin;
            $xmax = $pt->[0] if !defined $xmax || $pt->[0] > $xmax;
            $ymax = $pt->[1] if !defined $ymax || $pt->[1] > $ymax;
        }
    }
    $self->{bbox} = [ $xmin // 0, $ymin // 0, $xmax // 0, $ymax // 0 ];
}

sub bbox { @{ $_[0]->{bbox} } }         # (xmin,ymin,xmax,ymax) um

sub field_wh {
    my ($self) = @_;
    return @{ $self->{field} } if $self->{field};
    my ( $x0, $y0, $x1, $y1 ) = @{ $self->{bbox} };
    return ( $x1 - $x0, $y1 - $y0 );
}

sub field_area_um2 {                    # um^2
    my ($self) = @_;
    my ( $w, $h ) = $self->field_wh;
    return $w * $h;
}

# ---------------------------------------------------------------------------
# Areas  (um^2 ; helpers to cm^2 for loading)
# ---------------------------------------------------------------------------
sub drawn_area_um2 {
    my ($self) = @_;
    my $a = 0;
    $a += _polygon_area( $_[0], $_ ) for @{ $self->{polygons} };
    return $a;
}

sub open_area_um2 {
    my ($self) = @_;
    my $drawn = $self->drawn_area_um2;
    return $self->{tone} eq 'dark'
        ? ( $self->field_area_um2 - $drawn )
        : $drawn;
}

sub open_area_cm2 { $_[0]->open_area_um2 * 1e-8 }      # 1 um^2 = 1e-8 cm^2
sub field_area_cm2 { $_[0]->field_area_um2 * 1e-8 }

sub open_fraction {
    my ($self) = @_;
    my $fa = $self->field_area_um2 or return 0;
    return $self->open_area_um2 / $fa;
}

# ---------------------------------------------------------------------------
# Per-feature critical dimension (nm).  CD ~ narrow side of each polygon's
# bounding box (exact for axis-aligned rectangles/lines).
# ---------------------------------------------------------------------------
sub features {
    my ($self) = @_;
    my @f;
    for my $p ( @{ $self->{polygons} } ) {
        my ( $x0, $y0, $x1, $y1 );
        for my $pt (@$p) {
            $x0 = $pt->[0] if !defined $x0 || $pt->[0] < $x0;
            $y0 = $pt->[1] if !defined $y0 || $pt->[1] < $y0;
            $x1 = $pt->[0] if !defined $x1 || $pt->[0] > $x1;
            $y1 = $pt->[1] if !defined $y1 || $pt->[1] > $y1;
        }
        my $w  = $x1 - $x0;
        my $h  = $y1 - $y0;
        my $cd = $w < $h ? $w : $h;                  # microns
        push @f,
            {
            cd_um   => $cd,
            cd_nm   => $cd * 1000,
            long_um => ( $w > $h ? $w : $h ),
            area_um2 => _polygon_area( $self, $p ),
            center  => [ ( $x0 + $x1 ) / 2, ( $y0 + $y1 ) / 2 ],
            };
    }
    return \@f;
}

sub cd_stats_nm {
    my ($self) = @_;
    my @cd = map { $_->{cd_nm} } @{ $self->features };
    return {} unless @cd;
    my ( $min, $max, $sum ) = ( $cd[0], $cd[0], 0 );
    for (@cd) { $min = $_ if $_ < $min; $max = $_ if $_ > $max; $sum += $_; }
    return { min => $min, max => $max, mean => $sum / @cd, n => scalar @cd };
}

# ---------------------------------------------------------------------------
# Local pattern-density map (open fraction per grid cell) for microloading.
# cell_um: grid pitch in microns.  Returns { nx, ny, cell, min, max, mean,
# grid => [ [ frac, ... ], ... ] }.
# ---------------------------------------------------------------------------
sub density_map {
    my ( $self, %a ) = @_;
    my $cell = $a{cell_um} // 10;
    my $sub  = $a{subsamples} // 4;          # NxN sample points per cell
    my ( $x0, $y0, $x1, $y1 ) = @{ $self->{bbox} };
    my $w = $x1 - $x0 || $cell;
    my $h = $y1 - $y0 || $cell;
    my $nx = int( $w / $cell + 0.999 ) || 1;
    my $ny = int( $h / $cell + 0.999 ) || 1;

    my @grid;
    my ( $min, $max, $sum ) = ( 1, 0, 0 );
    for my $iy ( 0 .. $ny - 1 ) {
        my @row;
        for my $ix ( 0 .. $nx - 1 ) {
            my $inside = 0;
            my $total  = 0;
            for my $sx ( 0 .. $sub - 1 ) {
                for my $sy ( 0 .. $sub - 1 ) {
                    my $px = $x0 + ( $ix + ( $sx + 0.5 ) / $sub ) * $cell;
                    my $py = $y0 + ( $iy + ( $sy + 0.5 ) / $sub ) * $cell;
                    $total++;
                    $inside++ if $self->_point_drawn( $px, $py );
                }
            }
            my $drawn = $total ? $inside / $total : 0;
            my $open = $self->{tone} eq 'dark' ? 1 - $drawn : $drawn;
            push @row, $open;
            $min = $open if $open < $min;
            $max = $open if $open > $max;
            $sum += $open;
        }
        push @grid, \@row;
    }
    my $n = $nx * $ny;
    return {
        nx   => $nx, ny => $ny, cell => $cell,
        grid => \@grid,
        min  => $min, max => $max, mean => ( $n ? $sum / $n : 0 ),
    };
}

sub _point_drawn {
    my ( $self, $x, $y ) = @_;
    for my $poly ( @{ $self->{polygons} } ) {
        return 1 if _point_in_polygon( $x, $y, $poly );
    }
    return 0;
}

# ---------------------------------------------------------------------------
# geometry primitives
# ---------------------------------------------------------------------------
sub _polygon_area {
    my ( undef, $poly ) = @_;
    my $n = @$poly;
    return 0 if $n < 3;
    my $a = 0;
    for my $i ( 0 .. $n - 1 ) {
        my $j = ( $i + 1 ) % $n;
        $a += $poly->[$i][0] * $poly->[$j][1] - $poly->[$j][0] * $poly->[$i][1];
    }
    return abs($a) / 2;
}

sub _point_in_polygon {
    my ( $x, $y, $poly ) = @_;
    my $n = @$poly;
    my $in = 0;
    for ( my $i = 0, my $j = $n - 1; $i < $n; $j = $i++ ) {
        my ( $xi, $yi ) = @{ $poly->[$i] };
        my ( $xj, $yj ) = @{ $poly->[$j] };
        if ( ( $yi > $y ) != ( $yj > $y )
            && $x < ( $xj - $xi ) * ( $y - $yi ) / ( ( $yj - $yi ) || 1e-30 ) + $xi )
        {
            $in = !$in;
        }
    }
    return $in;
}

# ---------------------------------------------------------------------------
sub summary {
    my ($self) = @_;
    my $cd = $self->cd_stats_nm;
    my ( $fw, $fh ) = $self->field_wh;
    return sprintf(
        "Layout: %d features, tone=%s, field %.1f x %.1f um\n"
            . "  open area %.1f um^2 (%.1f%% open), CD min/mean/max = %.0f/%.0f/%.0f nm",
        $self->count, $self->{tone}, $fw, $fh,
        $self->open_area_um2, 100 * $self->open_fraction,
        $cd->{min} // 0, $cd->{mean} // 0, $cd->{max} // 0,
    );
}

1;

__END__

=head1 NAME

Physics::Etch::Layout - mask-pattern geometry for etch modelling

=head1 SYNOPSIS

    use Physics::Etch::Layout;

    my $lay = Physics::Etch::Layout->from_gdsii_file( 'mask.gds',
        layer => 1, tone => 'clear' );

    printf "open fraction: %.1f%%\n", 100 * $lay->open_fraction;
    my $cd  = $lay->cd_stats_nm;         # { min, mean, max, n }
    my $den = $lay->density_map( cell_um => 20 );

=head1 DESCRIPTION

Analyses a photoresist / mask layer (from L<Physics::Etch::GDSII> or an
explicit polygon list) into the quantities that drive etch loading and
anisotropy:

=over 4

=item * C<open_area_um2> / C<open_area_cm2> / C<open_fraction> - macro-loading input

=item * C<features> / C<cd_stats_nm> - per-feature critical dimension (for ARDE)

=item * C<density_map> - local open-fraction grid (micro-loading input)

=back

C<tone> selects whether drawn polygons are the openings (C<clear>) or the
protected mask (C<dark>). Feature CD is estimated from each polygon's bounding
box (exact for axis-aligned rectangles and lines).

=cut
