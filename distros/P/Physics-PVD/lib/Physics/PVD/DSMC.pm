package Physics::PVD::DSMC;
use strict;
use warnings;
use Carp;
use POSIX qw(floor ceil acos);
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Direct Simulation Monte Carlo for PVD vapor transport
#
# Simulates the kinetic transport of sputtered atoms from target to substrate
# through a background gas (typically Ar). Models:
#   - Free molecular flow (high vacuum, Kn >> 1)
#   - Transitional regime (Kn ~ 1) with gas-phase collisions
#   - Thompson energy distribution of sputtered atoms
#   - Cosine^n angular distribution from target
#   - Gas-phase scattering and thermalization
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB    => 1.380649e-23;     # J/K
use constant AMU   => 1.66053906660e-27; # kg
use constant PI    => 3.14159265358979;
use constant EV    => 1.602176634e-19;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        # Domain geometry (2D axisymmetric or 3D)
        domain       => $opts{domain}    // [0.1, 0.1, 0.05],  # [width, depth, height] in meters
        n_cells      => $opts{n_cells}   // [50, 50, 25],      # grid cells
        dimensions   => $opts{dimensions} // 3,                  # 2 or 3

        # Gas properties
        gas_species   => $opts{gas_species}   // 'Ar',
        gas_mass      => $opts{gas_mass}      // 39.948,  # amu
        gas_pressure  => $opts{pressure}      // 1.0,     # Pa
        gas_temperature => $opts{temperature} // 300,     # K

        # Target properties
        target_material => $opts{target_material} // 'Ta',
        target_mass     => $opts{target_mass}     // 180.95, # amu
        target_position => $opts{target_position} // 'top',  # top | bottom | left
        target_diameter => $opts{target_diameter} // 0.05,   # m

        # Sputtering parameters
        sputter_yield   => $opts{sputter_yield}  // 1.0,
        surface_binding => $opts{surface_binding} // 8.1,   # eV (Ta)
        cosine_power    => $opts{cosine_power}   // 1,      # cos^n emission

        # Substrate
        substrate_position => $opts{substrate_position} // 'bottom',
        substrate_distance => $opts{substrate_distance} // 0.04,  # m from target

        # DSMC parameters
        n_particles     => $opts{n_particles}   // 10000,
        dt              => $opts{dt}            // 1e-7,     # time step (s)
        n_real_per_sim  => $opts{n_real_per_sim} // 1e10,    # real atoms per sim particle
        max_collisions  => $opts{max_collisions} // 5,

        # Cross-section model
        sigma_ref => $opts{sigma_ref} // 3.0e-19,  # reference cross-section (m²)

        # Simulation state
        particles => [],       # [{x,y,z,vx,vy,vz,species,energy,active}]
        flux_map  => undef,    # 2D flux distribution on substrate
        energy_dist => [],     # energy distribution of arriving atoms
        angular_dist => [],    # angular distribution

        time      => 0,
        seed      => $opts{seed} // int(rand(2**31)),
        verbose   => $opts{verbose} // 0,
    }, $class;

    srand($self->{seed});
    $self->_init_flux_map;
    return $self;
}

sub _init_flux_map {
    my ($self) = @_;
    my ($ncx, $ncy) = @{$self->{n_cells}}[0, 1];
    $self->{flux_map} = [];
    for my $i (0 .. $ncx-1) {
        $self->{flux_map}[$i] = [(0) x $ncy];
    }
}

# Set background gas parameters
sub set_gas {
    my ($self, %opts) = @_;
    $self->{gas_species}     = $opts{species}     if exists $opts{species};
    $self->{gas_mass}        = $opts{mass}        if exists $opts{mass};
    $self->{gas_pressure}    = $opts{pressure}    if exists $opts{pressure};
    $self->{gas_temperature} = $opts{temperature} if exists $opts{temperature};
    return $self;
}

# Set target parameters
sub set_target {
    my ($self, %opts) = @_;
    $self->{target_material}  = $opts{material}       if exists $opts{material};
    $self->{target_mass}      = $opts{mass}           if exists $opts{mass};
    $self->{surface_binding}  = $opts{surface_binding} if exists $opts{surface_binding};
    $self->{sputter_yield}    = $opts{yield}          if exists $opts{yield};
    $self->{cosine_power}     = $opts{cosine_power}   if exists $opts{cosine_power};
    $self->{target_diameter}  = $opts{diameter}       if exists $opts{diameter};
    return $self;
}

# Set substrate parameters
sub set_substrate {
    my ($self, %opts) = @_;
    $self->{substrate_position} = $opts{position} if exists $opts{position};
    $self->{substrate_distance} = $opts{distance} if exists $opts{distance};
    return $self;
}

# Generate sputtered atom with Thompson energy distribution
# P(E) ∝ E / (E + E_b)^3   where E_b = surface binding energy
sub _thompson_energy {
    my ($self) = @_;
    my $Eb = $self->{surface_binding};  # eV
    # Inverse CDF sampling for Thompson distribution
    my $u = rand();
    # Approximation: E = Eb × u / (1 - u)^(1/2)
    my $E = $Eb * $u / (1.0 - $u + 1e-10)**0.5;
    # Clamp to reasonable range (0 to 10× binding energy)
    $E = min($E, 10.0 * $Eb);
    return $E;
}

# Generate emission direction with cos^n distribution
sub _cosine_emission {
    my ($self) = @_;
    my $n = $self->{cosine_power};
    # Polar angle: P(θ) ∝ cos^n(θ) sin(θ)
    # CDF inversion: θ = acos(rand^(1/(n+1)))
    my $cos_theta = rand()**(1.0 / ($n + 1));
    my $sin_theta = sqrt(1.0 - $cos_theta**2);
    # Azimuthal angle: uniform
    my $phi = 2.0 * PI * rand();

    return ($sin_theta * cos($phi), $sin_theta * sin($phi), -$cos_theta);
}

# Initialize a batch of sputtered particles
sub _emit_particles {
    my ($self, $n) = @_;
    $n //= $self->{n_particles};

    my $mass_kg = $self->{target_mass} * AMU;
    my $td = $self->{target_diameter};

    for my $i (1 .. $n) {
        # Random position on circular target
        my $r = $td/2 * sqrt(rand());
        my $phi = 2 * PI * rand();
        my $px = $r * cos($phi) + $self->{domain}[0]/2;
        my $py = $r * sin($phi) + $self->{domain}[1]/2;
        my $pz = $self->{domain}[2];  # top of domain

        # Energy and velocity
        my $E_eV = $self->_thompson_energy;
        my $speed = sqrt(2.0 * $E_eV * EV / $mass_kg);  # m/s

        my ($dx, $dy, $dz) = $self->_cosine_emission;
        my ($vx, $vy, $vz) = ($speed * $dx, $speed * $dy, $speed * $dz);

        push @{$self->{particles}}, {
            x => $px, y => $py, z => $pz,
            vx => $vx, vy => $vy, vz => $vz,
            species => $self->{target_material},
            energy  => $E_eV,
            active  => 1,
        };
    }
}

# Check collision probability with background gas (null-collision method)
sub _collide {
    my ($self, $p) = @_;
    my $gas_n = $self->{gas_pressure} / (KB * $self->{gas_temperature});  # number density
    my $v_rel = sqrt($p->{vx}**2 + $p->{vy}**2 + $p->{vz}**2);

    my $P_coll = $gas_n * $self->{sigma_ref} * $v_rel * $self->{dt};
    $P_coll = min($P_coll, 0.5);  # cap

    if (rand() < $P_coll) {
        # Hard-sphere collision with background gas atom
        my $m1 = $self->{target_mass};
        my $m2 = $self->{gas_mass};
        my $mu = $m1 * $m2 / ($m1 + $m2);  # reduced mass ratio

        # Isotropic scattering in center-of-mass frame
        my $cos_chi = 1.0 - 2.0 * rand();
        my $sin_chi = sqrt(1.0 - $cos_chi**2);
        my $phi = 2.0 * PI * rand();

        # Energy transfer fraction
        my $frac = 2.0 * $mu / $m1 * (1.0 - $cos_chi);
        my $speed = sqrt($p->{vx}**2 + $p->{vy}**2 + $p->{vz}**2);
        my $new_speed = $speed * sqrt(1.0 - $frac);

        # New random direction (isotropic post-collision in lab frame approx)
        my $theta = acos(1.0 - 2.0 * rand());
        my $phi2 = 2.0 * PI * rand();
        $p->{vx} = $new_speed * sin($theta) * cos($phi2);
        $p->{vy} = $new_speed * sin($theta) * sin($phi2);
        $p->{vz} = $new_speed * cos($theta);
        $p->{energy} *= (1.0 - $frac);
    }
}

# Main DSMC time-stepping loop
sub run {
    my ($self, %opts) = @_;
    my $timesteps = $opts{timesteps} // 5000;

    # Emit initial particle batch
    $self->_emit_particles;

    printf "  DSMC: Running %d timesteps (%d particles, P=%.1f Pa)\n",
           $timesteps, scalar(@{$self->{particles}}), $self->{gas_pressure}
        if $self->{verbose};

    my ($ncx, $ncy) = @{$self->{n_cells}}[0, 1];
    my ($Lx, $Ly, $Lz) = @{$self->{domain}};
    my $arrived = 0;

    for my $step (1 .. $timesteps) {
        for my $p (@{$self->{particles}}) {
            next unless $p->{active};

            # Move particle
            $p->{x} += $p->{vx} * $self->{dt};
            $p->{y} += $p->{vy} * $self->{dt};
            $p->{z} += $p->{vz} * $self->{dt};

            # Periodic boundaries in x, y
            $p->{x} = $p->{x} - $Lx * floor($p->{x} / $Lx) if $p->{x} < 0 || $p->{x} >= $Lx;
            $p->{y} = $p->{y} - $Ly * floor($p->{y} / $Ly) if $p->{y} < 0 || $p->{y} >= $Ly;

            # Check substrate arrival (z <= 0)
            if ($p->{z} <= 0) {
                $p->{active} = 0;
                $arrived++;
                # Record on flux map
                my $ix = min(floor($p->{x} / $Lx * $ncx), $ncx - 1);
                my $iy = min(floor($p->{y} / $Ly * $ncy), $ncy - 1);
                $ix = max($ix, 0);
                $iy = max($iy, 0);
                $self->{flux_map}[$ix][$iy]++;

                # Record energy and angle
                my $vz = abs($p->{vz}) + 1e-30;
                my $vt = sqrt($p->{vx}**2 + $p->{vy}**2);
                push @{$self->{energy_dist}}, $p->{energy};
                push @{$self->{angular_dist}}, atan2($vt, $vz) * 180 / PI;
                next;
            }

            # Check if escaped from top/sides
            if ($p->{z} > $Lz) {
                $p->{active} = 0;
                next;
            }

            # Gas-phase collisions
            $self->_collide($p);
        }

        $self->{time} += $self->{dt};
    }

    printf "  DSMC: Done. %d/%d particles arrived at substrate\n",
           $arrived, scalar(@{$self->{particles}})
        if $self->{verbose};

    return $self;
}

# Get 2D flux distribution on substrate
sub get_flux_distribution {
    my ($self) = @_;
    return $self->{flux_map};
}

# Get energy distribution of arriving atoms
sub get_energy_distribution {
    my ($self) = @_;
    return $self->{energy_dist};
}

# Get angular distribution of arriving atoms
sub get_angular_distribution {
    my ($self) = @_;
    return $self->{angular_dist};
}

# Get mean energy of arriving atoms
sub mean_arrival_energy {
    my ($self) = @_;
    my @e = @{$self->{energy_dist}};
    return 0 unless @e;
    return sum(@e) / scalar(@e);
}

# Get Knudsen number for the system
sub knudsen_number {
    my ($self) = @_;
    my $gas_n = $self->{gas_pressure} / (KB * $self->{gas_temperature});
    my $mfp = 1.0 / (sqrt(2) * $gas_n * $self->{sigma_ref});
    return $mfp / $self->{substrate_distance};
}

# Get simulation statistics
sub stats {
    my ($self) = @_;
    my @active = grep { $_->{active} } @{$self->{particles}};
    my @arrived = grep { !$_->{active} && $_->{z} <= 0 } @{$self->{particles}};
    return {
        total_particles => scalar(@{$self->{particles}}),
        arrived         => scalar(@arrived),
        still_flying    => scalar(@active),
        mean_energy_eV  => $self->mean_arrival_energy,
        knudsen_number  => $self->knudsen_number,
        time            => $self->{time},
    };
}

1;

__END__

=head1 NAME

Physics::PVD::DSMC - Direct Simulation Monte Carlo for PVD vapor transport

=head1 DESCRIPTION

Simulates the kinetic transport of sputtered atoms through a background gas
from target to substrate. Handles free-molecular, transitional, and
continuum flow regimes. Models Thompson energy distribution, cosine^n
angular emission, and gas-phase scattering.

=cut
