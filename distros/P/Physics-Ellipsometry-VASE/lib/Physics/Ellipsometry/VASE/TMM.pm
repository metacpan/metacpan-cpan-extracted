package Physics::Ellipsometry::VASE::TMM;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Exporter 'import';

our @EXPORT_OK = qw(tmm_reflect psi_delta tmm_graded tmm_interface);

our $VERSION = '1.03';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::TMM - Transfer Matrix Method for multilayer
thin film optics

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::TMM qw(tmm_reflect psi_delta
                                          tmm_graded tmm_interface);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);

    my $lambda = sequence(500) * 2 + 300;   # 300–1298 nm
    my $theta  = ones($lambda) * 70;        # 70° incidence

    # --- Single-layer example: SiO2 on Si ---

    # Ambient (air)
    my $N_air = ones($lambda) + i() * zeroes($lambda);

    # SiO2 film (Cauchy model, transparent)
    my ($n_sio2, $k_sio2) = cauchy_nk($lambda, 1.46, 0.003, 0.0);
    my $N_sio2 = $n_sio2 + i() * $k_sio2;

    # Si substrate (tabulated values, simplified here)
    my $N_si = 3.87 * ones($lambda) + i() * 0.02 * ones($lambda);

    my ($psi, $delta) = psi_delta(
        $lambda, $theta,
        [ $N_air, $N_sio2, $N_si ],   # media: ambient, film, substrate
        [ 100.0 ],                     # thickness: 100 nm SiO2
    );

    print "Psi range:   ", $psi->min,  " – ", $psi->max,  " deg\n";
    print "Delta range: ", $delta->min, " – ", $delta->max, " deg\n";

    # --- Raw reflection coefficients ---
    my ($rp, $rs) = tmm_reflect(
        $lambda, $theta,
        [ $N_air, $N_sio2, $N_si ],
        [ 100.0 ],
    );
    my $reflectance_s = abs($rs)**2;
    my $reflectance_p = abs($rp)**2;

=head1 DESCRIPTION

Implements the 2×2 transfer matrix method (TMM) for computing the
optical response of planar multilayer thin-film stacks.  This is the
standard algorithm used in spectroscopic ellipsometry to predict
Psi (Ψ) and Delta (Δ) from a physical model of the sample.

=head2 Physical background

When polarised light reflects from a surface, the B<p>-polarised
(parallel to the plane of incidence) and B<s>-polarised (perpendicular)
components experience different amplitude and phase changes described by
the complex Fresnel reflection coefficients C<rp> and C<rs>.

Ellipsometry measures the ratio

    ρ = rp / rs = tan(Ψ) · exp(iΔ)

For a simple ambient/substrate interface the Fresnel equations give
C<rp> and C<rs> directly.  When one or more thin films are present,
multiple reflections within each layer create interference effects that
modify the overall reflection.  The transfer matrix method handles
this systematically by representing each layer as a 2×2 matrix and
multiplying them together.

=head2 Algorithm

For a stack of N media (ambient = 0, layers 1..N-2, substrate = N-1):

=over 4

=item 1.

B<Snell's law> determines the complex propagation angle in each layer:

    N_0 · sin(θ_0) = N_j · sin(θ_j)    for all j

=item 2.

B<Fresnel coefficients> are calculated at every interface for both
polarisations.

=item 3.

Starting from the deepest interface (last layer → substrate), the
B<Airy formula> recursively combines each interface reflection with
the phase accumulated traversing the layer:

    r = (r_ij + r_below · e^{+2iβ}) / (1 + r_ij · r_below · e^{+2iβ})

where β = (2π/λ) · N_j · d_j · cos(θ_j) is the single-pass phase
thickness of layer j.

=item 4.

The final C<rp> and C<rs> at the ambient surface give Ψ and Δ.

=back

=head1 CONVENTIONS

=over 4

=item B<Phase convention>

Physics sign convention: e^{−iωt} time dependence, producing
e^{+2iβ} phase accumulation for forward propagation through a layer.

=item B<Fresnel rp (Verdet convention)>

    rp = (N_f · cosθ_i − N_i · cosθ_f) / (N_f · cosθ_i + N_i · cosθ_f)

This convention yields Δ ≈ 180° for bare dielectrics at moderate angles,
consistent with WVASE® and most modern ellipsometry software.

=item B<Fresnel rs>

    rs = (N_i · cosθ_i − N_f · cosθ_f) / (N_i · cosθ_i + N_f · cosθ_f)

=item B<Delta mapping>

    Δ = −arg(ρ)   mapped to [0°, 360°)

matching the convention used in WVASE® and RefEllips.

=back

=head1 FUNCTIONS

=head2 tmm_reflect

    my ($rp, $rs) = tmm_reflect($lambda_nm, $theta_deg,
                                \@N_layers, \@d_nm);

Calculates the complex Fresnel reflection coefficients for a complete
multilayer stack.

Arguments:

=over 4

=item C<$lambda_nm>

PDL piddle of wavelengths in nanometres (npts elements).

=item C<$theta_deg>

PDL piddle of angles of incidence in degrees (same size as C<$lambda_nm>).

=item C<\@N_layers>

Arrayref of complex refractive index piddles C<[N_0, N_1, ..., N_s]>,
one per medium.  C<N_0> is the ambient (usually air, n=1) and C<N_s> is
the substrate.  Each piddle must have the same length as C<$lambda_nm>.

=item C<\@d_nm>

Arrayref of layer thicknesses in nanometres C<[d_1, d_2, ..., d_{s-1}]>.
There is no thickness entry for the ambient or the substrate (semi-infinite
half-spaces), so this array has two fewer elements than C<\@N_layers>.

=back

Returns a list C<($rp, $rs)> of complex PDL piddles.

    # Two-layer stack: SiO2 (100 nm) + Ta2O5 (50 nm) on Si
    my ($rp, $rs) = tmm_reflect($lambda, $theta,
        [ $N_air, $N_ta2o5, $N_sio2, $N_si ],
        [ 50.0, 100.0 ],
    );

=head2 psi_delta

    my ($psi, $delta) = psi_delta($lambda_nm, $theta_deg,
                                  \@N_layers, \@d_nm,
                                  delta_ref => $ref_delta);

Convenience wrapper around L</tmm_reflect> that returns the ellipsometric
angles Ψ and Δ in degrees.

    Ψ = atan( |ρ| )          in [0°, 90°]
    Δ = −arg(ρ)              in [0°, 360°)

The optional C<delta_ref> parameter provides a reference Δ piddle; the
calculated Δ is shifted by multiples of 360° to minimise the distance
to the reference, avoiding discontinuities at the 0°/360° boundary
during fitting.

Returns a list C<($psi_deg, $delta_deg)> of real PDL piddles.

    # Multi-angle measurement
    my @angles = (65, 70, 75);
    for my $ang (@angles) {
        my $theta = ones($lambda) * $ang;
        my ($psi, $delta) = psi_delta(
            $lambda, $theta,
            [ $N_air, $N_film, $N_sub ],
            [ $thickness ],
        );
        printf "Angle %d: Psi(500nm)=%.2f  Delta(500nm)=%.2f\n",
               $ang, $psi->at(100), $delta->at(100);
    }

=head2 tmm_graded

    my ($rp, $rs) = tmm_graded($lambda_nm, $theta_deg,
                                $N_ambient, $N_substrate,
                                $n_func, $d_total,
                                n_slices => 20);

Models a B<graded layer> whose optical constants vary continuously with
depth.  The layer is discretized into C<n_slices> sublayers, each with
uniform optical constants evaluated at the sublayer midpoint.

This approach handles:

=over 4

=item - Composition gradients (e.g., SiO2 transitioning to Si3N4)

=item - Thermal diffusion profiles

=item - Ion-implanted layers with depth-dependent damage

=back

B<Parameters:>

=over 4

=item C<$n_func> - coderef C<sub($lambda, $z_frac)> returning complex N at
fractional depth z (0 = top, 1 = bottom)

=item C<$d_total> - total graded layer thickness [nm]

=item C<n_slices> - number of sublayers (default 20; increase for accuracy)

=back

B<Example:>

    use Physics::Ellipsometry::VASE::TMM qw(tmm_graded);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);

    # Linear gradient from SiO2 (n=1.46) to Si3N4 (n=2.0)
    my $grad_func = sub {
        my ($lambda, $z) = @_;
        my $n = 1.46 + 0.54 * $z;  # linear gradient
        return pdl($n) + i() * pdl(0);
    };

    my $lambda = sequence(100) * 10 + 300;
    my ($rp, $rs) = tmm_graded($lambda, pdl(70),
        pdl(1.0)+i()*pdl(0),       # air ambient
        pdl(3.94)+i()*pdl(0.02),   # Si substrate
        $grad_func, 200,           # 200 nm graded layer
        n_slices => 30,
    );

=head2 tmm_interface

    my ($rp, $rs) = tmm_interface($lambda_nm, $theta_deg,
                                   $N_ambient, $N_substrate,
                                   $N_a, $N_b, $d_interface,
                                   n_slices => 10,
                                   ema_model => 'bruggeman');

Models a thin B<interface layer> (interlayer) between two materials
using an EMA-graded profile.  The composition varies linearly from
100% material A at the top to 100% material B at the bottom.

B<Physical motivation:> Real interfaces are rarely atomically sharp.
Interdiffusion, roughness, and reaction products create a transition
region that is better modeled as a graded interlayer than as an
abrupt boundary.

B<Parameters:>

=over 4

=item C<$N_a>, C<$N_b> - complex refractive indices of the two materials
forming the interface

=item C<$d_interface> - interface thickness [nm]

=item C<ema_model> - mixing rule: 'bruggeman' (default), 'linear', or 'looyenga'

=item C<n_slices> - number of sublayers (default 10)

=back

B<Example:>

    use Physics::Ellipsometry::VASE::TMM qw(tmm_interface);

    my $lambda = sequence(100) * 10 + 300;

    # Model a 3 nm Si/SiO2 interface transition
    my ($rp, $rs) = tmm_interface($lambda, pdl(70),
        pdl(1.0)+i()*pdl(0),       # ambient
        pdl(3.94)+i()*pdl(0.02),   # Si substrate
        pdl(1.46)+i()*pdl(0),      # SiO2 side
        pdl(3.94)+i()*pdl(0.02),   # Si side
        3.0,                       # 3 nm interface
        ema_model => 'bruggeman',
    );

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::Dispersion>,
L<Physics::Ellipsometry::VASE::Materials>,
L<Physics::Ellipsometry::VASE::EMA>

H. Fujiwara, I<Spectroscopic Ellipsometry: Principles and Applications>,
John Wiley E<amp> Sons, 2007, Chapter 3.

R.M.A. Azzam and N.M. Bashara, I<Ellipsometry and Polarized Light>,
North-Holland, 1987.

=cut

# Calculate reflection coefficients for a multilayer stack
# Input:
#   $lambda_nm - wavelength piddle (npts)
#   $theta_deg - angle of incidence piddle (npts), in degrees
#   $N_layers  - arrayref of complex refractive index piddles [N0, N1, ..., Ns]
#                N0 = ambient, Ns = substrate
#   $d_nm      - arrayref of layer thicknesses in nm [d1, d2, ..., d_{s-1}]
#                (no thickness for ambient or substrate)
# Returns: ($rp, $rs) complex reflection coefficients
sub tmm_reflect {
    my ($lambda_nm, $theta_deg, $N_layers, $d_nm) = @_;

    my $n_media = scalar @$N_layers;  # number of media (ambient + layers + substrate)
    die "Need at least 2 media (ambient + substrate)" if $n_media < 2;
    die "Need exactly N-2 thicknesses" if scalar @$d_nm != $n_media - 2;

    my $theta_rad = $theta_deg * (PI / 180.0);
    my $cos_t0 = cos($theta_rad);
    my $sin_t0 = sin($theta_rad);
    my $N0 = $N_layers->[0];

    # Calculate cos(θ) in each layer via Snell's law
    my @cos_t;
    push @cos_t, $cos_t0;
    for my $j (1 .. $n_media - 1) {
        my $Nj = $N_layers->[$j];
        $cos_t[$j] = sqrt(1.0 - ($N0 * $sin_t0)**2 / $Nj**2);
    }

    # Build system by nested Airy formula (back-to-front)
    # Start from the deepest interface and propagate backward
    my $last = $n_media - 1;

    # Fresnel coefficients at last interface (layer n-2 → substrate)
    my $rs = _fresnel_s($N_layers->[$last-1], $N_layers->[$last],
                        $cos_t[$last-1], $cos_t[$last]);
    my $rp = _fresnel_p($N_layers->[$last-1], $N_layers->[$last],
                        $cos_t[$last-1], $cos_t[$last]);

    # Propagate backward through each layer
    for (my $j = $last - 2; $j >= 0; $j--) {
        # Phase thickness of layer j+1
        my $d = $d_nm->[$j];  # thickness of layer j+1 (0-indexed in d_nm)
        my $beta = (2 * PI / $lambda_nm) * $N_layers->[$j+1] * $d * $cos_t[$j+1];

        # Fresnel at interface j → j+1
        my $r_s_ij = _fresnel_s($N_layers->[$j], $N_layers->[$j+1],
                                $cos_t[$j], $cos_t[$j+1]);
        my $r_p_ij = _fresnel_p($N_layers->[$j], $N_layers->[$j+1],
                                $cos_t[$j], $cos_t[$j+1]);

        # Airy formula: r = (r_ij + r_below·e^{+2iβ}) / (1 + r_ij·r_below·e^{+2iβ})
        my $phase = exp(2.0 * i() * $beta);
        $rs = ($r_s_ij + $rs * $phase) / (1.0 + $r_s_ij * $rs * $phase);
        $rp = ($r_p_ij + $rp * $phase) / (1.0 + $r_p_ij * $rp * $phase);
    }

    return ($rp, $rs);
}

# Calculate Psi and Delta from a layer stack
# Returns: ($psi_deg, $delta_deg) with Delta in [0, 360)
sub psi_delta {
    my ($lambda_nm, $theta_deg, $N_layers, $d_nm, %opts) = @_;

    my ($rp, $rs) = tmm_reflect($lambda_nm, $theta_deg, $N_layers, $d_nm);

    my $rho = $rp / $rs;
    my $psi = atan(abs($rho)) * (180.0 / PI);

    # Delta = -arg(ρ) mapped to [0°, 360°)
    my $delta_rad = -carg($rho)->re;
    $delta_rad += 2*PI * ($delta_rad < 0);
    my $delta = $delta_rad * (180.0 / PI);

    # Optionally align to reference data (avoid 0/360 wrap)
    if (my $delta_ref = $opts{delta_ref}) {
        my $diff = $delta - $delta_ref;
        $delta -= 360.0 * rint($diff / 360.0);
    }

    return ($psi->re->double, $delta->double);
}

# Fresnel s-polarization: rs = (Ni·cosθi - Nf·cosθf) / (Ni·cosθi + Nf·cosθf)
sub _fresnel_s {
    my ($Ni, $Nf, $cos_ti, $cos_tf) = @_;
    return ($Ni*$cos_ti - $Nf*$cos_tf) / ($Ni*$cos_ti + $Nf*$cos_tf);
}

# Fresnel p-polarization (Verdet): rp = (Nf·cosθi - Ni·cosθf) / (Nf·cosθi + Ni·cosθf)
sub _fresnel_p {
    my ($Ni, $Nf, $cos_ti, $cos_tf) = @_;
    return ($Nf*$cos_ti - $Ni*$cos_tf) / ($Nf*$cos_ti + $Ni*$cos_tf);
}

# Graded layer: slices a single layer with position-dependent optical
# constants into N sublayers and computes TMM for the full stack.
# $n_func: coderef ($lambda, $z_frac) -> complex N at fractional depth z
# $d_total: total layer thickness [nm]
# $n_slices: number of sublayers (default 20)
# $N_ambient, $N_substrate: complex refractive indices of bounding media
sub tmm_graded {
    my ($lambda_nm, $theta_deg, $N_ambient, $N_substrate,
        $n_func, $d_total, %opts) = @_;
    my $n_slices = $opts{n_slices} // 20;

    my $d_slice = $d_total / $n_slices;

    # Build layer stack: [ambient, slice_1, ..., slice_N, substrate]
    my @N_layers = ($N_ambient);
    my @d_nm;

    for my $i (0 .. $n_slices - 1) {
        my $z_frac = ($i + 0.5) / $n_slices;  # midpoint of sublayer
        my $N_slice = &$n_func($lambda_nm, $z_frac);
        push @N_layers, $N_slice;
        push @d_nm, $d_slice;
    }
    push @N_layers, $N_substrate;

    return tmm_reflect($lambda_nm, $theta_deg, \@N_layers, \@d_nm);
}

# Interface layer model: models a thin intermixed region between two
# materials using EMA. Creates a layer with linearly graded composition
# from material A to material B.
# $N_a, $N_b: complex N of materials above and below the interface
# $d_interface: interface thickness [nm]
# $ema_model: mixing rule ('bruggeman', 'linear', 'looyenga'), default 'bruggeman'
# $n_slices: number of sublayers to represent the grading
sub tmm_interface {
    my ($lambda_nm, $theta_deg, $N_ambient, $N_substrate,
        $N_a, $N_b, $d_interface, %opts) = @_;
    my $n_slices = $opts{n_slices} // 10;
    my $ema_model = $opts{ema_model} // 'bruggeman';

    require Physics::Ellipsometry::VASE::EMA;

    my $d_slice = $d_interface / $n_slices;
    my @N_layers = ($N_ambient);
    my @d_nm;

    # Convert N to epsilon for EMA
    my $eps_a = $N_a**2;
    my $eps_b = $N_b**2;

    for my $i (0 .. $n_slices - 1) {
        my $vf = ($i + 0.5) / $n_slices;  # fraction of material B

        my $eps_eff;
        if ($ema_model eq 'bruggeman') {
            $eps_eff = Physics::Ellipsometry::VASE::EMA::ema_bruggeman($eps_a, $eps_b, $vf);
        } elsif ($ema_model eq 'looyenga') {
            $eps_eff = Physics::Ellipsometry::VASE::EMA::ema_looyenga($eps_a, $eps_b, $vf);
        } else {
            $eps_eff = Physics::Ellipsometry::VASE::EMA::ema_linear($eps_a, $eps_b, $vf);
        }

        push @N_layers, sqrt($eps_eff);
        push @d_nm, $d_slice;
    }
    push @N_layers, $N_substrate;

    return tmm_reflect($lambda_nm, $theta_deg, \@N_layers, \@d_nm);
}

1;
