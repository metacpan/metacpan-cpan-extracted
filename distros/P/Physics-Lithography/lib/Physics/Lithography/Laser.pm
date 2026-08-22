package Physics::Lithography::Laser;
use strict;
use warnings;
use Carp;
use List::Util qw(max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Laser beam and pulse characterization
#
# Models:
#   - Spatial profiles: Gaussian, flat-top, ring (donut)
#   - Temporal profiles: Gaussian pulse, square pulse, modulated
#   - Beer-Lambert absorption in materials
#   - Fluence, intensity, peak power calculations
# ═══════════════════════════════════════════════════════════════════════════════

use constant PI  => 3.14159265358979;
use constant C   => 2.998e8;         # m/s
use constant H   => 6.626e-34;       # J·s

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        wavelength   => $opts{wavelength}  // 355e-9,    # m (UV, 355 nm)
        pulse_width  => $opts{pulse_width} // 10e-9,     # s (10 ns)
        fluence      => $opts{fluence}     // 0.5,       # J/cm²
        spot_size    => $opts{spot_size}   // 5e-6,      # m (1/e² radius)
        rep_rate     => $opts{rep_rate}    // 1000,      # Hz
        profile      => $opts{profile}     // 'gaussian', # spatial
        temporal     => $opts{temporal}    // 'gaussian', # temporal
        verbose      => $opts{verbose}     // 0,
    }, $class;
    return $self;
}

# Peak intensity (W/cm²) for Gaussian pulse
sub peak_intensity {
    my ($self) = @_;
    my $tau = $self->{pulse_width};
    # For Gaussian temporal: I_peak = F / (τ × √(π/2))
    return $self->{fluence} / ($tau * sqrt(PI / 2));
}

# Pulse energy (J)
sub pulse_energy {
    my ($self) = @_;
    my $area = PI * ($self->{spot_size} * 100)**2;  # cm²
    return $self->{fluence} * $area;
}

# Average power (W)
sub average_power {
    my ($self) = @_;
    return $self->pulse_energy * $self->{rep_rate};
}

# Photon energy (eV)
sub photon_energy_eV {
    my ($self) = @_;
    return H * C / $self->{wavelength} / 1.602e-19;
}

# Thermal diffusion length during pulse (m)
sub thermal_diffusion_length {
    my ($self, %opts) = @_;
    my $kappa = $opts{diffusivity} // 1e-7;  # m²/s (typical polymer)
    my $tau = $self->{pulse_width};
    return sqrt($kappa * $tau);
}

# Spatial intensity profile I(r) at given radius (normalized to peak)
sub spatial_profile {
    my ($self, $r) = @_;
    my $w = $self->{spot_size};
    if ($self->{profile} eq 'gaussian') {
        return exp(-2.0 * $r**2 / $w**2);
    } elsif ($self->{profile} eq 'flat_top') {
        return ($r <= $w) ? 1.0 : 0.0;
    } elsif ($self->{profile} eq 'ring') {
        my $r0 = $w * 0.7;
        my $sigma = $w * 0.2;
        return exp(-($r - $r0)**2 / (2 * $sigma**2));
    }
    return 0;
}

# Temporal intensity profile I(t) (normalized to peak)
sub temporal_profile {
    my ($self, $t) = @_;
    my $tau = $self->{pulse_width};
    my $t0 = 3 * $tau;  # center pulse at 3τ
    if ($self->{temporal} eq 'gaussian') {
        return exp(-4 * log(2) * ($t - $t0)**2 / $tau**2);
    } elsif ($self->{temporal} eq 'square') {
        return (abs($t - $t0) <= $tau/2) ? 1.0 : 0.0;
    }
    return 0;
}

# Beer-Lambert absorption profile Q(z) (W/cm³)
# Returns volumetric heat source at depth z
sub absorption_profile {
    my ($self, %opts) = @_;
    my $z     = $opts{z};          # depth (m)
    my $alpha = $opts{alpha};      # absorption coefficient (1/m)
    my $R     = $opts{reflectivity} // 0.05;
    my $I0    = $self->peak_intensity * 1e4;  # W/cm² -> W/m²

    return (1 - $R) * $alpha * $I0 * exp(-$alpha * $z);  # W/m³
}

# Optical penetration depth (m)
sub penetration_depth {
    my ($self, %opts) = @_;
    my $alpha = $opts{alpha} // 1e7;  # 1/m
    return 1.0 / $alpha;
}

# Is the pulse in thermal confinement regime?
sub is_thermal_confinement {
    my ($self, %opts) = @_;
    my $kappa = $opts{diffusivity} // 1e-7;
    my $alpha = $opts{alpha} // 1e7;
    my $tau_th = 1.0 / ($kappa * $alpha**2);  # thermal relaxation time
    return $self->{pulse_width} < $tau_th;
}

# Number of photons per pulse per unit area
sub photon_flux {
    my ($self) = @_;
    my $E_photon = H * C / $self->{wavelength};
    return $self->{fluence} * 1e4 / $E_photon;  # photons/m²
}

sub summary {
    my ($self) = @_;
    return {
        wavelength_nm   => $self->{wavelength} * 1e9,
        pulse_width_ns  => $self->{pulse_width} * 1e9,
        fluence_Jcm2    => $self->{fluence},
        spot_size_um    => $self->{spot_size} * 1e6,
        peak_intensity  => $self->peak_intensity,
        pulse_energy_uJ => $self->pulse_energy * 1e6,
        photon_eV       => $self->photon_energy_eV,
        profile         => $self->{profile},
    };
}

1;
