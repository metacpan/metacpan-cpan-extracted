package Physics::CVD::Transport;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Mass transport modeling for CVD
#
# Models:
#   - Boundary layer diffusion (stagnation flow)
#   - Feature-scale transport (Knudsen diffusion in trenches/vias)
#   - Ballistic transport in molecular flow regime
#   - Conformality and step coverage prediction
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB => 1.380649e-23;
use constant PI => 3.14159265358979;
use constant R_GAS => 8.314462;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        temperature => $opts{temperature} // 700,
        pressure    => $opts{pressure}    // 100,
        verbose     => $opts{verbose}     // 0,
        # Feature geometry
        feature_type  => $opts{feature_type} // 'trench',  # trench, via, blanket
        aspect_ratio  => $opts{aspect_ratio} // 3.0,
        feature_width => $opts{feature_width} // 0.1e-4,   # cm (100nm)
    }, $class;
    return $self;
}

# Knudsen diffusivity in a feature (cm²/s)
sub knudsen_diffusivity {
    my ($self, %opts) = @_;
    my $T     = $opts{T} // $self->{temperature};
    my $width = $opts{width} // $self->{feature_width};
    my $mass  = $opts{mass} // 44;  # amu
    my $m_kg  = $mass * 1.66054e-27;
    # D_Kn = (w/3) × sqrt(8kT/(πm))
    return ($width / 3.0) * sqrt(8.0 * KB * $T / (PI() * $m_kg));
}

# Effective diffusivity (Bosanquet interpolation)
sub effective_diffusivity {
    my ($self, %opts) = @_;
    my $D_bulk = $opts{D_bulk} // 10.0;  # cm²/s (gas-phase)
    my $D_Kn   = $self->knudsen_diffusivity(%opts);
    # 1/D_eff = 1/D_bulk + 1/D_Kn
    return 1.0 / (1.0/$D_bulk + 1.0/$D_Kn);
}

# Step coverage for a trench/via with first-order surface kinetics
# Uses the Yanguas-Gil analytical model
sub step_coverage {
    my ($self, %opts) = @_;
    my $AR    = $opts{aspect_ratio} // $self->{aspect_ratio};
    my $S     = $opts{sticking_coeff} // 0.1;
    my $width = $opts{width} // $self->{feature_width};

    # Modified Thiele modulus for CVD in features
    # φ = AR × sqrt(S / (2-S)) for a trench
    my $phi;
    if ($self->{feature_type} eq 'via') {
        $phi = $AR * sqrt($S);
    } else {
        $phi = $AR * sqrt($S / (2.0 - $S));
    }

    # Bottom/top deposition rate ratio
    my $sc = 1.0 / (1.0 + $phi**2 / 6.0);  # parabolic approximation
    $sc = max($sc, 0.01);
    $sc = min($sc, 1.0);
    return $sc;
}

# Full conformality profile along feature depth
sub conformality_profile {
    my ($self, %opts) = @_;
    my $AR    = $opts{aspect_ratio} // $self->{aspect_ratio};
    my $S     = $opts{sticking_coeff} // 0.1;
    my $n_pts = $opts{points} // 20;

    my @profile;
    for my $i (0 .. $n_pts - 1) {
        my $x = $i / ($n_pts - 1);  # 0=top, 1=bottom
        my $depth = $x * $AR;
        # Exponential flux attenuation
        my $flux_ratio = exp(-$depth * sqrt($S));
        push @profile, { position => $x, flux_ratio => $flux_ratio };
    }
    return \@profile;
}

# Boundary layer thickness (cm) — stagnation flow approximation
sub boundary_layer_thickness {
    my ($self, %opts) = @_;
    my $D     = $opts{diffusivity} // 10.0;  # cm²/s
    my $v     = $opts{velocity} // 10.0;     # cm/s
    my $L     = $opts{length} // 15.0;       # cm (wafer radius)
    # δ ≈ sqrt(D × L / v)
    return sqrt($D * $L / $v);
}

# Mass transfer coefficient (cm/s)
sub mass_transfer_coeff {
    my ($self, %opts) = @_;
    my $D     = $opts{diffusivity} // 10.0;
    my $delta = $self->boundary_layer_thickness(%opts);
    return ($delta > 0) ? $D / $delta : 0;
}

# Deposition rate profile across wafer (normalized)
sub wafer_uniformity {
    my ($self, %opts) = @_;
    my $n_pts = $opts{points} // 10;
    my $Da    = $opts{damkohler} // 1.0;

    my @profile;
    for my $i (0 .. $n_pts - 1) {
        my $r = $i / ($n_pts - 1);  # 0=center, 1=edge
        # Depletion effect: rate decreases toward center for Da>1
        my $depletion = exp(-$Da * (1 - $r));
        push @profile, { radius => $r, relative_rate => $depletion };
    }
    return \@profile;
}

# Predict regime: reaction-limited vs transport-limited
sub regime {
    my ($self, %opts) = @_;
    my $Da = $opts{damkohler} // 1.0;
    if ($Da < 0.1) {
        return 'reaction-limited';
    } elsif ($Da > 10) {
        return 'transport-limited';
    } else {
        return 'mixed';
    }
}

sub stats {
    my ($self) = @_;
    return {
        feature_type  => $self->{feature_type},
        aspect_ratio  => $self->{aspect_ratio},
        feature_width => $self->{feature_width},
        D_Kn          => $self->knudsen_diffusivity,
        step_coverage => $self->step_coverage,
    };
}

1;
