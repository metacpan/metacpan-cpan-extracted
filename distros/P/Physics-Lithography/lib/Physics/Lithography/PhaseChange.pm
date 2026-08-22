package Physics::Lithography::PhaseChange;
use strict;
use warnings;
use Carp;
use List::Util qw(max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Phase change model (Stefan problem) for laser processing
#
# Tracks melting/solidification front using enthalpy method:
#   - Melt pool geometry and dynamics
#   - Resolidification velocity
#   - Heat affected zone (HAZ)
#   - Crystallization kinetics (for polymers)
# ═══════════════════════════════════════════════════════════════════════════════

use constant PI => 3.14159265358979;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        verbose     => $opts{verbose} // 0,
        # Material phase change properties
        T_melt      => $opts{T_melt} // 433,       # K
        T_vaporize  => $opts{T_vaporize} // 623,    # K
        L_melt      => $opts{L_melt} // 100e3,     # J/kg (latent heat fusion)
        L_vapor     => $opts{L_vapor} // 800e3,    # J/kg (latent heat vaporization)
        density     => $opts{density} // 1200,      # kg/m³
        cp_solid    => $opts{cp_solid} // 1400,     # J/(kg·K)
        cp_liquid   => $opts{cp_liquid} // 1800,    # J/(kg·K)
        k_solid     => $opts{k_solid} // 0.2,       # W/(m·K)
        k_liquid    => $opts{k_liquid} // 0.15,     # W/(m·K)
        # Computed state
        melt_front  => [],
        haz_depth   => 0,
    }, $class;
    return $self;
}

# Compute melt pool from temperature field
sub analyze_melt_pool {
    my ($self, %opts) = @_;
    my $T_field = $opts{temperature} or croak "temperature field required";
    my $dr = $opts{dr} // 1e-6;
    my $dz = $opts{dz} // 1e-7;
    my $T_m = $self->{T_melt};
    my $T_v = $self->{T_vaporize};

    my $nr = scalar @$T_field;
    my $nz = scalar @{$T_field->[0]};

    my $max_r_melt = 0;
    my $max_z_melt = 0;
    my $max_r_vapor = 0;
    my $max_z_vapor = 0;
    my $melt_volume = 0;

    for my $i (0 .. $nr-1) {
        for my $j (0 .. $nz-1) {
            my $T = $T_field->[$i][$j];
            if ($T >= $T_m) {
                $max_r_melt = max($max_r_melt, $i * $dr);
                $max_z_melt = max($max_z_melt, $j * $dz);
                # Approximate volume element (cylindrical)
                my $r = $i * $dr;
                $melt_volume += 2 * PI * max($r, $dr/2) * $dr * $dz;
            }
            if ($T >= $T_v) {
                $max_r_vapor = max($max_r_vapor, $i * $dr);
                $max_z_vapor = max($max_z_vapor, $j * $dz);
            }
        }
    }

    $self->{melt_pool} = {
        radius_um     => $max_r_melt * 1e6,
        depth_um      => $max_z_melt * 1e6,
        volume_um3    => $melt_volume * 1e18,
        vapor_radius_um => $max_r_vapor * 1e6,
        vapor_depth_um  => $max_z_vapor * 1e6,
        aspect_ratio  => ($max_r_melt > 0) ? $max_z_melt / $max_r_melt : 0,
    };
    return $self->{melt_pool};
}

# Estimate resolidification time using Stefan number
sub resolidification_time {
    my ($self, %opts) = @_;
    my $melt_depth = $opts{melt_depth} // 1e-6;  # m
    my $T_super = $opts{T_superheat} // 100;       # K above T_melt

    my $rho = $self->{density};
    my $L   = $self->{L_melt};
    my $k   = $self->{k_solid};
    my $cp  = $self->{cp_solid};
    my $kappa = $k / ($rho * $cp);

    # Stefan number: St = cp × (T_melt - T_ambient) / L
    my $T_ambient = $opts{T_ambient} // 300;
    my $St = $cp * ($self->{T_melt} - $T_ambient) / $L;

    # Resolidification time ≈ d² / (κ × St) for 1D
    return $melt_depth**2 / ($kappa * max($St, 0.01));
}

# Cooling rate at solidification front (K/s)
sub cooling_rate {
    my ($self, %opts) = @_;
    my $v_front = $opts{velocity} // 1.0;  # m/s solidification velocity
    my $G       = $opts{gradient} // 1e8;  # K/m temperature gradient
    return $v_front * $G;
}

# Heat affected zone depth (where T > T_threshold but < T_melt)
sub haz_depth {
    my ($self, %opts) = @_;
    my $T_field   = $opts{temperature} or return 0;
    my $dz        = $opts{dz} // 1e-7;
    my $T_thresh  = $opts{T_threshold} // ($self->{T_melt} * 0.7);  # 70% of T_melt

    my $nz = scalar @{$T_field->[0]};
    for my $j (0 .. $nz-1) {
        if ($T_field->[0][$j] < $T_thresh) {
            $self->{haz_depth} = $j * $dz;
            return $j * $dz;
        }
    }
    return $nz * $dz;
}

# Enthalpy at given temperature (accounts for latent heat)
sub enthalpy {
    my ($self, $T) = @_;
    my $T_m = $self->{T_melt};
    my $T_v = $self->{T_vaporize};
    my $rho = $self->{density};

    if ($T <= $T_m) {
        return $rho * $self->{cp_solid} * $T;
    } elsif ($T <= $T_v) {
        return $rho * ($self->{cp_solid} * $T_m + $self->{L_melt}
               + $self->{cp_liquid} * ($T - $T_m));
    } else {
        return $rho * ($self->{cp_solid} * $T_m + $self->{L_melt}
               + $self->{cp_liquid} * ($T_v - $T_m) + $self->{L_vapor});
    }
}

# Phase state at temperature
sub phase_at {
    my ($self, $T) = @_;
    return 'solid'  if $T < $self->{T_melt};
    return 'liquid' if $T < $self->{T_vaporize};
    return 'vapor';
}

sub melt_pool { return $_[0]->{melt_pool} // {} }

1;
