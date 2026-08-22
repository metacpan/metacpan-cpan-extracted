package Physics::Etch::Simulation;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

# ===========================================================================
# Ties an etch process to a chamber, a mask layout and a loading model, then
# simulates pattern-dependent, per-feature etch behaviour:
#   * chamber geometry -> pressure & DC bias handed to the process
#   * open area + wafer area -> macro loading -> reduced global rate
#   * per-feature CD -> aspect ratio -> ARDE (RIE lag) -> local rate & taper
#   * local pattern density -> micro loading
#
#   new( process => $etch,          # Physics::Etch::WetEtch or DryEtch (req.)
#        chamber => $chamber,       # Physics::Etch::Chamber   (optional)
#        layout  => $layout,        # Physics::Etch::Layout    (optional)
#        loading => $loading,       # Physics::Etch::Loading   (optional)
#        wafer_area_cm2 => ...,     # overrides chamber wafer area
#        micro_cell_um  => 20 )
# ===========================================================================
sub new {
    my ( $class, %a ) = @_;
    my $self = bless {
        process        => $a{process} || croak('Simulation: process required'),
        chamber        => $a{chamber},
        layout         => $a{layout},
        loading        => $a{loading},
        wafer_area_cm2 => $a{wafer_area_cm2},
        micro_cell_um  => $a{micro_cell_um} // 20,
        _ran           => 0,
    }, $class;
    return $self;
}

sub process { $_[0]->{process} }
sub chamber { $_[0]->{chamber} }
sub layout  { $_[0]->{layout} }
sub loading { $_[0]->{loading} }

# ---------------------------------------------------------------------------
sub run {
    my ($self) = @_;
    my $p = $self->{process};

    # 1) chamber -> process conditions (only if the process accepts them)
    if ( $self->{chamber} && $p->can('bias') ) {
        my %c = $self->{chamber}->process_conditions;
        $p->pressure( $c{pressure} ) if defined $c{pressure};
        $p->bias( $c{bias} )         if defined $c{bias};
    }

    # base (unloaded) rates
    $self->{base_loading} //= ( $p->can('loading') ? $p->loading : 1 );
    $p->loading( $self->{base_loading} ) if $p->can('loading');
    my $base_rate = $p->vertical_rate;

    # 2) macro loading from open area
    my $wafer_area = $self->{wafer_area_cm2}
        // ( $self->{chamber} ? $self->{chamber}->wafer_area_cm2 : undef );
    my ( $open_fraction, $a_load );
    if ( $self->{layout} ) {
        $open_fraction = $self->{layout}->open_fraction;
        $a_load = defined $wafer_area
            ? $open_fraction * $wafer_area
            : $self->{layout}->open_area_cm2;
    }
    my $macro = 1;
    if ( $self->{loading} && defined $a_load ) {
        $macro = $self->{loading}->macro_factor($a_load);
        $p->loading( $self->{base_loading} * $macro ) if $p->can('loading');
    }

    # loaded global rates / timing (low aspect ratio field)
    my $Rv = $p->vertical_rate;
    my $Rl = $p->lateral_rate;
    my $thickness = $p->thickness
        or croak 'Simulation: process needs a film thickness';
    my $t_clear = $thickness / $Rv;
    my $etch_time = $p->etch_time;      # respects explicit time or overetch

    # 3) micro-loading density map
    my ( $den, $mean_den );
    if ( $self->{layout} ) {
        $den = $self->{layout}->density_map( cell_um => $self->{micro_cell_um} );
        $mean_den = $den->{mean};
    }

    # 4) per-feature analysis
    my @feat;
    if ( $self->{layout} ) {
        for my $f ( @{ $self->{layout}->features } ) {
            push @feat, $self->_analyze_feature( $f, $Rv, $Rl, $thickness,
                $etch_time, $den, $mean_den );
        }
    }

    $self->{result} = {
        base_rate     => $base_rate,
        macro_factor  => $macro,
        loaded_rate   => $Rv,
        lateral_rate  => $Rl,
        open_fraction => $open_fraction,
        wafer_area    => $wafer_area,
        a_load        => $a_load,
        time_to_clear => $t_clear,
        etch_time     => $etch_time,
        thickness     => $thickness,
        density       => $den,
        features      => \@feat,
    };
    $self->{_ran} = 1;
    return $self;
}

sub _analyze_feature {
    my ( $self, $f, $Rv, $Rl, $thickness, $t, $den, $mean_den ) = @_;
    my $cd = $f->{cd_nm};
    my $ar = $cd > 0 ? $thickness / $cd : 0;      # final aspect ratio

    # ARDE
    my ( $av, $al ) = ( 1, 1 );
    if ( $self->{loading} ) {
        $av = $self->{loading}->arde_factor($ar);
        $al = $self->{loading}->arde_lateral_factor($ar);
    }

    # micro loading at feature center
    my $micro = 1;
    my $local_den;
    if ( $self->{loading} && $den ) {
        $local_den = $self->_density_at( $den, $f->{center} );
        $micro = $self->{loading}->micro_relative( $local_den, $mean_den );
    }

    my $rv = $Rv * $av * $micro;
    my $rl = $Rl * $al * $micro;
    my $depth = $rv * $t;
    my $film  = $depth > $thickness ? $thickness : $depth;
    my $under = $rl * $t;
    my $aniso = $rv > 0 ? 1 - $rl / $rv : 0;
    $aniso = 0 if $aniso < 0;
    my $angle = _deg( atan2( $film, $under ) );

    return {
        cd_nm          => $cd,
        aspect_ratio   => $ar,
        arde_factor    => $av,
        local_density  => $local_den,
        local_rate     => $rv,
        depth          => $depth,
        film_depth     => $film,
        cleared        => ( $depth >= $thickness ? 1 : 0 ),
        undercut       => $under,
        etch_bias      => 2 * $under,
        anisotropy     => $aniso,
        sidewall_angle => $angle,
    };
}

sub _density_at {
    my ( $self, $den, $center ) = @_;
    my ( $cx, $cy ) = @$center;
    my ( $x0, $y0 ) = ( $self->{layout}->bbox )[ 0, 1 ];
    my $ix = int( ( $cx - $x0 ) / $den->{cell} );
    my $iy = int( ( $cy - $y0 ) / $den->{cell} );
    $ix = 0 if $ix < 0;
    $iy = 0 if $iy < 0;
    $ix = $den->{nx} - 1 if $ix > $den->{nx} - 1;
    $iy = $den->{ny} - 1 if $iy > $den->{ny} - 1;
    return $den->{grid}[$iy][$ix];
}

# ---------------------------------------------------------------------------
# grouped-by-CD view (arrays of identical features collapse to one row)
# ---------------------------------------------------------------------------
sub features_by_cd {
    my ($self) = @_;
    $self->run unless $self->{_ran};
    my %g;
    for my $f ( @{ $self->{result}{features} } ) {
        my $key = sprintf '%.0f', $f->{cd_nm};
        push @{ $g{$key} }, $f;
    }
    my @rows;
    for my $key ( sort { $a <=> $b } keys %g ) {
        my @fs  = @{ $g{$key} };
        my $rep = $fs[0];
        # worst (min) sidewall / clearance within the group
        my ( $min_ang, $any_uncleared ) = ( $rep->{sidewall_angle}, 0 );
        for my $f (@fs) {
            $min_ang = $f->{sidewall_angle} if $f->{sidewall_angle} < $min_ang;
            $any_uncleared = 1 unless $f->{cleared};
        }
        push @rows,
            {
            %$rep,
            count          => scalar @fs,
            sidewall_angle => $min_ang,
            cleared        => ( $any_uncleared ? 0 : 1 ),
            };
    }
    return \@rows;
}

sub result { $_[0]->run unless $_[0]->{_ran}; $_[0]->{result} }

# ---------------------------------------------------------------------------
sub report {
    my ($self) = @_;
    $self->run unless $self->{_ran};
    my $r = $self->{result};
    my $p = $self->{process};
    my @o;

    push @o, '#' x 66;
    push @o, sprintf( '# ETCH SIMULATION  --  %s  (%s)',
        $p->target->label, $p->process_type );
    push @o, '#' x 66;

    push @o, $self->{chamber}->report if $self->{chamber};
    push @o, $self->{loading}->describe if $self->{loading};
    push @o, $self->{layout}->summary   if $self->{layout};

    push @o, '-' x 66;
    push @o, sprintf( '  Base rate            : %.1f nm/min', $r->{base_rate} );
    if ( $self->{loading} && defined $r->{a_load} ) {
        push @o, sprintf(
            '  Macro loading        : A_load %.1f cm^2 -> x%.3f  (%.1f -> %.1f nm/min)',
            $r->{a_load}, $r->{macro_factor}, $r->{base_rate}, $r->{loaded_rate} );
    }
    push @o, sprintf( '  Global etch          : clear %.2f min, run %.2f min',
        $r->{time_to_clear}, $r->{etch_time} );

    if ( $r->{density} ) {
        push @o, sprintf(
            '  Micro density        : local open %.2f - %.2f (mean %.2f)',
            $r->{density}{min}, $r->{density}{max}, $r->{density}{mean} );
    }

    # per-CD feature table
    my $rows = $self->features_by_cd;
    if (@$rows) {
        push @o, '-' x 66;
        push @o, sprintf( '  %-9s %-4s %-6s %-7s %-8s %-7s %-6s %s',
            'CD(nm)', 'x', 'AR', 'ARDE', 'depth', 'under', 'A', 'wall' );
        for my $row (@$rows) {
            push @o, sprintf(
                '  %-9.0f %-4d %-6.2f %-7.2f %-8.0f %-7.1f %-6.3f %.0f%s',
                $row->{cd_nm}, $row->{count}, $row->{aspect_ratio},
                $row->{arde_factor}, $row->{depth}, $row->{undercut},
                $row->{anisotropy}, $row->{sidewall_angle},
                ( $row->{cleared} ? '' : '  *UNCLEARED*' ),
            );
        }
        push @o, '  (depth/under in nm; A = anisotropy; wall = sidewall deg)';

        # RIE-lag / loading depth spread (shallowest vs deepest feature)
        my @by_depth = sort { $a->{depth} <=> $b->{depth} } @$rows;
        my $shallow  = $by_depth[0];
        my $deep     = $by_depth[-1];
        if ( $deep->{depth} > 0 ) {
            push @o, '-' x 66;
            push @o, sprintf(
                '  Pattern spread: shallowest (%.0f nm, AR %.2f) reaches %.0f%% '
                    . 'of the deepest (%.0f nm) etch depth',
                $shallow->{cd_nm}, $shallow->{aspect_ratio},
                100 * $shallow->{depth} / $deep->{depth}, $deep->{cd_nm} );
        }
        my @unc = grep { !$_->{cleared} } @$rows;
        push @o, sprintf( '  WARNING: %d CD group(s) not cleared at run time', scalar @unc )
            if @unc;
    }

    push @o, '#' x 66;
    return join( "\n", @o ) . "\n";
}

sub _deg { $_[0] * 180 / 3.14159265358979 }

1;

__END__

=head1 NAME

Physics::Etch::Simulation - pattern/chamber/loading-aware etch simulation

=head1 SYNOPSIS

    use Physics::Etch;
    use Physics::Etch::Chamber;
    use Physics::Etch::Layout;
    use Physics::Etch::Loading;
    use Physics::Etch::Simulation;

    my $etch = Physics::Etch->dry_etch('silicon_nitride', thickness => 300);

    my $chamber = Physics::Etch::Chamber->new(
        wafer_diameter_mm => 200, pressure_mtorr => 20, power_w => 300 );

    my $layout  = Physics::Etch::Layout->from_gdsii_file('mask.gds', layer => 1);
    my $loading = Physics::Etch::Loading->from_chamber($chamber);

    my $sim = Physics::Etch::Simulation->new(
        process => $etch, chamber => $chamber,
        layout  => $layout, loading => $loading );

    print $sim->report;
    my $rows = $sim->features_by_cd;    # per-CD anisotropy / undercut / lag

=head1 DESCRIPTION

Couples the reactor, mask pattern and loading models to the base etch model.
On C<run> it:

=over 4

=item 1. hands the chamber's derived pressure and DC bias to the process;

=item 2. computes macro loading from the layout open fraction and wafer area,
lowering the global etch rate;

=item 3. for every mask feature, converts CD to aspect ratio and applies ARDE
(RIE lag) plus local micro-loading to get a per-feature rate, etch depth,
undercut, anisotropy and sidewall angle;

=item 4. flags features that fail to clear and reports the RIE-lag spread.

=back

C<report> renders the whole picture; C<features_by_cd> and C<result> expose the
numbers.

=cut
