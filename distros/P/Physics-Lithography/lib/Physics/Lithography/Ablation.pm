package Physics::Lithography::Ablation;
use strict;
use warnings;
use Carp;
use List::Util qw(max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Ablation model for laser direct imprint lithography
#
# Models:
#   - Threshold fluence (F_th)
#   - Logarithmic blow-off model: d = (1/α) × ln(F/F_th)
#   - Multi-pulse incubation
#   - Effective absorption coefficient at high fluence
#   - Ablation rate vs fluence curves
#   - Material removal efficiency
# ═══════════════════════════════════════════════════════════════════════════════

use constant PI => 3.14159265358979;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        verbose => $opts{verbose} // 0,
        # Material ablation properties
        alpha        => $opts{alpha} // 1e6,         # 1/m, effective absorption
        F_threshold  => $opts{F_threshold} // 0.1,   # J/cm²
        incubation_N => $opts{incubation_N} // 1,    # number of pulses for threshold
        incubation_S => $opts{incubation_S} // 0.8,  # incubation coefficient S<1
        T_decomp     => $opts{T_decomp} // 623,      # K
        rho          => $opts{density} // 1200,      # kg/m³
        L_ablation   => $opts{L_ablation} // 1e6,    # J/kg (ablation enthalpy)
    }, $class;
    return $self;
}

# Single-pulse ablation depth (m) — logarithmic blow-off model
# d = (1/α_eff) × ln(F/F_th)
sub ablation_depth {
    my ($self, %opts) = @_;
    my $F     = $opts{fluence} // 0.5;           # J/cm²
    my $alpha = $opts{alpha} // $self->{alpha};
    my $F_th  = $opts{F_threshold_eff} // $opts{F_threshold} // $self->{F_threshold};

    return 0 if $F <= $F_th;
    return log($F / $F_th) / $alpha;  # meters
}

# Multi-pulse accumulated depth
sub multi_pulse_depth {
    my ($self, %opts) = @_;
    my $F      = $opts{fluence} // 0.5;
    my $N      = $opts{pulses} // 1;
    my $alpha  = $opts{alpha} // $self->{alpha};

    # Incubation: effective threshold decreases with pulse number
    # F_th(N) = F_th(1) × N^(S-1)
    my $F_th_N = $self->{F_threshold} * $N**($self->{incubation_S} - 1);
    $F_th_N = max($F_th_N, $self->{F_threshold} * 0.1);  # floor

    return 0 if $F <= $F_th_N;
    return $N * log($F / $F_th_N) / $alpha;
}

# Ablation rate (depth per pulse, m/pulse) as function of fluence
sub ablation_rate_curve {
    my ($self, %opts) = @_;
    my $F_min = $opts{F_min} // 0.01;    # J/cm²
    my $F_max = $opts{F_max} // 5.0;
    my $n_pts = $opts{points} // 50;

    my @curve;
    for my $i (0 .. $n_pts-1) {
        my $F = $F_min * exp(log($F_max/$F_min) * $i / ($n_pts-1));
        my $d = $self->ablation_depth(fluence => $F);
        push @curve, { fluence => $F, depth_nm => $d * 1e9 };
    }
    return \@curve;
}

# Threshold fluence from material properties (thermal model)
# F_th ≈ ρ × Cp × (T_decomp - T_ambient) / (α × (1-R))
sub calculate_threshold {
    my ($self, %opts) = @_;
    my $rho   = $opts{density} // $self->{rho};
    my $cp    = $opts{cp} // 1200;          # J/(kg·K)
    my $T_d   = $opts{T_decomp} // $self->{T_decomp};
    my $T0    = $opts{T_ambient} // 300;
    my $alpha = $opts{alpha} // $self->{alpha};
    my $R     = $opts{reflectivity} // 0.05;

    # F_th = ρ × cp × ΔT / (α × (1-R))  in J/m² → convert to J/cm²
    my $F_th = $rho * $cp * ($T_d - $T0) / ($alpha * (1 - $R));
    return $F_th * 1e-4;  # J/cm²
}

# Crater geometry: radius and depth for Gaussian beam
sub crater_profile {
    my ($self, %opts) = @_;
    my $F0   = $opts{fluence} // 0.5;
    my $w    = $opts{spot_size} // 5e-6;    # m (1/e² radius)
    my $F_th = $opts{F_threshold} // $self->{F_threshold};
    my $alpha = $opts{alpha} // $self->{alpha};

    return undef if $F0 <= $F_th;

    # Ablation radius: F(r) = F0 × exp(-2r²/w²) = F_th
    # → r_abl = w × sqrt(ln(F0/F_th)/2)
    my $r_abl = $w * sqrt(log($F0 / $F_th) / 2.0);

    # Depth profile: d(r) = (1/α) × ln(F(r)/F_th)
    my $n_pts = $opts{points} // 30;
    my @profile;
    for my $i (0 .. $n_pts-1) {
        my $r = $r_abl * $i / ($n_pts - 1);
        my $F_r = $F0 * exp(-2 * $r**2 / $w**2);
        my $d = ($F_r > $F_th) ? log($F_r / $F_th) / $alpha : 0;
        push @profile, { r_um => $r * 1e6, depth_nm => $d * 1e9 };
    }

    return {
        radius_um  => $r_abl * 1e6,
        max_depth_nm => log($F0 / $F_th) / $alpha * 1e9,
        aspect_ratio => (log($F0 / $F_th) / $alpha) / (2 * $r_abl),
        profile    => \@profile,
    };
}

# Material removal rate (volume per pulse, m³/pulse)
sub volume_per_pulse {
    my ($self, %opts) = @_;
    my $F0   = $opts{fluence} // 0.5;
    my $w    = $opts{spot_size} // 5e-6;
    my $F_th = $opts{F_threshold} // $self->{F_threshold};
    my $alpha = $opts{alpha} // $self->{alpha};

    return 0 if $F0 <= $F_th;

    # V = (π×w²)/(4α) × [ln(F0/F_th)]²
    return (PI * $w**2) / (4.0 * $alpha) * (log($F0 / $F_th))**2;
}

# Ablation efficiency (material removed per unit energy)
sub efficiency {
    my ($self, %opts) = @_;
    my $V = $self->volume_per_pulse(%opts);
    my $E = $opts{fluence} * PI * ($opts{spot_size} // 5e-6)**2 * 1e4;  # J
    return ($E > 0) ? $V * $self->{rho} / $E : 0;  # kg/J
}

# Threshold with incubation for N pulses
# F_th(N) = F_th(1) × N^(S-1)
sub threshold_with_incubation {
    my ($self, %opts) = @_;
    my $N = $opts{N} // 1;
    my $S = $opts{S} // $self->{incubation_S};
    my $F_th = $self->{F_threshold} * $N**($S - 1);
    return max($F_th, $self->{F_threshold} * 0.1);
}

sub stats {
    my ($self) = @_;
    return {
        alpha        => $self->{alpha},
        F_threshold  => $self->{F_threshold},
        incubation_N => $self->{incubation_N},
        incubation_S => $self->{incubation_S},
    };
}

1;
