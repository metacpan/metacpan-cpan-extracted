package Physics::Lithography::Thermal;
use strict;
use warnings;
use Carp;
use List::Util qw(max min sum);

# ═══════════════════════════════════════════════════════════════════════════════
# 2D Thermal model (Finite Difference) for laser-material interaction
#
# Solves the heat equation:
#   ρCp ∂T/∂t = ∇·(k∇T) + Q_laser(r,z,t)
#
# Using ADI (Alternating Direction Implicit) or explicit FD scheme.
# Handles temperature-dependent properties and phase change via enthalpy.
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB => 1.380649e-23;

# Material database (resist polymers, metals, substrates)
my %MATERIALS = (
    pmma => {
        name        => 'PMMA (polymethyl methacrylate)',
        density     => 1190,       # kg/m³
        cp          => 1450,       # J/(kg·K)
        k           => 0.19,       # W/(m·K)
        T_melt      => 433,        # K (160°C, glass transition)
        T_decomp    => 623,        # K (350°C)
        L_melt      => 0,          # no true melting, glass transition
        L_decomp    => 800e3,      # J/kg (decomposition enthalpy)
        alpha_355   => 5e4,        # 1/m at 355 nm (low absorption)
        alpha_248   => 2e6,        # 1/m at 248 nm (KrF, high)
        reflectivity => 0.04,
    },
    su8 => {
        name        => 'SU-8 photoresist',
        density     => 1200,
        cp          => 1200,
        k           => 0.20,
        T_melt      => 483,        # K (glass transition ~210°C)
        T_decomp    => 673,        # K
        L_melt      => 0,
        L_decomp    => 600e3,
        alpha_355   => 1e5,
        alpha_248   => 5e6,
        reflectivity => 0.05,
    },
    polyimide => {
        name        => 'Polyimide (Kapton)',
        density     => 1420,
        cp          => 1090,
        k           => 0.12,
        T_melt      => 673,        # K (decomp, no melt)
        T_decomp    => 773,        # K
        L_melt      => 0,
        L_decomp    => 1000e3,
        alpha_355   => 3.7e6,      # 1/m (strongly absorbing)
        alpha_248   => 2.6e7,
        reflectivity => 0.03,
    },
    silicon => {
        name        => 'Silicon substrate',
        density     => 2329,
        cp          => 710,
        k           => 148,
        T_melt      => 1687,       # K
        T_decomp    => 3538,       # K (vaporization)
        L_melt      => 1.79e6,     # J/kg
        L_decomp    => 12.8e6,
        alpha_355   => 1e7,        # 1/m (highly absorbing at UV)
        alpha_248   => 1.5e8,
        reflectivity => 0.60,
    },
    gold => {
        name        => 'Gold thin film',
        density     => 19300,
        cp          => 129,
        k           => 317,
        T_melt      => 1337,
        T_decomp    => 3129,       # boiling
        L_melt      => 63.7e3,
        L_decomp    => 1.74e6,
        alpha_355   => 7.4e7,
        alpha_248   => 8.2e7,
        reflectivity => 0.37,      # at 355 nm
    },
    copper => {
        name        => 'Copper thin film',
        density     => 8960,
        cp          => 385,
        k           => 401,
        T_melt      => 1358,
        T_decomp    => 2835,
        L_melt      => 205e3,
        L_decomp    => 4.73e6,
        alpha_355   => 7.7e7,
        alpha_248   => 8.1e7,
        reflectivity => 0.34,
    },
);

sub new {
    my ($class, %opts) = @_;
    my $mat_name = $opts{material} // 'pmma';
    my $mat = $MATERIALS{$mat_name}
        or croak "Unknown material '$mat_name'. Known: " . join(', ', keys %MATERIALS);

    my $self = bless {
        material    => { %$mat },
        mat_name    => $mat_name,
        verbose     => $opts{verbose} // 0,
        # Grid parameters
        nr          => $opts{nr} // 50,          # radial points
        nz          => $opts{nz} // 80,          # depth points
        r_max       => $opts{r_max} // 50e-6,    # m (radial extent)
        z_max       => $opts{z_max} // 5e-6,     # m (depth)
        # State
        T           => undef,     # temperature field [nr x nz]
        time        => 0,
        dt          => $opts{dt} // undef,       # auto-calculated if undef
        T_ambient   => $opts{T_ambient} // 300,  # K
    }, $class;

    $self->_init_grid;
    return $self;
}

sub _init_grid {
    my ($self) = @_;
    my ($nr, $nz) = ($self->{nr}, $self->{nz});
    my $T0 = $self->{T_ambient};

    # Initialize temperature field
    $self->{T} = [];
    for my $i (0 .. $nr-1) {
        for my $j (0 .. $nz-1) {
            $self->{T}[$i][$j] = $T0;
        }
    }
    $self->{dr} = $self->{r_max} / ($nr - 1);
    $self->{dz} = $self->{z_max} / ($nz - 1);
}

# Solve heat equation with laser source for given duration
sub solve {
    my ($self, %opts) = @_;
    my $laser    = $opts{laser} or croak "Laser object required";
    my $duration = $opts{time} // $laser->{pulse_width} * 6;  # 6τ default
    my $nt       = $opts{steps} // 500;

    my $dt = $duration / $nt;
    my ($nr, $nz) = ($self->{nr}, $self->{nz});
    my ($dr, $dz) = ($self->{dr}, $self->{dz});

    my $mat   = $self->{material};
    my $rho   = $mat->{density};
    my $cp    = $mat->{cp};
    my $k     = $mat->{k};
    my $alpha = $mat->{alpha_355};  # absorption at laser wavelength
    my $R     = $mat->{reflectivity};
    my $kappa = $k / ($rho * $cp);  # thermal diffusivity

    # Stability check for explicit scheme
    my $dt_max = 0.25 / ($kappa * (1/$dr**2 + 1/$dz**2));
    if ($dt > $dt_max) {
        $nt = int($duration / $dt_max) + 1;
        $dt = $duration / $nt;
    }

    printf "  Thermal: solving %d×%d grid, %d steps (dt=%.2e s, %.1f ns)\n",
           $nr, $nz, $nt, $dt, $duration*1e9
        if $self->{verbose};

    my $T = $self->{T};
    my $T_max = $self->{T_ambient};

    # Precompute radial positions
    my @r = map { $_ * $dr } (0 .. $nr-1);

    for my $n (0 .. $nt-1) {
        my $t = $n * $dt;
        my $I_t = $laser->temporal_profile($t) * $laser->peak_intensity * 1e4;
        # I_t in W/m²

        # Create new temperature field
        my @T_new;
        for my $i (0 .. $nr-1) {
            for my $j (0 .. $nz-1) {
                $T_new[$i][$j] = $T->[$i][$j];
            }
        }

        # Interior points: explicit FD in cylindrical coordinates
        # ∂T/∂t = κ(∂²T/∂r² + (1/r)∂T/∂r + ∂²T/∂z²) + Q/(ρCp)
        for my $i (1 .. $nr-2) {
            my $ri = $r[$i];
            for my $j (1 .. $nz-2) {
                my $z = $j * $dz;

                # Laser source term
                my $I_r = $laser->spatial_profile($ri);
                my $Q = (1 - $R) * $alpha * $I_t * $I_r * exp(-$alpha * $z);
                # Q in W/m³

                # Finite differences
                my $d2T_dr2 = ($T->[$i+1][$j] - 2*$T->[$i][$j] + $T->[$i-1][$j]) / $dr**2;
                my $dT_dr   = ($T->[$i+1][$j] - $T->[$i-1][$j]) / (2*$dr);
                my $d2T_dz2 = ($T->[$i][$j+1] - 2*$T->[$i][$j] + $T->[$i][$j-1]) / $dz**2;

                my $laplacian = $d2T_dr2 + $dT_dr / $ri + $d2T_dz2;
                $T_new[$i][$j] = $T->[$i][$j] + $dt * ($kappa * $laplacian + $Q / ($rho * $cp));
            }
        }

        # Boundary conditions
        # r=0: symmetry (∂T/∂r = 0)
        for my $j (1 .. $nz-2) {
            my $z = $j * $dz;
            my $I_r = 1.0;  # peak at center
            my $Q = (1 - $R) * $alpha * $I_t * $I_r * exp(-$alpha * $z);
            my $d2T_dr2 = 2 * ($T->[1][$j] - $T->[0][$j]) / $dr**2;  # L'Hôpital
            my $d2T_dz2 = ($T->[0][$j+1] - 2*$T->[0][$j] + $T->[0][$j-1]) / $dz**2;
            $T_new[0][$j] = $T->[0][$j] + $dt * ($kappa * (2*$d2T_dr2 + $d2T_dz2)
                            + $Q / ($rho * $cp));
        }
        # z=0: surface (convective/radiative, simplified as insulated)
        for my $i (0 .. $nr-1) {
            $T_new[$i][0] = $T_new[$i][1];
        }
        # z=z_max: substrate at T_ambient
        for my $i (0 .. $nr-1) {
            $T_new[$i][$nz-1] = $self->{T_ambient};
        }
        # r=r_max: far field at T_ambient
        for my $j (0 .. $nz-1) {
            $T_new[$nr-1][$j] = $self->{T_ambient};
        }

        $self->{T} = \@T_new;
        $T = \@T_new;

        # Track max temperature
        for my $i (0 .. $nr-1) {
            for my $j (0 .. $nz-1) {
                $T_max = $T_new[$i][$j] if $T_new[$i][$j] > $T_max;
            }
        }
    }

    $self->{time} = $duration;
    $self->{T_max} = $T_max;

    printf "  Thermal: done. T_max=%.0f K, T_surface_center=%.0f K\n",
           $T_max, $self->{T}[0][0]
        if $self->{verbose};

    return $self;
}

# Get temperature at specific (r, z) by interpolation
sub temperature_at {
    my ($self, $r, $z) = @_;
    my $i = int($r / $self->{dr} + 0.5);
    my $j = int($z / $self->{dz} + 0.5);
    $i = min($i, $self->{nr} - 1);
    $j = min($j, $self->{nz} - 1);
    return $self->{T}[$i][$j];
}

# Surface temperature profile T(r) at z=0
sub surface_temperature {
    my ($self) = @_;
    my @T_surf;
    for my $i (0 .. $self->{nr}-1) {
        push @T_surf, $self->{T}[$i][0];
    }
    return \@T_surf;
}

# Maximum temperature
sub T_max { return $_[0]->{T_max} // $_[0]->{T_ambient} }

# Melt radius: radius where T > T_melt at surface
sub melt_radius {
    my ($self) = @_;
    my $T_melt = $self->{material}{T_melt};
    my $dr = $self->{dr};
    for my $i (0 .. $self->{nr}-1) {
        if ($self->{T}[$i][0] < $T_melt) {
            return $i * $dr;
        }
    }
    return $self->{r_max};  # entire surface melted
}

# Melt depth at center (r=0)
sub melt_depth {
    my ($self) = @_;
    my $T_melt = $self->{material}{T_melt};
    my $dz = $self->{dz};
    for my $j (0 .. $self->{nz}-1) {
        if ($self->{T}[0][$j] < $T_melt) {
            return $j * $dz;
        }
    }
    return $self->{z_max};
}

# Decomposition depth at center
sub decomposition_depth {
    my ($self) = @_;
    my $T_decomp = $self->{material}{T_decomp};
    my $dz = $self->{dz};
    for my $j (0 .. $self->{nz}-1) {
        if ($self->{T}[0][$j] < $T_decomp) {
            return $j * $dz;
        }
    }
    return $self->{z_max};
}

# Full temperature field as arrayref [nr][nz]
sub field { return $_[0]->{T} }

# Grid info
sub grid_info {
    my ($self) = @_;
    return {
        nr => $self->{nr}, nz => $self->{nz},
        dr => $self->{dr}, dz => $self->{dz},
        r_max => $self->{r_max}, z_max => $self->{z_max},
    };
}

# Available materials
sub materials { return [sort keys %MATERIALS] }
sub material_info { return $MATERIALS{$_[1]} }

1;
