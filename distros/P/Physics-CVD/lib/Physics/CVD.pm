package Physics::CVD;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

# ═══════════════════════════════════════════════════════════════════════════════
# Physics::CVD — Chemical Vapor Deposition Simulation Framework
#
# Provides KMC surface growth, gas-phase chemistry, mass transport modeling,
# and reactor-scale simulation for CVD processes.
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        temperature => $opts{temperature} // 700,   # K
        pressure    => $opts{pressure}    // 100,   # Pa (typ. LPCVD)
        verbose     => $opts{verbose}     // 0,
    }, $class;
    return $self;
}

# Factory methods
sub reactor {
    my ($self, %opts) = @_;
    require Physics::CVD::Reactor;
    $opts{temperature} //= $self->{temperature};
    $opts{pressure}    //= $self->{pressure};
    $opts{verbose}     //= $self->{verbose};
    return Physics::CVD::Reactor->new(%opts);
}

sub chemistry {
    my ($self, %opts) = @_;
    require Physics::CVD::Chemistry;
    $opts{temperature} //= $self->{temperature};
    $opts{pressure}    //= $self->{pressure};
    $opts{verbose}     //= $self->{verbose};
    return Physics::CVD::Chemistry->new(%opts);
}

sub transport {
    my ($self, %opts) = @_;
    require Physics::CVD::Transport;
    $opts{temperature} //= $self->{temperature};
    $opts{pressure}    //= $self->{pressure};
    $opts{verbose}     //= $self->{verbose};
    return Physics::CVD::Transport->new(%opts);
}

sub kmc {
    my ($self, %opts) = @_;
    require Physics::CVD::KMC;
    $opts{temperature} //= $self->{temperature};
    $opts{pressure}    //= $self->{pressure};
    $opts{verbose}     //= $self->{verbose};
    return Physics::CVD::KMC->new(%opts);
}

sub film {
    my ($self, %opts) = @_;
    require Physics::CVD::Film;
    return Physics::CVD::Film->new(%opts);
}

sub interface {
    my ($self, $name, %opts) = @_;
    my %map = (
        openfoam => 'Physics::CVD::Interface::OpenFOAM',
        lammps   => 'Physics::CVD::Interface::LAMMPS',
        cantera  => 'Physics::CVD::Interface::Cantera',
    );
    my $pkg = $map{lc $name} or croak "Unknown interface: $name";
    eval "require $pkg" or croak "Failed to load $pkg: $@";
    return $pkg->new(%opts);
}

sub methods    { return [qw(reactor chemistry transport kmc film)] }
sub interfaces { return [qw(openfoam lammps cantera)] }

1;

__END__

=head1 NAME

Physics::CVD - Chemical Vapor Deposition simulation framework in Perl

=head1 SYNOPSIS

    use Physics::CVD;

    my $cvd = Physics::CVD->new(
        temperature => 700,    # K
        pressure    => 66.5,   # Pa (500 mTorr)
    );

    my $chem = $cvd->chemistry;
    $chem->add_gas_reaction(...);

    my $kmc = $cvd->kmc(lattice_size => [50, 50, 30]);
    $kmc->add_species(name => 'Si', ...);
    $kmc->deposit(time => 60);

=cut
