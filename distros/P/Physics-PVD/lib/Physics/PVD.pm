package Physics::PVD;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use Physics::PVD::KMC;
use Physics::PVD::DSMC;
use Physics::PVD::Film;

# Optional interface modules loaded on demand
my %INTERFACES = (
    openfoam   => 'Physics::PVD::Interface::OpenFOAM',
    lammps     => 'Physics::PVD::Interface::LAMMPS',
    quantumatk => 'Physics::PVD::Interface::QuantumATK',
);

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        method      => $opts{method}    // 'kmc',      # kmc | dsmc | hybrid
        temperature => $opts{temperature} // 300,      # K
        pressure    => $opts{pressure}   // 1e-3,      # Pa (base pressure)
        verbose     => $opts{verbose}    // 0,
        seed        => $opts{seed}       // int(rand(2**31)),
        _engines    => {},
        _film       => undef,
    }, $class;

    srand($self->{seed});
    return $self;
}

# Configure simulation parameters
sub configure {
    my ($self, %params) = @_;
    for my $key (keys %params) {
        $self->{$key} = $params{$key};
    }
    return $self;
}

# Get/create the KMC engine
sub kmc {
    my ($self, %opts) = @_;
    unless ($self->{_engines}{kmc}) {
        $self->{_engines}{kmc} = Physics::PVD::KMC->new(
            temperature => $self->{temperature},
            seed        => $self->{seed},
            verbose     => $self->{verbose},
            %opts,
        );
    }
    return $self->{_engines}{kmc};
}

# Get/create the DSMC engine
sub dsmc {
    my ($self, %opts) = @_;
    unless ($self->{_engines}{dsmc}) {
        $self->{_engines}{dsmc} = Physics::PVD::DSMC->new(
            pressure    => $self->{pressure},
            temperature => $self->{temperature},
            seed        => $self->{seed},
            verbose     => $self->{verbose},
            %opts,
        );
    }
    return $self->{_engines}{dsmc};
}

# Get/create the Film object
sub film {
    my ($self, %opts) = @_;
    unless ($self->{_film}) {
        $self->{_film} = Physics::PVD::Film->new(%opts);
    }
    return $self->{_film};
}

# Load and return an interface module
sub interface {
    my ($self, $name, %opts) = @_;
    $name = lc($name);
    croak "Unknown interface '$name'. Available: " . join(', ', sort keys %INTERFACES)
        unless exists $INTERFACES{$name};

    my $module = $INTERFACES{$name};
    eval "require $module" or croak "Failed to load $module: $@";
    return $module->new(%opts);
}

# Run a complete PVD simulation
sub run {
    my ($self, %opts) = @_;
    my $method = $opts{method} // $self->{method};

    if ($method eq 'kmc') {
        return $self->_run_kmc(%opts);
    } elsif ($method eq 'dsmc') {
        return $self->_run_dsmc(%opts);
    } elsif ($method eq 'hybrid') {
        return $self->_run_hybrid(%opts);
    } else {
        croak "Unknown simulation method: $method";
    }
}

sub _run_kmc {
    my ($self, %opts) = @_;
    my $kmc = $self->kmc;
    my $steps = $opts{steps} // 10000;
    my $flux  = $opts{flux}  // 1e14;   # atoms/cm²/s

    $kmc->set_flux($flux) if $flux;
    $kmc->run(steps => $steps);
    $self->{_film} = $kmc->get_film;
    return $self->{_film};
}

sub _run_dsmc {
    my ($self, %opts) = @_;
    my $dsmc = $self->dsmc;
    my $timesteps = $opts{timesteps} // 5000;

    $dsmc->run(timesteps => $timesteps);
    return $dsmc->get_flux_distribution;
}

sub _run_hybrid {
    my ($self, %opts) = @_;
    # Hybrid: DSMC for transport → KMC for film growth
    my $flux_dist = $self->_run_dsmc(%opts);
    my $kmc = $self->kmc;
    $kmc->set_angular_distribution($flux_dist);
    return $self->_run_kmc(%opts);
}

# Convenience: list available methods
sub available_methods { return qw(kmc dsmc hybrid); }

# Convenience: list available interfaces
sub available_interfaces { return sort keys %INTERFACES; }

1;

__END__

=head1 NAME

Physics::PVD - Physical Vapor Deposition simulation framework

=head1 SYNOPSIS

    use Physics::PVD;

    my $pvd = Physics::PVD->new(
        method      => 'kmc',
        temperature => 600,   # K
        pressure    => 5e-3,  # Pa
    );

    # Configure and run KMC film growth
    my $kmc = $pvd->kmc(lattice_size => [100, 100, 50]);
    $kmc->add_species(name => 'Ta', mass => 180.95, binding_energy => 8.1);
    $kmc->deposit(flux => 1e14, time => 60, angle => 0);

    # Get results
    my $film = $kmc->get_film;
    printf "Thickness: %.1f nm\n", $film->thickness;
    printf "Roughness: %.2f nm\n", $film->roughness;

=head1 DESCRIPTION

Physics::PVD provides a Perl framework for simulating Physical Vapor
Deposition processes using Kinetic Monte Carlo (kMC) for atomistic film
growth and Direct Simulation Monte Carlo (DSMC) for vapor transport.

Optional interfaces to OpenFOAM, LAMMPS, and QuantumATK enable advanced
multi-scale simulations.

=cut
