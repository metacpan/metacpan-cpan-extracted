package Physics::CVD::Reactor;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# CVD Reactor model
#
# Defines reactor geometry and operating conditions:
#   - Horizontal hot-wall tube (LPCVD)
#   - Showerhead/cold-wall (PECVD, MOCVD)
#   - Batch vs single-wafer
#   - Gas flow rates, residence time, Damköhler number
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB => 1.380649e-23;
use constant R_GAS => 8.314462;
use constant PI => 3.14159265358979;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        type        => $opts{type} // 'lpcvd_tube',  # lpcvd_tube, pecvd, mocvd
        temperature => $opts{temperature} // 700,
        pressure    => $opts{pressure}    // 100,     # Pa
        verbose     => $opts{verbose}     // 0,
        # Geometry
        length      => $opts{length} // 1.0,         # m (tube length)
        diameter    => $opts{diameter} // 0.15,       # m (tube diameter)
        gap         => $opts{gap} // 0.02,           # m (showerhead gap)
        wafer_diameter => $opts{wafer_diameter} // 0.3,  # m (300mm wafer)
        # Gas flow
        total_flow  => $opts{total_flow} // 100,     # sccm
        carrier_gas => $opts{carrier_gas} // 'N2',
        gases       => $opts{gases} // {},           # {name => flow_sccm}
    }, $class;
    return $self;
}

# Gas velocity in tube (m/s)
sub gas_velocity {
    my ($self) = @_;
    my $T = $self->{temperature};
    my $P = $self->{pressure};
    my $flow_m3s = $self->{total_flow} * 1e-6 / 60.0;  # sccm -> m³/s at STP
    # Correct for actual T,P
    $flow_m3s *= ($T / 273.15) * (101325.0 / $P);
    my $area = PI() * ($self->{diameter}/2)**2;
    return $flow_m3s / $area;
}

# Residence time (seconds)
sub residence_time {
    my ($self) = @_;
    my $v = $self->gas_velocity;
    return ($v > 0) ? $self->{length} / $v : 0;
}

# Reynolds number
sub reynolds_number {
    my ($self) = @_;
    my $v   = $self->gas_velocity;
    my $rho = $self->gas_density;
    my $mu  = $self->gas_viscosity;
    return ($mu > 0) ? $rho * $v * $self->{diameter} / $mu : 0;
}

# Gas density (kg/m³) using ideal gas
sub gas_density {
    my ($self) = @_;
    my $M = $self->_carrier_molar_mass;
    return $self->{pressure} * $M / (R_GAS * $self->{temperature});
}

# Gas viscosity (Pa·s) — Sutherland approximation for N₂
sub gas_viscosity {
    my ($self) = @_;
    my $T = $self->{temperature};
    # Sutherland: μ = μ₀(T/T₀)^(3/2) × (T₀+S)/(T+S)
    my $mu0 = 1.76e-5;  # Pa·s at 300K
    my $T0  = 300;
    my $S   = 111;       # K (Sutherland constant for N₂)
    return $mu0 * ($T/$T0)**1.5 * ($T0 + $S) / ($T + $S);
}

# Mean free path (m)
sub mean_free_path {
    my ($self) = @_;
    my $T = $self->{temperature};
    my $P = $self->{pressure};
    my $d = 3.7e-10;  # molecular diameter N₂ (m)
    return KB * $T / (sqrt(2) * PI() * $d**2 * $P);
}

# Knudsen number (Kn = λ/L)
sub knudsen_number {
    my ($self) = @_;
    my $L = ($self->{type} =~ /tube/) ? $self->{diameter} : $self->{gap};
    return $self->mean_free_path / $L;
}

# Damköhler number (Da = reaction rate / mass transfer rate)
sub damkohler_number {
    my ($self, %opts) = @_;
    my $k_s = $opts{surface_rate} // 1e-2;  # cm/s (surface reaction rate)
    my $D   = $self->diffusivity(%opts);     # cm²/s
    my $L   = ($self->{type} =~ /tube/) ? $self->{diameter} : $self->{gap};
    return $k_s * $L * 100 / $D;  # dimensionless
}

# Binary gas diffusivity (cm²/s) — Chapman-Enskog
sub diffusivity {
    my ($self, %opts) = @_;
    my $T = $self->{temperature};
    my $P = $self->{pressure} / 101325.0;  # Pa -> atm
    my $M1 = $opts{mass1} // 28;   # carrier (N₂)
    my $M2 = $opts{mass2} // 44;   # precursor
    my $sigma = $opts{sigma} // 4.0;  # Angstrom, collision diameter
    my $Omega = 1.0;  # collision integral (simplification)

    # D₁₂ = 0.00186 × T^(3/2) × sqrt(1/M₁ + 1/M₂) / (P × σ² × Ω)
    my $D = 0.00186 * $T**1.5 * sqrt(1/$M1 + 1/$M2) /
            ($P * $sigma**2 * $Omega);
    return $D;  # cm²/s
}

# Thiele modulus for feature-scale transport
sub thiele_modulus {
    my ($self, %opts) = @_;
    my $L    = $opts{feature_depth} // 1e-4;  # cm (1 μm trench)
    my $D    = $opts{diffusivity} // $self->diffusivity(%opts);
    my $k_s  = $opts{surface_rate} // 0.01;   # cm/s
    return $L * sqrt($k_s / $D);
}

# Step coverage estimate for a trench
sub step_coverage {
    my ($self, %opts) = @_;
    my $phi = $self->thiele_modulus(%opts);
    # Simplified: SC ≈ 1/cosh(φ) for first-order reaction in trench
    return 1.0 / cosh($phi);
}

sub _carrier_molar_mass {
    my ($self) = @_;
    my %masses = (N2 => 0.028, Ar => 0.040, H2 => 0.002, He => 0.004);
    return $masses{$self->{carrier_gas}} // 0.028;
}

sub summary {
    my ($self) = @_;
    return {
        type            => $self->{type},
        temperature     => $self->{temperature},
        pressure        => $self->{pressure},
        gas_velocity    => $self->gas_velocity,
        residence_time  => $self->residence_time,
        reynolds        => $self->reynolds_number,
        knudsen         => $self->knudsen_number,
        mean_free_path  => $self->mean_free_path,
    };
}

# Helper for cosh
sub cosh { return (exp($_[0]) + exp(-$_[0])) / 2.0 }

1;
