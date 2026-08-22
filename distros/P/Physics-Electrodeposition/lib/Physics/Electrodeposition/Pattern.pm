package Physics::Electrodeposition::Pattern;

use strict;
use warnings;
use Physics::Electrodeposition::GDSII;

our $VERSION = '1.00';

#=============================================================================
# Physics::Electrodeposition::Pattern
#
# Turns a GDSII photoresist / plating-mask layout into the geometric quantities
# an electrodeposition model needs:
#
#   * open (plating) area and pattern density  ("open fraction")
#   * feature count and critical-dimension (CD) statistics
#   * a pattern-density map (grid) -> within-die loading non-uniformity
#   * a radial density profile     -> within-wafer variation (wafer-scope masks)
#
# In through-mask plating the resist covers the field and metal grows only in
# the openings, so the LOCAL current density is the applied (wafer-referenced)
# current density divided by the open fraction. Regions of low local pattern
# density ("isolated" features) draw more current and plate thicker -- the
# classic loading (pattern-density) effect captured here.
#=============================================================================

my $PI = 4 * atan2(1, 1);

#-----------------------------------------------------------------------------
# new(
#   gdsii  => $gdsii_obj,          # OR  file => 'mask.gds'
#   layer  => 1,                   # plating-opening layer (undef = all layers)
#   datatype => undef,             # optional datatype filter
#   grid   => 16,                  # density-map resolution (grid x grid)
#   scope  => 'die',               # 'die' (repeated field) or 'wafer'
#   wafer_diameter => 300,         # mm, used only for scope=>'wafer'
# )
#-----------------------------------------------------------------------------
sub new {
    my ($class, %a) = @_;
    my $gds = $a{gdsii};
    $gds ||= Physics::Electrodeposition::GDSII->new(file => $a{file}) if $a{file};
    die "Pattern: need gdsii => obj or file => path" unless $gds;

    my $self = {
        gdsii          => $gds,
        source         => $a{file} // 'gdsii',
        layer          => $a{layer},          # undef = all
        datatype       => $a{datatype},
        grid           => $a{grid}   // 16,
        scope          => $a{scope}  // 'die',
        wafer_diameter => $a{wafer_diameter} // 300,
        _cache         => {},
    };
    bless $self, $class;
    $self->_analyze;
    return $self;
}

#-----------------------------------------------------------------------------
# Polygon geometry helpers (coordinates in micrometres)
#-----------------------------------------------------------------------------

# Signed shoelace area (um^2); sign encodes winding.
sub _poly_area {
    my $pts = shift;
    my $n = @$pts;
    return 0 if $n < 3;
    my $a = 0;
    for my $i (0 .. $n - 1) {
        my $j = ($i + 1) % $n;
        $a += $pts->[$i][0] * $pts->[$j][1] - $pts->[$j][0] * $pts->[$i][1];
    }
    return $a / 2.0;
}

# Area-weighted centroid (um).
sub _poly_centroid {
    my $pts = shift;
    my $n = @$pts;
    my ($cx, $cy, $a) = (0, 0, 0);
    for my $i (0 .. $n - 1) {
        my $j = ($i + 1) % $n;
        my $cross = $pts->[$i][0] * $pts->[$j][1] - $pts->[$j][0] * $pts->[$i][1];
        $a  += $cross;
        $cx += ($pts->[$i][0] + $pts->[$j][0]) * $cross;
        $cy += ($pts->[$i][1] + $pts->[$j][1]) * $cross;
    }
    return @{$pts->[0]} if $a == 0;
    $a /= 2.0;
    return ($cx / (6 * $a), $cy / (6 * $a));
}

# Axis-aligned bounding box of a polygon.
sub _poly_bbox {
    my $pts = shift;
    my ($x0, $y0) = @{$pts->[0]};
    my ($x1, $y1) = ($x0, $y0);
    for my $p (@$pts) {
        $x0 = $p->[0] if $p->[0] < $x0;  $x1 = $p->[0] if $p->[0] > $x1;
        $y0 = $p->[1] if $p->[1] < $y0;  $y1 = $p->[1] if $p->[1] > $y1;
    }
    return ($x0, $y0, $x1, $y1);
}

#-----------------------------------------------------------------------------
# One-time analysis
#-----------------------------------------------------------------------------
sub _analyze {
    my $self = shift;
    my $all = $self->{gdsii}->polygons;

    my @feat;
    my ($X0, $Y0, $X1, $Y1);
    for my $poly (@$all) {
        next if defined $self->{layer}    && $poly->{layer}    != $self->{layer};
        next if defined $self->{datatype} && $poly->{datatype} != $self->{datatype};
        my $pts  = $poly->{pts};
        next if @$pts < 3;
        my $area = abs(_poly_area($pts));
        next if $area <= 0;
        my ($cx, $cy) = _poly_centroid($pts);
        my ($bx0, $by0, $bx1, $by1) = _poly_bbox($pts);
        push @feat, {
            area => $area, cx => $cx, cy => $cy,
            bx0 => $bx0, by0 => $by0, bx1 => $bx1, by1 => $by1,
            w => $bx1 - $bx0, h => $by1 - $by0,
            cd => (($bx1 - $bx0) < ($by1 - $by0) ? ($bx1 - $bx0) : ($by1 - $by0)),
        };
        $X0 = $bx0 if !defined $X0 || $bx0 < $X0;
        $Y0 = $by0 if !defined $Y0 || $by0 < $Y0;
        $X1 = $bx1 if !defined $X1 || $bx1 > $X1;
        $Y1 = $by1 if !defined $Y1 || $by1 > $Y1;
    }

    $self->{features} = \@feat;
    $self->{bbox}     = defined $X0 ? [$X0, $Y0, $X1, $Y1] : [0, 0, 0, 0];

    my $open = 0; $open += $_->{area} for @feat;
    $self->{open_area_um2} = $open;                      # sum of opening areas
    my $fw = ($X1 // 0) - ($X0 // 0);
    my $fh = ($Y1 // 0) - ($Y0 // 0);
    $self->{field_area_um2} = ($fw > 0 && $fh > 0) ? $fw * $fh : 0;
}

#-----------------------------------------------------------------------------
# Public geometric results
#-----------------------------------------------------------------------------
sub feature_count  { return scalar @{$_[0]->{features}}; }
sub open_area_um2  { return $_[0]->{open_area_um2}; }
sub field_area_um2 { return $_[0]->{field_area_um2}; }
sub bbox           { return @{$_[0]->{bbox}}; }

# open (plating) fraction of the field = pattern density (0..1)
sub open_fraction {
    my $s = shift;
    return $s->{field_area_um2} > 0
         ? $s->{open_area_um2} / $s->{field_area_um2} : 0;
}

# critical-dimension statistics (um): min / mean / max opening CD
sub cd_stats {
    my $s = shift;
    my @cd = map { $_->{cd} } @{$s->{features}};
    return (0, 0, 0) unless @cd;
    my ($min, $max, $sum) = ($cd[0], $cd[0], 0);
    for (@cd) { $min = $_ if $_ < $min; $max = $_ if $_ > $max; $sum += $_; }
    return ($min, $sum / @cd, $max);
}

# equivalent circular diameter of the mean feature (um)
sub mean_feature_diameter {
    my $s = shift;
    my $n = $s->feature_count or return 0;
    my $mean_area = $s->{open_area_um2} / $n;
    return sqrt(4 * $mean_area / $PI);
}

#-----------------------------------------------------------------------------
# Density map (grid x grid) using centroid binning.  Returns arrayref of local
# pattern densities (open area / cell area) for cells that contain features.
#-----------------------------------------------------------------------------
sub density_map {
    my $s = shift;
    return $s->{_cache}{dmap} if $s->{_cache}{dmap};
    my $g = $s->{grid};
    my ($x0, $y0, $x1, $y1) = @{$s->{bbox}};
    my $w = $x1 - $x0; my $h = $y1 - $y0;
    my @cell_open = (0) x ($g * $g);
    my $cw = $w / $g; my $ch = $h / $g;
    if ($w > 0 && $h > 0) {
        for my $f (@{$s->{features}}) {
            # Distribute the opening's area over the cells its bounding box
            # overlaps, weighted by the overlap fraction.  For rectangular pads
            # this is exact and removes grid-aliasing on uniform fields.
            my $bw = $f->{bx1} - $f->{bx0};
            my $bh = $f->{by1} - $f->{by0};
            my $barea = $bw * $bh;
            if ($barea <= 0) {                      # degenerate: bin by centroid
                my $ci = int(($f->{cx} - $x0) / $cw); $ci = $g-1 if $ci >= $g; $ci = 0 if $ci < 0;
                my $cj = int(($f->{cy} - $y0) / $ch); $cj = $g-1 if $cj >= $g; $cj = 0 if $cj < 0;
                $cell_open[$cj * $g + $ci] += $f->{area};
                next;
            }
            my $ci0 = int(($f->{bx0} - $x0) / $cw); $ci0 = 0 if $ci0 < 0;
            my $ci1 = int(($f->{bx1} - $x0) / $cw); $ci1 = $g - 1 if $ci1 >= $g;
            my $cj0 = int(($f->{by0} - $y0) / $ch); $cj0 = 0 if $cj0 < 0;
            my $cj1 = int(($f->{by1} - $y0) / $ch); $cj1 = $g - 1 if $cj1 >= $g;
            for my $ci ($ci0 .. $ci1) {
                my $cx0 = $x0 + $ci * $cw;
                my $ox = _overlap($f->{bx0}, $f->{bx1}, $cx0, $cx0 + $cw);
                next if $ox <= 0;
                for my $cj ($cj0 .. $cj1) {
                    my $cy0 = $y0 + $cj * $ch;
                    my $oy = _overlap($f->{by0}, $f->{by1}, $cy0, $cy0 + $ch);
                    next if $oy <= 0;
                    $cell_open[$cj * $g + $ci] += $f->{area} * ($ox * $oy) / $barea;
                }
            }
        }
    }
    my $cell_area = ($cw > 0 && $ch > 0) ? $cw * $ch : 0;
    my @dens = $cell_area > 0 ? map { $_ / $cell_area } @cell_open : ();
    $s->{_cache}{dmap} = \@dens;
    return \@dens;
}

# 1-D interval overlap length
sub _overlap {
    my ($a0, $a1, $b0, $b1) = @_;
    my $lo = $a0 > $b0 ? $a0 : $b0;
    my $hi = $a1 < $b1 ? $a1 : $b1;
    return $hi > $lo ? $hi - $lo : 0;
}

#-----------------------------------------------------------------------------
# Within-die loading non-uniformity (%).  Local plated thickness scales as
# (local density)^(-exponent); we report the 1-sigma spread across populated
# cells.  exponent in [0,1]: 0 = perfectly leveled (no loading), 1 = full
# inverse-density loading.  Default 0.5 (moderate coupling).
#-----------------------------------------------------------------------------
sub loading_nonuniformity {
    my ($s, $exp) = @_;
    $exp = 0.5 unless defined $exp;
    my $dmap = $s->density_map;
    my @d = grep { $_ > 0 } @$dmap;
    return 0 unless @d > 1;
    my @t = map { $_ ** (-$exp) } @d;             # relative thickness per cell
    my $mean = 0; $mean += $_ for @t; $mean /= @t;
    return 0 if $mean <= 0;
    my $var = 0; $var += ($_ - $mean) ** 2 for @t; $var /= @t;
    return 100 * sqrt($var) / $mean;              # percent (1-sigma)
}

# Ratio of the plated thickness of the most isolated feature to the densest
# region (isolated/dense), an intuitive loading-effect figure.
sub isolated_to_dense_ratio {
    my ($s, $exp) = @_;
    $exp = 0.5 unless defined $exp;
    my @d = grep { $_ > 0 } @{$s->density_map};
    return 1 unless @d;
    my ($lo, $hi) = (sort { $a <=> $b } @d)[0, -1];
    return $lo > 0 ? ($lo ** (-$exp)) / ($hi ** (-$exp)) : 1;
}

#-----------------------------------------------------------------------------
# Radial pattern-density profile (wafer-scope masks): equal-area annuli from
# the pattern centre.  Returns arrayref of { r_in, r_out, density } (um, fraction)
#-----------------------------------------------------------------------------
sub radial_profile {
    my ($s, $nzones) = @_;
    $nzones ||= 5;
    my ($x0, $y0, $x1, $y1) = @{$s->{bbox}};
    my $cx = ($x0 + $x1) / 2; my $cy = ($y0 + $y1) / 2;
    my $R  = $s->{scope} eq 'wafer'
           ? ($s->{wafer_diameter} * 1000 / 2)          # mm -> um radius
           : (0.5 * sqrt(($x1 - $x0)**2 + ($y1 - $y0)**2));
    return [] if $R <= 0;
    my @open  = (0) x $nzones;
    for my $f (@{$s->{features}}) {
        my $r = sqrt(($f->{cx} - $cx)**2 + ($f->{cy} - $cy)**2);
        my $z = int(($r / $R) ** 2 * $nzones);          # equal-area binning
        $z = $nzones - 1 if $z >= $nzones; $z = 0 if $z < 0;
        $open[$z] += $f->{area};
    }
    my @prof;
    for my $z (0 .. $nzones - 1) {
        my $rin  = $R * sqrt($z / $nzones);
        my $rout = $R * sqrt(($z + 1) / $nzones);
        my $zone_area = $PI * ($rout**2 - $rin**2);
        push @prof, { r_in => $rin, r_out => $rout,
                      density => $zone_area > 0 ? $open[$z] / $zone_area : 0 };
    }
    return \@prof;
}

# Within-wafer non-uniformity (%) from the radial density variation.
sub radial_nonuniformity {
    my ($s, $exp) = @_;
    $exp = 0.5 unless defined $exp;
    my $prof = $s->radial_profile;
    my @t = map { $_->{density} > 0 ? $_->{density} ** (-$exp) : () } @$prof;
    return 0 unless @t > 1;
    my $mean = 0; $mean += $_ for @t; $mean /= @t;
    return 0 if $mean <= 0;
    my $var = 0; $var += ($_ - $mean) ** 2 for @t; $var /= @t;
    return 100 * sqrt($var) / $mean;
}

1;

__END__

=head1 NAME

Physics::Electrodeposition::Pattern - Extract plating geometry (open area,
pattern density, feature CD, loading non-uniformity) from a GDSII mask.

=head1 SYNOPSIS

    use Physics::Electrodeposition::Pattern;

    my $pat = Physics::Electrodeposition::Pattern->new(
        file  => 'bumps.gds',
        layer => 1,               # plating-opening layer
        grid  => 16,
    );

    printf "open fraction = %.3f\n", $pat->open_fraction;
    printf "%d features, CD %.2f um\n", $pat->feature_count, ($pat->cd_stats)[1];
    printf "loading WIDNU = %.1f %%\n", $pat->loading_nonuniformity;

=head1 DESCRIPTION

Given a GDSII layout (via a
L<Physics::Electrodeposition::GDSII> object or a file path) and an optional
layer/datatype selection, computes the geometric inputs a through-mask
electrodeposition model needs: total open (plating) area, pattern density
(open fraction), feature count and critical-dimension statistics, a gridded
pattern-density map, and loading (pattern-density) non-uniformity estimates.

Openings are assumed non-overlapping (standard for a mask layer); polygon areas
are summed by the shoelace formula and no Boolean union is performed. Density
mapping bins each opening by its centroid, which is accurate when features are
small relative to the map cell size.

=head1 METHODS

=over 4

=item open_fraction

Pattern density: summed opening area divided by the field bounding-box area.

=item feature_count / open_area_um2 / field_area_um2 / bbox

Basic geometry.

=item cd_stats

Returns C<($min, $mean, $max)> opening critical dimension in micrometres.

=item mean_feature_diameter

Equivalent circular diameter of the mean opening (um).

=item density_map

Arrayref of local pattern densities over a grid x grid map.

=item loading_nonuniformity([$exponent])

Estimated within-die thickness non-uniformity (%) from pattern-density loading;
thickness ~ density**(-exponent), default exponent 0.5.

=item isolated_to_dense_ratio([$exponent])

Plated-thickness ratio of the most isolated to the densest region.

=item radial_profile([$nzones]) / radial_nonuniformity([$exponent])

Radial (center-to-edge) density profile and the resulting within-wafer
non-uniformity (%), for wafer-scope masks.

=back

=cut
