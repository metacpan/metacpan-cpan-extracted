package Physics::CVD::Chemistry;
use strict;
use warnings;
use Carp;
use List::Util qw(sum max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Gas-phase and surface reaction chemistry for CVD
#
# Handles:
#   - Gas-phase decomposition reactions (Arrhenius kinetics)
#   - Surface adsorption/reaction mechanisms (Langmuir-Hinshelwood, Eley-Rideal)
#   - Sticking coefficients (temperature-dependent)
#   - Reaction networks with multiple intermediates
# ═══════════════════════════════════════════════════════════════════════════════

use constant KB => 1.380649e-23;    # J/K
use constant EV => 1.602176634e-19; # J/eV
use constant R_GAS => 8.314462;     # J/(mol·K)
use constant NA => 6.02214076e23;   # /mol

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        temperature    => $opts{temperature} // 700,
        pressure       => $opts{pressure}    // 100,
        verbose        => $opts{verbose}     // 0,
        gas_reactions  => [],
        surface_reactions => [],
        species        => {},
        concentrations => {},
    }, $class;
    return $self;
}

# Add a gas-phase species
sub add_species {
    my ($self, %spec) = @_;
    croak "Species 'name' required" unless $spec{name};
    $self->{species}{$spec{name}} = {
        name     => $spec{name},
        mass     => $spec{mass} // 28,         # amu
        formula  => $spec{formula} // $spec{name},
        type     => $spec{type} // 'gas',      # gas, surface, bulk
    };
    $self->{concentrations}{$spec{name}} = $spec{concentration} // 0;
    return $self;
}

# Add a gas-phase reaction: A -> B + C with Arrhenius kinetics
sub add_gas_reaction {
    my ($self, %rxn) = @_;
    croak "Reactants required" unless $rxn{reactants};
    croak "Products required"  unless $rxn{products};

    push @{$self->{gas_reactions}}, {
        reactants  => $rxn{reactants},      # ['SiH4']
        products   => $rxn{products},       # ['SiH2', 'H2']
        A          => $rxn{A} // 1e13,      # pre-exponential (1/s or cm³/mol·s)
        Ea         => $rxn{Ea} // 1.0,      # activation energy (eV)
        order      => $rxn{order} // 1,     # reaction order
        name       => $rxn{name} // 'unnamed',
    };
    return $self;
}

# Add a surface reaction (Langmuir-Hinshelwood or Eley-Rideal)
sub add_surface_reaction {
    my ($self, %rxn) = @_;
    croak "Reactants required" unless $rxn{reactants};
    croak "Products required"  unless $rxn{products};

    push @{$self->{surface_reactions}}, {
        reactants        => $rxn{reactants},    # ['SiH2(s)', 'O(s)']
        products         => $rxn{products},     # ['SiO2(b)']
        mechanism        => $rxn{mechanism} // 'LH',  # LH or ER
        sticking_coeff   => $rxn{sticking_coeff} // 0.1,
        Ea               => $rxn{Ea} // 0.5,    # eV
        A                => $rxn{A} // 1e13,
        name             => $rxn{name} // 'unnamed',
    };
    return $self;
}

# Compute Arrhenius rate constant k = A × exp(-Ea/kT)
sub rate_constant {
    my ($self, %opts) = @_;
    my $A  = $opts{A}  // 1e13;
    my $Ea = $opts{Ea} // 1.0;    # eV
    my $T  = $opts{T}  // $self->{temperature};
    return $A * exp(-$Ea * EV / (KB * $T));
}

# Compute all gas-phase reaction rates at current conditions
sub gas_rates {
    my ($self) = @_;
    my $T = $self->{temperature};
    my @rates;
    for my $rxn (@{$self->{gas_reactions}}) {
        my $k = $rxn->{A} * exp(-$rxn->{Ea} * EV / (KB * $T));
        # Rate = k × product of reactant concentrations
        my $rate = $k;
        for my $r (@{$rxn->{reactants}}) {
            $rate *= ($self->{concentrations}{$r} // 0) ** $rxn->{order};
        }
        push @rates, { name => $rxn->{name}, rate => $rate, k => $k };
    }
    return \@rates;
}

# Compute surface reaction rates
sub surface_rates {
    my ($self, %opts) = @_;
    my $T = $self->{temperature};
    my $coverage = $opts{coverage} // {};  # surface coverages θᵢ
    my @rates;
    for my $rxn (@{$self->{surface_reactions}}) {
        my $k = $rxn->{A} * exp(-$rxn->{Ea} * EV / (KB * $T));
        my $rate = $k;
        if ($rxn->{mechanism} eq 'LH') {
            # Langmuir-Hinshelwood: rate ∝ θ_A × θ_B
            for my $r (@{$rxn->{reactants}}) {
                $rate *= ($coverage->{$r} // 0);
            }
        } else {
            # Eley-Rideal: rate ∝ P_gas × θ_surface
            $rate *= $rxn->{sticking_coeff};
        }
        push @rates, { name => $rxn->{name}, rate => $rate, k => $k };
    }
    return \@rates;
}

# Hertz-Knudsen flux: impingement rate of gas on surface (molecules/cm²/s)
sub impingement_flux {
    my ($self, %opts) = @_;
    my $P    = $opts{pressure} // $self->{pressure};  # Pa
    my $T    = $opts{T} // $self->{temperature};
    my $mass = $opts{mass} // 28;  # amu
    my $m_kg = $mass * 1.66054e-27;
    # Φ = P / sqrt(2πmkT)
    return $P / sqrt(2.0 * 3.14159265 * $m_kg * KB * $T) * 1e-4;  # /cm²/s
}

# Sticking coefficient with temperature dependence: S(T) = S₀ × exp(-Ea/kT)
sub sticking_coefficient {
    my ($self, %opts) = @_;
    my $S0 = $opts{S0} // 1.0;
    my $Ea = $opts{Ea} // 0;       # eV
    my $T  = $opts{T}  // $self->{temperature};
    return $S0 * exp(-$Ea * EV / (KB * $T));
}

# Integrate gas-phase chemistry over time (simple Euler)
sub evolve {
    my ($self, %opts) = @_;
    my $dt     = $opts{dt} // 1e-6;      # seconds
    my $steps  = $opts{steps} // 1000;
    my $T      = $self->{temperature};

    for my $step (1 .. $steps) {
        for my $rxn (@{$self->{gas_reactions}}) {
            my $k = $rxn->{A} * exp(-$rxn->{Ea} * EV / (KB * $T));
            my $rate = $k;
            for my $r (@{$rxn->{reactants}}) {
                $rate *= ($self->{concentrations}{$r} // 0);
            }
            # Consume reactants, produce products
            for my $r (@{$rxn->{reactants}}) {
                $self->{concentrations}{$r} -= $rate * $dt;
                $self->{concentrations}{$r} = 0
                    if ($self->{concentrations}{$r} // 0) < 0;
            }
            for my $p (@{$rxn->{products}}) {
                $self->{concentrations}{$p} += $rate * $dt;
            }
        }
    }
    return $self;
}

# Set/get concentrations
sub set_concentration {
    my ($self, $species, $conc) = @_;
    $self->{concentrations}{$species} = $conc;
    return $self;
}

sub get_concentration {
    my ($self, $species) = @_;
    return $self->{concentrations}{$species} // 0;
}

sub concentrations { return $_[0]->{concentrations} }

# Growth rate estimate (nm/min) from surface flux and sticking
sub growth_rate {
    my ($self, %opts) = @_;
    my $flux    = $opts{flux} // $self->impingement_flux(%opts);
    my $S       = $opts{sticking} // 0.1;
    my $density = $opts{film_density} // 2.2e22;  # atoms/cm³ (SiO₂)
    my $rate_cm_s = $flux * $S / $density;
    return $rate_cm_s * 1e7 * 60;  # nm/min
}

sub stats {
    my ($self) = @_;
    return {
        n_gas_reactions     => scalar @{$self->{gas_reactions}},
        n_surface_reactions => scalar @{$self->{surface_reactions}},
        n_species           => scalar keys %{$self->{species}},
        temperature         => $self->{temperature},
        pressure            => $self->{pressure},
        concentrations      => { %{$self->{concentrations}} },
    };
}

1;
