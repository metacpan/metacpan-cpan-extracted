package Physics::Lithography;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

# ═══════════════════════════════════════════════════════════════════════════════
# Physics::Lithography — Laser Direct Imprint Lithography Simulation
#
# Models laser-matter interaction, thermal transport, ablation, phase change,
# pattern transfer fidelity, and laser-induced forward transfer (LIFT).
# ═══════════════════════════════════════════════════════════════════════════════

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        verbose => $opts{verbose} // 0,
    }, $class;
    return $self;
}

sub laser {
    my ($self, %opts) = @_;
    require Physics::Lithography::Laser;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::Laser->new(%opts);
}

sub thermal {
    my ($self, %opts) = @_;
    require Physics::Lithography::Thermal;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::Thermal->new(%opts);
}

sub ablation {
    my ($self, %opts) = @_;
    require Physics::Lithography::Ablation;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::Ablation->new(%opts);
}

sub phase_change {
    my ($self, %opts) = @_;
    require Physics::Lithography::PhaseChange;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::PhaseChange->new(%opts);
}

sub pattern {
    my ($self, %opts) = @_;
    require Physics::Lithography::Pattern;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::Pattern->new(%opts);
}

sub lift {
    my ($self, %opts) = @_;
    require Physics::Lithography::LIFT;
    $opts{verbose} //= $self->{verbose};
    return Physics::Lithography::LIFT->new(%opts);
}

sub interface {
    my ($self, $name, %opts) = @_;
    my %map = (
        openfoam => 'Physics::Lithography::Interface::OpenFOAM',
        lammps   => 'Physics::Lithography::Interface::LAMMPS',
    );
    my $pkg = $map{lc $name} or croak "Unknown interface: $name";
    eval "require $pkg" or croak "Failed to load $pkg: $@";
    return $pkg->new(%opts);
}

sub methods    { return [qw(laser thermal ablation phase_change pattern lift)] }
sub interfaces { return [qw(openfoam lammps)] }

1;

__END__

=head1 NAME

Physics::Lithography - Laser Direct Imprint Lithography simulation framework

=head1 SYNOPSIS

    use Physics::Lithography;

    my $litho = Physics::Lithography->new(verbose => 1);

    my $laser = $litho->laser(
        wavelength  => 355e-9,    # nm (UV)
        pulse_width => 10e-9,     # 10 ns
        fluence     => 0.5,       # J/cm²
        spot_size   => 5e-6,      # 5 µm
    );

    my $thermal = $litho->thermal(material => 'pmma');
    $thermal->solve(laser => $laser, time => 100e-9);

=cut
