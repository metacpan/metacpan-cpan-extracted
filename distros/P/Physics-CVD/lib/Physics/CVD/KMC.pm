package Physics::CVD::KMC;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# KMC engine for CVD surface growth
#
# Models surface processes during CVD:
#   - Precursor adsorption (sticking coefficient model)
#   - Surface decomposition of adsorbed precursors
#   - Surface diffusion of adatoms
#   - Reaction between co-adsorbed species (LH mechanism)
#   - Desorption of byproducts
#   - Film incorporation
#
# Uses deposition-centric BKL algorithm adapted for multi-species CVD.
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB => 1.380649e-23;
use constant EV => 1.602176634e-19;
use constant PI => 3.14159265358979;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        temperature       => $opts{temperature} // 700,
        pressure          => $opts{pressure}    // 100,
        verbose           => $opts{verbose}     // 0,
        lattice_size      => $opts{lattice_size} // [30, 30, 20],
        lattice_const     => $opts{lattice_const} // 3.0,  # Angstrom
        attempt_freq      => $opts{attempt_freq} // 1e13,
        species           => {},
        species_list      => [],
        lattice           => undef,
        surface           => undef,
        site_species      => undef,  # tracks which species at each site
        time              => 0,
        steps             => 0,
        deposited         => 0,
        events            => { adsorption => 0, diffusion => 0, reaction => 0,
                              decomposition => 0, desorption => 0 },
        surface_reactions => [],
    }, $class;

    $self->_init_lattice;
    return $self;
}

sub _init_lattice {
    my ($self) = @_;
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    $self->{lattice}      = [];
    $self->{surface}      = [];
    $self->{site_species} = [];
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            $self->{surface}[$x][$y] = 0;
            for my $z (0 .. $nz-1) {
                $self->{lattice}[$x][$y][$z] = 0;
                $self->{site_species}[$x][$y][$z] = '';
            }
        }
    }
}

sub add_species {
    my ($self, %spec) = @_;
    croak "Species 'name' required" unless $spec{name};
    $self->{species}{$spec{name}} = {
        name              => $spec{name},
        mass              => $spec{mass} // 28,
        sticking_coeff    => $spec{sticking_coeff} // 0.1,
        diffusion_barrier => $spec{diffusion_barrier} // 0.5,  # eV
        desorption_energy => $spec{desorption_energy} // 2.0,  # eV
        decomposition_barrier => $spec{decomposition_barrier} // undef,
        decomp_products   => $spec{decomp_products} // [],
        is_precursor      => $spec{is_precursor} // 0,
        is_byproduct      => $spec{is_byproduct} // 0,
        partial_pressure  => $spec{partial_pressure} // 0,  # Pa
    };
    push @{$self->{species_list}}, $spec{name};
    return $self;
}

# Add surface reaction between co-adsorbed species
sub add_surface_reaction {
    my ($self, %rxn) = @_;
    push @{$self->{surface_reactions}}, {
        reactants => $rxn{reactants},   # ['SiH2', 'O']
        products  => $rxn{products},    # ['SiO2']
        barrier   => $rxn{barrier} // 0.3,  # eV
        name      => $rxn{name} // 'reaction',
    };
    return $self;
}

# Set deposition conditions
sub deposit {
    my ($self, %opts) = @_;
    my $time  = $opts{time}  // 60;
    my $steps = $opts{steps} // undef;

    unless ($steps) {
        # Estimate atoms to deposit from impingement flux
        my ($nx, $ny) = @{$self->{lattice_size}};
        my $area = $nx * $ny * ($self->{lattice_const} * 1e-8)**2;
        my $total_flux = 0;
        for my $sp (values %{$self->{species}}) {
            next unless $sp->{partial_pressure} > 0;
            my $m_kg = $sp->{mass} * 1.66054e-27;
            my $phi = $sp->{partial_pressure} /
                      sqrt(2 * PI() * $m_kg * KB * $self->{temperature});
            $total_flux += $phi * $sp->{sticking_coeff} * $area * 1e-4;
        }
        $steps = int($total_flux * $time + 0.5);
        $steps = max($steps, 100);
    }

    $self->run(steps => $steps);
    return $self;
}

sub _rate {
    my ($self, $barrier_eV) = @_;
    my $T = $self->{temperature};
    return 0 if $T <= 0;
    return $self->{attempt_freq} * exp(-$barrier_eV * EV / (KB * $T));
}

# Run deposition-centric KMC
sub run {
    my ($self, %opts) = @_;
    my $steps = $opts{steps} // 1000;
    my $max_diff = $opts{max_diff_per_dep} // 30;

    croak "No species defined" unless keys %{$self->{species}};

    my ($nx, $ny, $nz) = @{$self->{lattice_size}};
    my $n_sites = $nx * $ny;

    # Compute relative fluxes for each precursor species
    my @precursors;
    my $total_flux = 0;
    for my $name (@{$self->{species_list}}) {
        my $sp = $self->{species}{$name};
        next unless $sp->{partial_pressure} > 0 && !$sp->{is_byproduct};
        my $m_kg = $sp->{mass} * 1.66054e-27;
        my $flux = $sp->{partial_pressure} /
                   sqrt(2 * PI() * $m_kg * KB * $self->{temperature});
        $flux *= $sp->{sticking_coeff};
        push @precursors, { name => $name, flux => $flux };
        $total_flux += $flux;
    }

    croak "No precursors with partial_pressure > 0" unless @precursors;

    # Normalize for weighted random selection
    my @cum_prob;
    my $cum = 0;
    for my $p (@precursors) {
        $cum += $p->{flux} / $total_flux;
        push @cum_prob, $cum;
    }

    # D/F ratio for surface diffusion (use lightest barrier)
    my $min_barrier = min(map { $self->{species}{$_->{name}}{diffusion_barrier} }
                          @precursors);
    my $rate_diff = $self->_rate($min_barrier);
    my $area_per_site = ($self->{lattice_const} * 1e-8)**2;
    my $F_per_site = $total_flux * $area_per_site * 1e-4;
    my $DF_ratio = ($F_per_site > 0) ? $rate_diff / $F_per_site : 0;
    $DF_ratio = min($DF_ratio, $max_diff);

    my $dt_dep = ($F_per_site > 0) ? 1.0 / ($F_per_site * $n_sites) : 1.0;

    printf "  CVD-KMC: Running %d depositions (T=%.0f K, P=%.1f Pa, D/F=%.1f)\n",
           $steps, $self->{temperature}, $self->{pressure}, $DF_ratio
        if $self->{verbose};

    for my $step (1 .. $steps) {
        # 1) Select species to deposit based on relative flux
        my $r = rand();
        my $sp_name = $precursors[-1]{name};
        for my $i (0 .. $#cum_prob) {
            if ($r < $cum_prob[$i]) {
                $sp_name = $precursors[$i]{name};
                last;
            }
        }

        # 2) Adsorb atom
        $self->_event_adsorption($sp_name);

        # 3) Surface diffusion hops
        my $n_hops = int($DF_ratio + 0.5);
        for (1 .. $n_hops) {
            $self->_event_diffusion;
        }

        # 4) Surface decomposition (if precursor has decomp pathway)
        $self->_event_decomposition($sp_name);

        # 5) Surface reactions between co-adsorbed species
        $self->_event_surface_reaction;

        $self->{time} += $dt_dep;
        $self->{steps} += 1 + $n_hops;
    }

    printf "  CVD-KMC: Done. t=%.3e s, deposited=%d atoms\n",
           $self->{time}, $self->{deposited}
        if $self->{verbose};

    return $self;
}

sub _event_adsorption {
    my ($self, $species) = @_;
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};

    my $x = int(rand($nx));
    my $y = int(rand($ny));
    my $z = $self->{surface}[$x][$y];

    return if $z >= $nz;  # column full

    $self->{lattice}[$x][$y][$z] = 1;
    $self->{site_species}[$x][$y][$z] = $species;
    $self->{surface}[$x][$y] = $z + 1;
    $self->{deposited}++;
    $self->{events}{adsorption}++;
}

sub _event_diffusion {
    my ($self) = @_;
    my ($nx, $ny, $nz) = @{$self->{lattice_size}};

    my $x = int(rand($nx));
    my $y = int(rand($ny));
    my $z = $self->{surface}[$x][$y] - 1;
    return if $z < 0;

    # Pick random neighbor
    my @dx = (1, -1, 0, 0);
    my @dy = (0, 0, 1, -1);
    my $dir = int(rand(4));
    my $nx2 = ($x + $dx[$dir]) % $nx;
    my $ny2 = ($y + $dy[$dir]) % $ny;
    my $z_n = $self->{surface}[$nx2][$ny2];

    if ($z_n <= $z) {
        my $sp = $self->{site_species}[$x][$y][$z];
        $self->{lattice}[$x][$y][$z] = 0;
        $self->{site_species}[$x][$y][$z] = '';
        $self->{lattice}[$nx2][$ny2][$z_n] = 1;
        $self->{site_species}[$nx2][$ny2][$z_n] = $sp;
        $self->{surface}[$x][$y] = $z;
        $self->{surface}[$nx2][$ny2] = $z_n + 1;
        $self->{events}{diffusion}++;
    }
}

sub _event_decomposition {
    my ($self, $species) = @_;
    my $sp = $self->{species}{$species};
    return unless $sp->{decomposition_barrier};
    return unless @{$sp->{decomp_products}};

    # Probability of decomposition this step
    my $k = $self->_rate($sp->{decomposition_barrier});
    my $dt = 1.0 / $self->{attempt_freq};  # characteristic time
    return unless rand() < $k * $dt;

    # Find an adsorbed precursor and decompose it
    my ($nx, $ny) = @{$self->{lattice_size}};
    my $x = int(rand($nx));
    my $y = int(rand($ny));
    my $z = $self->{surface}[$x][$y] - 1;
    return if $z < 0;
    return unless $self->{site_species}[$x][$y][$z] eq $species;

    # Replace with first decomposition product (rest desorb as byproducts)
    $self->{site_species}[$x][$y][$z] = $sp->{decomp_products}[0];
    $self->{events}{decomposition}++;
}

sub _event_surface_reaction {
    my ($self) = @_;
    return unless @{$self->{surface_reactions}};

    my ($nx, $ny) = @{$self->{lattice_size}};
    my $x = int(rand($nx));
    my $y = int(rand($ny));
    my $z = $self->{surface}[$x][$y] - 1;
    return if $z < 0;

    my $sp_here = $self->{site_species}[$x][$y][$z];
    return unless $sp_here;

    # Check neighbors for reaction partners
    my @dx = (1, -1, 0, 0);
    my @dy = (0, 0, 1, -1);
    for my $rxn (@{$self->{surface_reactions}}) {
        next unless grep { $_ eq $sp_here } @{$rxn->{reactants}};
        my $partner = (grep { $_ ne $sp_here } @{$rxn->{reactants}})[0];
        next unless $partner;

        # Look for partner in neighbors
        for my $dir (0 .. 3) {
            my $nx2 = ($x + $dx[$dir]) % $nx;
            my $ny2 = ($y + $dy[$dir]) % $ny;
            my $z_n = $self->{surface}[$nx2][$ny2] - 1;
            next if $z_n < 0;
            next unless $self->{site_species}[$nx2][$ny2][$z_n] eq $partner;

            # Reaction probability
            my $k = $self->_rate($rxn->{barrier});
            my $dt = 1.0 / $self->{attempt_freq};
            next unless rand() < $k * $dt;

            # React: convert both to product
            my $product = $rxn->{products}[0] // 'film';
            $self->{site_species}[$x][$y][$z] = $product;
            # Remove partner
            $self->{lattice}[$nx2][$ny2][$z_n] = 0;
            $self->{site_species}[$nx2][$ny2][$z_n] = '';
            $self->{surface}[$nx2][$ny2] = $z_n;
            $self->{events}{reaction}++;
            return;
        }
    }
}

sub get_film {
    my ($self) = @_;
    require Physics::CVD::Film;
    return Physics::CVD::Film->new(
        lattice       => $self->{lattice},
        surface       => $self->{surface},
        site_species  => $self->{site_species},
        lattice_size  => $self->{lattice_size},
        lattice_const => $self->{lattice_const},
    );
}

sub coverage {
    my ($self) = @_;
    my ($nx, $ny) = @{$self->{lattice_size}};
    my $occupied = 0;
    for my $x (0 .. $nx-1) {
        for my $y (0 .. $ny-1) {
            $occupied++ if $self->{surface}[$x][$y] > 0;
        }
    }
    return $occupied / ($nx * $ny);
}

sub stats {
    my ($self) = @_;
    return {
        time      => $self->{time},
        steps     => $self->{steps},
        deposited => $self->{deposited},
        coverage  => $self->coverage,
        events    => { %{$self->{events}} },
    };
}

1;
