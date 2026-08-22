package Physics::Lithography::Pattern;
use strict;
use warnings;
use Carp;
use List::Util qw(max min);

# ═══════════════════════════════════════════════════════════════════════════════
# Pattern transfer fidelity model for laser direct imprint
#
# Models:
#   - Feature resolution limits (thermal diffusion length)
#   - Edge acuity and line edge roughness
#   - Aspect ratio achievable
#   - Multi-pulse patterning (scanning)
#   - Overlay and stitching
#   - Process window (fluence vs feature quality)
# ═══════════════════════════════════════════════════════════════════════════════

use constant PI => 3.14159265358979;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        verbose => $opts{verbose} // 0,
    }, $class;
    return $self;
}

# Minimum feature size from thermal diffusion
# Resolution ≈ max(optical_spot, 2×L_thermal)
sub minimum_feature_size {
    my ($self, %opts) = @_;
    my $spot   = $opts{spot_size} // 5e-6;       # m
    my $kappa  = $opts{diffusivity} // 1e-7;     # m²/s
    my $tau    = $opts{pulse_width} // 10e-9;    # s

    my $L_th = sqrt($kappa * $tau);              # thermal diffusion length
    my $optical_limit = $spot * 0.5;             # ~half the spot size
    my $thermal_limit = 2 * $L_th;

    return {
        thermal_limit_nm => $thermal_limit * 1e9,
        optical_limit_nm => $optical_limit * 1e9,
        minimum_nm       => max($thermal_limit, $optical_limit) * 1e9,
        L_thermal_nm     => $L_th * 1e9,
    };
}

# Edge acuity: sharpness of feature edge (nm)
# Depends on thermal gradient at ablation boundary
sub edge_acuity {
    my ($self, %opts) = @_;
    my $kappa = $opts{diffusivity} // 1e-7;
    my $tau   = $opts{pulse_width} // 10e-9;
    my $alpha = $opts{alpha} // 1e6;             # 1/m

    # Edge width ≈ thermal diffusion length + optical absorption depth
    my $L_th = sqrt($kappa * $tau);
    my $L_abs = 1.0 / $alpha;

    return {
        edge_width_nm => ($L_th + $L_abs) * 1e9,
        thermal_nm    => $L_th * 1e9,
        optical_nm    => $L_abs * 1e9,
    };
}

# Maximum aspect ratio (depth:width) for ablation
sub max_aspect_ratio {
    my ($self, %opts) = @_;
    my $F      = $opts{fluence} // 0.5;
    my $F_th   = $opts{F_threshold} // 0.1;
    my $alpha  = $opts{alpha} // 1e6;
    my $spot   = $opts{spot_size} // 5e-6;

    return 0 if $F <= $F_th;

    # Depth = (1/α) × ln(F/F_th)
    my $depth = log($F / $F_th) / $alpha;
    # Width ≈ 2 × spot × sqrt(ln(F/F_th)/2) for Gaussian
    my $width = 2 * $spot * sqrt(log($F / $F_th) / 2);

    return ($width > 0) ? $depth / $width : 0;
}

# Process window: map of feature quality vs fluence and spot size
sub process_window {
    my ($self, %opts) = @_;
    my $F_min  = $opts{F_min} // 0.05;
    my $F_max  = $opts{F_max} // 2.0;
    my $alpha  = $opts{alpha} // 1e6;
    my $F_th   = $opts{F_threshold} // 0.1;
    my $spot   = $opts{spot_size} // 5e-6;
    my $kappa  = $opts{diffusivity} // 1e-7;
    my $tau    = $opts{pulse_width} // 10e-9;
    my $n_pts  = $opts{points} // 20;

    my @window;
    for my $i (0 .. $n_pts-1) {
        my $F = $F_min * exp(log($F_max/$F_min) * $i / ($n_pts-1));
        my $depth = ($F > $F_th) ? log($F / $F_th) / $alpha * 1e9 : 0;
        my $width = ($F > $F_th)
            ? 2 * $spot * sqrt(log($F / $F_th) / 2) * 1e9 : 0;
        my $L_th = sqrt($kappa * $tau) * 1e9;
        my $quality = ($depth > 0 && $width > 0)
            ? min(1.0, $depth / max($L_th, 1)) * min(1.0, 100 / max($width - $spot*1e9, 1))
            : 0;

        push @window, {
            fluence    => $F,
            depth_nm   => $depth,
            width_nm   => $width,
            quality    => $quality,  # 0-1 figure of merit
        };
    }
    return \@window;
}

# Scanning pattern: pitch and overlap for continuous features
sub scan_parameters {
    my ($self, %opts) = @_;
    my $spot    = $opts{spot_size} // 5e-6;      # m
    my $overlap = $opts{overlap} // 0.5;         # 50% overlap
    my $rep_rate = $opts{rep_rate} // 1000;      # Hz
    my $velocity = $opts{velocity} // undef;     # m/s (auto if undef)

    my $pitch = $spot * (1 - $overlap) * 2;      # distance between pulses
    $velocity //= $pitch * $rep_rate;

    return {
        pitch_um    => $pitch * 1e6,
        velocity_mm_s => $velocity * 1e3,
        throughput_cm2_s => $velocity * $spot * 2 * 1e4,
        dwell_time_ns => 1.0 / $rep_rate * 1e9,
    };
}

# Line pattern: predict line width and depth for scanning
sub line_pattern {
    my ($self, %opts) = @_;
    my $F      = $opts{fluence} // 0.5;
    my $spot   = $opts{spot_size} // 5e-6;
    my $F_th   = $opts{F_threshold} // 0.1;
    my $alpha  = $opts{alpha} // 1e6;
    my $overlap = $opts{overlap} // 0.5;
    my $N_eff  = 1.0 / (1.0 - $overlap);  # effective pulse overlap count

    return { width_nm => 0, depth_nm => 0 } if $F <= $F_th;

    # Width of ablated region
    my $r_abl = $spot * sqrt(log($F / $F_th) / 2);
    my $width = 2 * $r_abl;

    # Depth enhanced by overlap (accumulation)
    my $depth = log($F * $N_eff / $F_th) / $alpha;
    $depth = max($depth, 0);

    return {
        width_nm => $width * 1e9,
        depth_nm => $depth * 1e9,
        aspect_ratio => ($width > 0) ? $depth / $width : 0,
    };
}

# Resolution comparison for different wavelengths/pulsewidths
sub resolution_comparison {
    my ($self, %opts) = @_;
    my @configs = @{$opts{configs} // [
        { name => '355nm/10ns',  wavelength => 355e-9, pulse_width => 10e-9 },
        { name => '248nm/25ns',  wavelength => 248e-9, pulse_width => 25e-9 },
        { name => '355nm/100ps', wavelength => 355e-9, pulse_width => 100e-12 },
        { name => '800nm/100fs', wavelength => 800e-9, pulse_width => 100e-15 },
    ]};
    my $kappa = $opts{diffusivity} // 1e-7;

    my @results;
    for my $cfg (@configs) {
        my $L_th = sqrt($kappa * $cfg->{pulse_width});
        push @results, {
            name => $cfg->{name},
            L_thermal_nm => $L_th * 1e9,
            resolution_nm => 2 * $L_th * 1e9,
        };
    }
    return \@results;
}

1;
