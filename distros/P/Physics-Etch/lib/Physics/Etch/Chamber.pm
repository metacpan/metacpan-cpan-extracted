package Physics::Etch::Chamber;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

use constant {
    KB      => 1.380649e-23,       # J/K
    TORR_PA => 133.322,            # Pa per Torr
    SCCM_TORR_L_S => 0.01270,      # 1 sccm ~ 0.0127 Torr.L/s (0 degC)
};

# ===========================================================================
# Plasma-etch reactor geometry -> plasma / transport quantities that feed the
# etch model (DC self-bias, ion energy, residence time, mean free path).
#
# Attributes (all optional; sensible defaults for a small CCP-RIE):
#   reactor_type       label  (default 'CCP-RIE')
#   wafer_diameter_mm  (default 150)
#   powered_area_cm2   powered-electrode area (default = wafer area)
#   grounded_area_cm2  grounded area (default = area_ratio_default * powered)
#   gap_cm             electrode gap (default 3)
#   volume_l           chamber volume (default = powered_area*gap)
#   pressure_mtorr     (default 20)
#   power_w            RF power (default 200)
#   flow_sccm          total gas flow (default 50)
#   gas / gas_mass_amu / gas_diameter_m / gas_temp_k  (default Ar, 300 K)
#   plasma_potential_v (default 15)
#   bias_const / area_exponent  calibration knobs for the self-bias heuristic
# ===========================================================================
sub new {
    my ( $class, %a ) = @_;

    my $wafer = $a{wafer_diameter_mm} // 150;
    my $wafer_area = 3.14159265358979 * ( $wafer / 20 )**2;   # cm^2 (mm/2/10)

    my $powered = $a{powered_area_cm2} // $wafer_area;
    my $grounded = $a{grounded_area_cm2}
        // ( $powered * ( $a{grounded_ratio} // 3 ) );
    my $gap = $a{gap_cm} // 3;

    my $self = bless {
        reactor_type      => $a{reactor_type}      // 'CCP-RIE',
        wafer_diameter_mm => $wafer,
        wafer_area_cm2    => $wafer_area,
        powered_area_cm2  => $powered,
        grounded_area_cm2 => $grounded,
        gap_cm            => $gap,
        volume_l          => $a{volume_l} // ( $powered * $gap / 1000 ),
        pressure_mtorr    => $a{pressure_mtorr} // 20,
        power_w           => $a{power_w}         // 200,
        flow_sccm         => $a{flow_sccm}       // 50,
        gas               => $a{gas}             // 'Ar',
        gas_mass_amu      => $a{gas_mass_amu}    // 40,
        gas_diameter_m    => $a{gas_diameter_m}  // 3.4e-10,
        gas_temp_k        => $a{gas_temp_k}      // 300,
        plasma_potential_v => $a{plasma_potential_v} // 15,
        bias_const        => $a{bias_const}    // 150,
        area_exponent     => $a{area_exponent} // 0.30,
    }, $class;

    return $self;
}

# simple accessors
for my $attr (
    qw( reactor_type wafer_diameter_mm wafer_area_cm2 powered_area_cm2
    grounded_area_cm2 gap_cm volume_l pressure_mtorr power_w flow_sccm
    gas gas_mass_amu gas_diameter_m gas_temp_k plasma_potential_v )
    )
{
    no strict 'refs';
    *{$attr} = sub {
        my ( $self, $v ) = @_;
        $self->{$attr} = $v if @_ > 1;
        return $self->{$attr};
    };
}

sub pressure_torr { $_[0]->{pressure_mtorr} / 1000 }
sub pressure_pa   { $_[0]->pressure_torr * TORR_PA }

# electrode-area asymmetry (>= 1)
sub area_ratio {
    my ($self) = @_;
    return $self->{powered_area_cm2}
        ? $self->{grounded_area_cm2} / $self->{powered_area_cm2}
        : 1;
}

sub power_density { $_[0]->{power_w} / ( $_[0]->{powered_area_cm2} || 1 ) }   # W/cm^2

# gas residence time (s):  tau = p*V / throughput
sub residence_time_s {
    my ($self) = @_;
    my $q = $self->{flow_sccm} * SCCM_TORR_L_S;      # Torr.L/s
    return $q > 0 ? $self->pressure_torr * $self->{volume_l} / $q : undef;
}

# mean free path (meters):  lambda = kT / (sqrt(2) * pi * d^2 * p)
sub mean_free_path_m {
    my ($self) = @_;
    my $p = $self->pressure_pa;
    return undef unless $p > 0;
    my $d = $self->{gas_diameter_m};
    return KB * $self->{gas_temp_k}
        / ( 1.41421356 * 3.14159265358979 * $d * $d * $p );
}
sub mean_free_path_mm { my $l = $_[0]->mean_free_path_m; defined $l ? $l * 1000 : undef }

# Knudsen number over the electrode gap
sub knudsen {
    my ($self) = @_;
    my $l = $self->mean_free_path_m;
    return undef unless defined $l;
    return $l / ( $self->{gap_cm} / 100 );
}

# DC self-bias magnitude (V) -- heuristic, scales with power, asymmetry; falls
# with pressure.  Calibrated so the defaults give a few hundred volts.
sub self_bias_v {
    my ($self) = @_;
    my $p_term = ( $self->{pressure_mtorr} / 20 )**0.30;
    return $self->{bias_const}
        * ( $self->{power_w} / 100 )**0.5
        * ( $self->area_ratio )**$self->{area_exponent}
        / ( $p_term || 1 );
}

# ion energy at the wafer (eV) ~ sheath drop + plasma potential
sub ion_energy_ev { $_[0]->self_bias_v + $_[0]->{plasma_potential_v} }

# suggested process knobs to hand to a DryEtch
sub process_conditions {
    my ($self) = @_;
    return (
        pressure => $self->{pressure_mtorr},
        bias     => $self->self_bias_v,
    );
}

sub report {
    my ($self) = @_;
    my @l;
    push @l, '=' x 66;
    push @l, sprintf( 'CHAMBER  --  %s', $self->{reactor_type} );
    push @l, '=' x 66;
    push @l, sprintf( '  Wafer / powered / grounded : %.0f mm / %.0f / %.0f cm^2',
        $self->{wafer_diameter_mm}, $self->{powered_area_cm2},
        $self->{grounded_area_cm2} );
    push @l, sprintf( '  Area ratio (gnd/pwr)       : %.2f', $self->area_ratio );
    push @l, sprintf( '  Gap / volume               : %.1f cm / %.2f L',
        $self->{gap_cm}, $self->{volume_l} );
    push @l, sprintf( '  Gas / pressure / flow      : %s / %g mTorr / %g sccm',
        $self->{gas}, $self->{pressure_mtorr}, $self->{flow_sccm} );
    push @l, sprintf( '  RF power / power density   : %g W / %.2f W/cm^2',
        $self->{power_w}, $self->power_density );
    push @l, '  ' . '-' x 62;
    push @l, sprintf( '  DC self-bias (est.)        : %.0f V', $self->self_bias_v );
    push @l, sprintf( '  Ion energy (est.)          : %.0f eV', $self->ion_energy_ev );
    push @l, sprintf( '  Residence time             : %.1f ms',
        1000 * ( $self->residence_time_s // 0 ) );
    push @l, sprintf( '  Mean free path             : %.2f mm  (Kn = %.2f)',
        $self->mean_free_path_mm // 0, $self->knudsen // 0 );
    push @l, '=' x 66;
    return join( "\n", @l ) . "\n";
}

1;

__END__

=head1 NAME

Physics::Etch::Chamber - plasma-etch reactor geometry and derived conditions

=head1 SYNOPSIS

    use Physics::Etch::Chamber;

    my $ch = Physics::Etch::Chamber->new(
        reactor_type   => 'CCP-RIE',
        wafer_diameter_mm => 200,
        gap_cm         => 2.5,
        pressure_mtorr => 30,
        power_w        => 300,
        flow_sccm      => 80,
        gas            => 'SF6', gas_mass_amu => 146, gas_diameter_m => 4.8e-10,
    );

    print $ch->report;
    printf "bias=%.0f V, tau=%.1f ms, lambda=%.2f mm\n",
        $ch->self_bias_v, 1000*$ch->residence_time_s, $ch->mean_free_path_mm;

    # feed the derived conditions straight into a dry etch
    my %cond = $ch->process_conditions;   # ( pressure => .., bias => .. )

=head1 DESCRIPTION

Turns reactor geometry and operating point into the quantities that control an
etch: electrode C<area_ratio>, C<power_density>, C<residence_time_s> (gas
depletion / loading), C<mean_free_path_m> and C<knudsen> (ion directionality),
and a heuristic DC C<self_bias_v> / C<ion_energy_ev>. C<process_conditions>
returns pressure and bias ready to pass to L<Physics::Etch::DryEtch>.

The self-bias model is a calibrated heuristic (rises with power and
electrode asymmetry, falls with pressure), not a first-principles sheath
solution.

=cut
