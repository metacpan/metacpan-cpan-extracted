package Physics::Lithography::LIFT;
use strict;
use warnings;
use Carp;
use List::Util qw(max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Laser-Induced Forward Transfer (LIFT) model
#
# Models:
#   - Vapor recoil pressure and jetting threshold
#   - Droplet/voxel size prediction
#   - Transfer regimes (sub-threshold, jetting, spray)
#   - Film-to-receiver gap effects
#   - Multi-material LIFT (donor film stacks)
# ═══════════════════════════════════════════════════════════════════════════════

use constant PI => 3.14159265358979;
use constant KB => 1.380649e-23;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        verbose       => $opts{verbose} // 0,
        # Donor film properties
        film_thickness => $opts{film_thickness} // 100e-9,  # m (100 nm)
        density        => $opts{density} // 19300,          # kg/m³ (gold)
        T_melt         => $opts{T_melt} // 1337,            # K
        T_boil         => $opts{T_boil} // 3129,            # K
        L_vaporize     => $opts{L_vaporize} // 1.74e6,      # J/kg
        surface_tension => $opts{surface_tension} // 1.14,  # N/m (gold)
        viscosity      => $opts{viscosity} // 5e-3,         # Pa·s
        # Geometry
        gap            => $opts{gap} // 50e-6,              # m (donor-receiver gap)
        # Laser
        alpha          => $opts{alpha} // 7e7,              # 1/m
        reflectivity   => $opts{reflectivity} // 0.37,
    }, $class;
    return $self;
}

# Threshold fluence for LIFT transfer
# Based on energy needed to melt/vaporize donor at interface
sub transfer_threshold {
    my ($self, %opts) = @_;
    my $d     = $opts{film_thickness} // $self->{film_thickness};
    my $rho   = $self->{density};
    my $cp    = $opts{cp} // 130;       # J/(kg·K)
    my $T_m   = $self->{T_melt};
    my $L     = $self->{L_vaporize};
    my $alpha = $self->{alpha};
    my $R     = $self->{reflectivity};
    my $T0    = 300;

    # Energy to heat + partially vaporize the interface layer
    # F_th = ρ × d × (cp×(T_boil-T0) + L/2) / (1-R)
    # For thin films where α×d >> 1, most energy absorbed at interface
    my $absorb_fraction = 1 - exp(-$alpha * $d);
    my $E_needed = $rho * $d * ($cp * ($self->{T_boil} - $T0) + $L * 0.1);
    my $F_th = $E_needed / ((1 - $R) * $absorb_fraction);
    return $F_th * 1e-4;  # J/cm²
}

# Vapor recoil pressure at donor-substrate interface
sub recoil_pressure {
    my ($self, %opts) = @_;
    my $F     = $opts{fluence} // 0.5;             # J/cm²
    my $tau   = $opts{pulse_width} // 10e-9;       # s
    my $F_m2  = $F * 1e4;                          # J/m²
    my $R     = $self->{reflectivity};
    my $L     = $self->{L_vaporize};
    my $rho   = $self->{density};

    # Intensity at surface
    my $I = (1 - $R) * $F_m2 / $tau;  # W/m²

    # Ablation pressure: P ≈ 0.5 × ρ × v_ablation²
    # where v_abl ≈ I / (ρ × L)
    my $v_abl = $I / ($rho * $L);
    my $P_recoil = 0.5 * $rho * $v_abl**2;

    return $P_recoil;  # Pa
}

# Predicted droplet diameter
sub droplet_diameter {
    my ($self, %opts) = @_;
    my $F      = $opts{fluence} // 0.5;
    my $spot   = $opts{spot_size} // 5e-6;  # m
    my $d      = $self->{film_thickness};
    my $sigma  = $self->{surface_tension};
    my $rho    = $self->{density};

    my $F_th = $self->transfer_threshold;

    # Below threshold: no transfer
    return 0 if $F <= $F_th;

    # Near threshold (jetting regime): droplet ≈ spot size × (d/spot)^(1/3)
    my $ratio = $F / $F_th;
    if ($ratio < 3) {
        # Clean transfer regime: one droplet ≈ spot diameter
        return 2 * $spot * (1 + 0.2 * log($ratio));
    } else {
        # Spray regime: smaller satellites
        return 2 * $spot / sqrt($ratio);
    }
}

# Transfer regime classification
sub transfer_regime {
    my ($self, %opts) = @_;
    my $F    = $opts{fluence} // 0.5;
    my $F_th = $self->transfer_threshold;

    if ($F < $F_th * 0.8) {
        return 'no_transfer';
    } elsif ($F < $F_th) {
        return 'sub_threshold';
    } elsif ($F < $F_th * 3) {
        return 'jetting';       # clean single droplet
    } elsif ($F < $F_th * 10) {
        return 'spray';         # multiple droplets
    } else {
        return 'explosive';     # plasma-assisted
    }
}

# Jet velocity estimate (m/s)
sub jet_velocity {
    my ($self, %opts) = @_;
    my $P = $self->recoil_pressure(%opts);
    my $rho = $self->{density};
    my $d = $self->{film_thickness};

    # Velocity from pressure impulse on thin film: v ≈ P×τ/(ρ×d)
    my $tau = $opts{pulse_width} // 10e-9;
    return $P * $tau / ($rho * $d);
}

# Time of flight from donor to receiver
sub flight_time {
    my ($self, %opts) = @_;
    my $v = $self->jet_velocity(%opts);
    return ($v > 0) ? $self->{gap} / $v : 0;
}

# Weber number (inertia vs surface tension)
sub weber_number {
    my ($self, %opts) = @_;
    my $v   = $self->jet_velocity(%opts);
    my $D   = $self->droplet_diameter(%opts);
    my $rho = $self->{density};
    my $sig = $self->{surface_tension};
    return ($sig > 0 && $D > 0) ? $rho * $v**2 * $D / $sig : 0;
}

# Reynolds number of the jet
sub reynolds_number {
    my ($self, %opts) = @_;
    my $v   = $self->jet_velocity(%opts);
    my $D   = $self->droplet_diameter(%opts);
    my $rho = $self->{density};
    my $mu  = $self->{viscosity};
    return ($mu > 0 && $D > 0) ? $rho * $v * $D / $mu : 0;
}

# Sweep fluence and characterize transfer
sub fluence_sweep {
    my ($self, %opts) = @_;
    my $F_min = $opts{F_min} // 0.01;
    my $F_max = $opts{F_max} // 3.0;
    my $n_pts = $opts{points} // 30;
    my $spot  = $opts{spot_size} // 5e-6;

    my @sweep;
    for my $i (0 .. $n_pts-1) {
        my $F = $F_min * exp(log($F_max/$F_min) * $i / ($n_pts-1));
        push @sweep, {
            fluence     => $F,
            regime      => $self->transfer_regime(fluence => $F),
            droplet_um  => $self->droplet_diameter(fluence => $F, spot_size => $spot) * 1e6,
            velocity_ms => $self->jet_velocity(fluence => $F, %opts),
            pressure_MPa => $self->recoil_pressure(fluence => $F, %opts) / 1e6,
        };
    }
    return \@sweep;
}

1;
