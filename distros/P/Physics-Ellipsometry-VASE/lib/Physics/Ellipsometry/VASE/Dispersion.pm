package Physics::Ellipsometry::VASE::Dispersion;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Exporter 'import';

our @EXPORT_OK = qw(cauchy_nk sellmeier_nk tauc_lorentz_nk drude_nk genosc_nk
                    drude_lorentz_nk forouhi_bloomer_nk cody_lorentz_nk
                    critical_point_nk gaussian_nk bspline_nk);

our $VERSION = '1.03';

=head1 NAME

Physics::Ellipsometry::VASE::Dispersion - Optical dispersion models for
spectroscopic ellipsometry

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::Dispersion qw(
        cauchy_nk sellmeier_nk tauc_lorentz_nk drude_nk genosc_nk
        drude_lorentz_nk forouhi_bloomer_nk cody_lorentz_nk
        critical_point_nk gaussian_nk bspline_nk
    );

    my $lambda = sequence(500) * 2 + 300;   # 300-1298 nm

    # Transparent dielectric (SiO2-like)
    my ($n, $k) = cauchy_nk($lambda, 1.45, 0.003, 0.0);

    # Semiconductor with band gap (Ta2O5-like)
    my ($n2, $k2) = tauc_lorentz_nk($lambda, 100, 4.0, 1.0, 3.5, 1.0);

    # Metal with interband transitions (Au-like)
    my ($n3, $k3) = drude_lorentz_nk($lambda, 6.9, 9.03, 0.053,
        [ [1.3, 2.68, 0.51], [1.0, 3.87, 1.12] ]);

    # Crystalline semiconductor (Si critical points)
    my ($n4, $k4) = critical_point_nk($lambda, [
        { C=>6, E=>3.38, Gamma=>0.08, phi=>-1.2, mu=>0 },
    ], 1.0);

=head1 DESCRIPTION

Implements the standard parametric dispersion models used in spectroscopic
ellipsometry to describe the wavelength-dependent complex refractive index
N = n + ik of thin films and substrates.

The complex refractive index relates to the dielectric function through

    N = sqrt(epsilon)    where epsilon = epsilon_1 + i*epsilon_2

The real part B<n> (refractive index) governs the phase velocity of light
in the material.  The imaginary part B<k> (extinction coefficient)
describes optical absorption; k=0 for a perfectly transparent material.

All functions accept wavelength in nanometres and return a pair of PDL
piddles C<($n, $k)>.

B<Note:> Functions are called directly (not via closures) to avoid
PDL::NiceSlice source filter conflicts with the C<< $ref->() >> syntax.

=head1 FUNCTIONS

=head2 cauchy_nk

    my ($n, $k) = cauchy_nk($lambda_nm, $A, $B, $C,
                            k_amp => $k_amp, k_exp => $k_exp);

The B<Cauchy model> is an empirical dispersion formula suitable for
transparent or weakly absorbing dielectrics in the visible and near-IR.
The refractive index is expressed as a power series in inverse
wavelength-squared:

    n(lambda) = A + B/lambda^2 + C/lambda^4

where lambda is in micrometres.  Parameters B and C are in units of
um^2 and um^4, respectively.

When C<k_amp> is set, an B<Urbach absorption tail> is added:

    k(lambda) = k_amp * exp( k_exp * (1/lambda - 1/0.4) )

modelling the exponential increase in absorption near the band edge.
If C<k_amp> is zero (the default) the material is treated as fully
transparent (k = 0).

B<Typical use:> SiO2, Al2O3, MgF2, polymer films.

    # SiO2 in the visible
    my ($n, $k) = cauchy_nk($lambda, 1.45, 0.003, 0.0);

    # Polymer with weak UV absorption tail
    my ($n, $k) = cauchy_nk($lambda, 1.50, 0.005, 0.0,
                            k_amp => 0.01, k_exp => 2.0);

=head2 sellmeier_nk

    my ($n, $k) = sellmeier_nk($lambda_nm, \@B_terms, \@C_terms);

The B<Sellmeier equation> is derived from a classical harmonic-oscillator
model of the dielectric response.  Each resonance contributes a term to
the squared refractive index:

    n^2(lambda) = 1 + sum_i  B_i * lambda^2 / (lambda^2 - C_i)

where lambda is in micrometres.  C<C_i> values (um^2) locate the
resonance wavelengths (lambda_i = sqrt(C_i)), and C<B_i> values are the
oscillator strengths.  The model is valid away from the resonances and
does not predict absorption (k = 0).

B<Typical use:> Optical glasses (BK7, fused silica), crystals (CaF2,
sapphire), infrared windows.

    # BK7 glass (Schott catalogue coefficients)
    my ($n, $k) = sellmeier_nk($lambda,
        [1.0396, 0.2318, 1.0105],     # B terms
        [0.00600, 0.02002, 103.56],   # C terms (um^2)
    );

=head2 tauc_lorentz_nk

    my ($n, $k) = tauc_lorentz_nk($lambda_nm, $A, $E0, $Gamma, $Eg,
                                   $eps_inf);

The B<Tauc-Lorentz model> (Jellison E<amp> Modine, I<Appl. Phys. Lett.>
B<69>, 371, 1996) is widely used for amorphous semiconductors and
dielectrics.  It combines the Tauc joint density of states with a
Lorentz oscillator to give the imaginary dielectric function:

    epsilon_2(E) = [ A * E0 * Gamma * (E - Eg)^2 ]
                   / [ (E^2 - E0^2)^2 + Gamma^2 * E^2 ] / E
                   for E > Eg;   0 otherwise

The real part epsilon_1 is obtained through a B<numerical Kramers-Kronig>
integration to ensure the model is physically self-consistent (causal).

Parameters:

=over 4

=item C<$A> - oscillator amplitude (eV)

=item C<$E0> - peak transition energy (eV)

=item C<$Gamma> - oscillator broadening (eV)

=item C<$Eg> - optical band gap energy (eV); epsilon_2 = 0 below this energy

=item C<$eps_inf> - high-frequency dielectric constant (accounts for higher-energy transitions)

=back

B<Typical use:> Ta2O5, SiNx, TiO2, a-Si, amorphous oxides.

    # Ta2O5 thin film
    my ($n, $k) = tauc_lorentz_nk($lambda, 100, 4.5, 1.2, 3.8, 1.0);

    # Amorphous silicon
    my ($n, $k) = tauc_lorentz_nk($lambda, 200, 3.4, 2.5, 1.2, 1.0);

=head2 drude_nk

    my ($n, $k) = drude_nk($lambda_nm, $eps_inf, $omega_p, $gamma);

The B<Drude free-electron model> describes optical properties of metals
and heavily doped semiconductors.  Free carriers produce a dielectric
response:

    epsilon(E) = eps_inf - omega_p^2 / (E^2 + i * E * gamma)

where C<omega_p> is the plasma frequency (eV) and C<gamma> is the
carrier scattering rate (eV).  Below the plasma frequency the real part
of epsilon goes negative, producing the high reflectivity characteristic
of metals.

B<Typical use:> Au, Ag, Al, Cu, ITO, doped ZnO.

    # Gold (simplified)
    my ($n, $k) = drude_nk($lambda, 1.0, 9.0, 0.07);

    # ITO (transparent conductor)
    my ($n, $k) = drude_nk($lambda, 3.8, 1.5, 0.12);

=head2 genosc_nk

    my ($n, $k) = genosc_nk($lambda_nm, \@oscillators, $eps_inf);

The B<general oscillator> (GenOsc) model sums multiple Lorentz
oscillators to build an arbitrary dielectric function:

    epsilon(E) = eps_inf + sum_i  A_i * E0_i^2
                                  / (E0_i^2 - E^2 - i * Gamma_i * E)

Each oscillator is specified as C<[A, E0, Gamma]> (amplitude, centre
energy in eV, broadening in eV).  This is the most flexible built-in
model and can approximate complex band structures with multiple
absorption features.

B<Typical use:> Compound semiconductors, organic films, metamaterials,
any material with multiple absorption bands.

    # Two-oscillator model for a compound semiconductor
    my ($n, $k) = genosc_nk($lambda,
        [ [80, 3.5, 0.5], [40, 5.0, 1.0] ],   # oscillators
        1.5,                                     # eps_inf
    );

=head1 ENERGY-WAVELENGTH CONVERSION

Several models (Tauc-Lorentz, Drude, GenOsc) work internally in photon
energy.  The conversion used is:

    E (eV) = 1239.842 / lambda (nm)

Parameters for these models (E0, Eg, Gamma, omega_p) are in eV, while
the input wavelength and returned n, k are in nm.

=head2 drude_lorentz_nk

    my ($n, $k) = drude_lorentz_nk($lambda_nm, $eps_inf, $omega_p,
                                    $gamma_d, $oscillators);

The B<Drude-Lorentz hybrid> combines free-carrier (Drude) response with
bound-electron (Lorentz) interband transitions.  The dielectric function is:

    epsilon(E) = eps_inf - omega_p^2/(E^2 + i*E*Gamma_d)
                 + sum_j A_j*E0_j^2 / (E0_j^2 - E^2 - i*Gamma_j*E)

The first term describes metallic free carriers (plasma frequency C<omega_p>,
damping C<gamma_d>).  The oscillator terms model interband absorption peaks.

B<Parameters:>

=over 4

=item C<$eps_inf> - high-frequency dielectric constant (default 1.0)

=item C<$omega_p> - plasma frequency [eV] (default 9.0)

=item C<$gamma_d> - Drude damping rate [eV] (default 0.05)

=item C<$oscillators> - arrayref of [A, E0, Gamma] for interband peaks

=back

B<Typical use:> Noble metals (Au, Ag, Cu), transparent conducting oxides
(ITO, ZnO:Al), transition metals.

    # Gold: Drude + 2 interband transitions
    my ($n, $k) = drude_lorentz_nk($lambda,
        6.9,              # eps_inf
        9.03,             # omega_p [eV]
        0.053,            # Drude damping [eV]
        [ [1.3, 2.68, 0.51],     # L1 interband
          [1.0, 3.87, 1.12] ],   # L2 interband
    );

    # ITO (transparent conductor)
    my ($n, $k) = drude_lorentz_nk($lambda,
        3.8, 1.8, 0.12,          # lower omega_p than pure metal
        [ [0.5, 4.2, 0.8] ],     # UV absorption
    );

=head2 forouhi_bloomer_nk

    my ($n, $k) = forouhi_bloomer_nk($lambda_nm, \%params);

The B<Forouhi-Bloomer model> (1986, 1988) provides an analytic form for both
k(E) and n(E) in amorphous semiconductors and dielectrics.  Unlike
Tauc-Lorentz, the refractive index is derived analytically from
Kramers-Kronig without numerical integration:

    k(E) = A*(E - Eg)^2 / (E^2 - B*E + C)    for E > Eg
    n(E) = n_inf + (B0*E + C0) / (E^2 - B*E + C)

where B0 and C0 are derived analytically from A, B, C, and Eg.

B<Parameters (as hashref):>

=over 4

=item C<A> - absorption strength (default 0.5)

=item C<B> - peak energy parameter [eV] (default 6.0)

=item C<C> - peak width parameter [eV^2] (default 10.0); must satisfy 4C > B^2

=item C<Eg> - optical bandgap [eV] (default 1.5)

=item C<n_inf> - refractive index at infinite energy (default 1.5)

=back

B<Typical use:> a-Si:H, a-SiN, a-SiO2, amorphous carbon.

    # Amorphous silicon
    my ($n, $k) = forouhi_bloomer_nk($lambda, {
        A => 0.76, B => 7.53, C => 14.6,
        Eg => 1.12, n_inf => 2.03,
    });

=head2 cody_lorentz_nk

    my ($n, $k) = cody_lorentz_nk($lambda_nm,
        A => $A, E0 => $E0, Gamma => $Gamma,
        Eg => $Eg, Ep => $Ep, Eu => $Eu,
        eps_inf => $eps_inf);

The B<Cody-Lorentz model> (Ferlauto et al., 2002) extends the Tauc-Lorentz
model with two improvements:

=over 4

=item 1. Replaces the Tauc absorption onset with the Cody form, which
better describes the near-gap absorption in amorphous materials.

=item 2. Adds an exponential Urbach tail below the band edge to model
disorder-induced sub-gap absorption.

=back

The imaginary dielectric function:

    eps2(E) = G*L(E) * (E-Eg)^2 / ((E-Eg)^2 + Ep^2)   for E > Et
    eps2(E) = eps2(Et) * exp((E - Et)/Eu)                for Eg < E <= Et

where Et = Eg + Ep is the transition energy, G = A*E0*Gamma, and
L(E) is the Lorentz oscillator.

B<Parameters:>

=over 4

=item C<A> - amplitude [eV] (default 100)

=item C<E0> - resonance energy [eV] (default 4.0)

=item C<Gamma> - broadening [eV] (default 1.0)

=item C<Eg> - Cody optical gap [eV] (default 1.5)

=item C<Ep> - transition energy width [eV] (default 1.0)

=item C<Eu> - Urbach energy [eV] (default 0.05)

=item C<eps_inf> - high-frequency offset (default 1.0)

=back

B<Typical use:> a-Si:H, amorphous chalcogenides (GeSbTe), polymer films.

    # a-Si:H with Urbach tail
    my ($n, $k) = cody_lorentz_nk($lambda,
        A => 200, E0 => 3.6, Gamma => 2.5,
        Eg => 1.7, Ep => 0.8, Eu => 0.05,
        eps_inf => 1.0,
    );

=head2 critical_point_nk

    my ($n, $k) = critical_point_nk($lambda_nm, \@critical_points, $eps_inf);

The B<Critical Point model> (Adachi, 1987; Kim et al., 1992) describes the
dielectric function of crystalline semiconductors near van Hove
singularities (critical points in the joint density of states):

    epsilon(E) = eps_inf + sum_j C_j*exp(i*phi_j)*(E - E_j + i*Gamma_j)^(-mu_j)

The exponent C<mu> determines the type of critical point:

=over 4

=item mu = 0.5 - 3D M0 (band edge, e.g., E0 of GaAs)

=item mu = -0.5 - 3D M1 (saddle point)

=item mu = 0 - 2D (logarithmic singularity, e.g., E1 of Si)

=back

B<Parameters:>

Each critical point is a hashref with keys:

=over 4

=item C<C> - amplitude

=item C<E> - critical point energy [eV]

=item C<Gamma> - broadening [eV]

=item C<phi> - phase angle [radians]

=item C<mu> - exponent (0.5, -0.5, or 0)

=back

B<Typical use:> c-Si, GaAs, InP, Ge, III-V semiconductors.

    # Crystalline silicon (E1, E2 critical points)
    my ($n, $k) = critical_point_nk($lambda, [
        { C => 6.0,  E => 3.38, Gamma => 0.08, phi => -1.2, mu => 0 },    # E1
        { C => 3.0,  E => 3.62, Gamma => 0.12, phi => -0.8, mu => 0 },    # E1'
        { C => 20.0, E => 4.27, Gamma => 0.05, phi => -0.3, mu => 0.5 },  # E2
    ], 1.0);

=head2 gaussian_nk

    my ($n, $k) = gaussian_nk($lambda_nm, \@oscillators, $eps_inf);

B<Gaussian oscillators> model absorption peaks with a Gaussian line shape
instead of the Lorentzian used in C<genosc_nk>.  Gaussian profiles provide
better fits for inhomogeneously broadened transitions (e.g., amorphous
materials, organic films):

    eps2(E) = sum_j A_j * [ exp(-((E-E0j)/sigma_j)^2)
                          - exp(-((E+E0j)/sigma_j)^2) ]

where sigma_j = Gamma_j / (2*sqrt(ln 2)) is the standard deviation
(Gamma_j is the FWHM).  eps1 is obtained by numerical Kramers-Kronig
transformation.

B<Parameters:>

=over 4

=item C<$oscillators> - arrayref of [A, E0, Gamma] triplets

=item C<$eps_inf> - high-frequency dielectric constant (default 1.0)

=back

B<Typical use:> Organic semiconductors, polymers, dye films, biological
thin films, inhomogeneously broadened systems.

    # Organic semiconductor with two absorption bands
    my ($n, $k) = gaussian_nk($lambda, [
        [3.0, 2.8, 0.4],    # HOMO-LUMO transition
        [1.5, 4.5, 0.8],    # higher excited state
    ], 2.5);

=head2 bspline_nk

    my ($n, $k) = bspline_nk($lambda_nm, \@knots, \@coeffs, $eps_inf);

B<B-spline parameterization> provides a model-free (non-parametric)
description of the imaginary dielectric function eps2(E) using cubic
B-spline basis functions.  The real part eps1(E) is derived from
numerical Kramers-Kronig to ensure causality.

This approach is useful when:

=over 4

=item - No physical model adequately describes the material

=item - You need maximum flexibility for exploratory fitting

=item - The material has complex spectral features (multiple overlapping peaks)

=back

B<Parameters:>

=over 4

=item C<$knots> - arrayref of energy knot positions [eV] (must be sorted)

=item C<$coeffs> - arrayref of B-spline coefficients (non-negative for physical eps2)

=item C<$eps_inf> - eps1 offset (default 1.0)

=back

B<Typical use:> Unknown materials, complex alloys, metamaterials.

    # 7 knots spanning 1-6 eV with an absorption peak near 4 eV
    my ($n, $k) = bspline_nk($lambda,
        [1.0, 2.0, 3.0, 4.0, 5.0, 5.5, 6.0],   # knots
        [0.0, 0.1, 0.5, 2.0, 1.0, 0.3, 0.0],   # coefficients
        2.0,                                      # eps_inf
    );

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::TMM>,
L<Physics::Ellipsometry::VASE::Materials>

G.E. Jellison and F.A. Modine, "Parameterization of the optical functions
of amorphous materials in the interband region", I<Appl. Phys. Lett.>
B<69>, 371 (1996).

H. Fujiwara, I<Spectroscopic Ellipsometry: Principles and Applications>,
John Wiley E<amp> Sons, 2007, Chapters 5-6.

=cut

# Cauchy dispersion: n(λ) = A + B/λ² + C/λ⁴, k=0 (or Urbach tail)
# $lambda in nm, B in µm², C in µm⁴
sub cauchy_nk {
    my ($lambda_nm, $A, $B, $C, %opts) = @_;
    $A //= 2.0;
    $B //= 0.01;
    $C //= 0.0;
    my $k_amp = $opts{k_amp} // 0;
    my $k_exp = $opts{k_exp} // 0;

    my $lam_um = $lambda_nm / 1000.0;
    my $n = $A + $B / $lam_um**2 + $C / $lam_um**4;
    my $k;
    if ($k_amp > 0) {
        $k = $k_amp * exp($k_exp * (1.0/$lam_um - 1.0/0.4));
    } else {
        $k = zeroes($lambda_nm);
    }
    return ($n, $k);
}

# Sellmeier dispersion: n²(λ) = 1 + Σ Bᵢλ²/(λ² - Cᵢ)
# $B_terms, $C_terms are arrayrefs; C in µm²
sub sellmeier_nk {
    my ($lambda_nm, $B_terms, $C_terms) = @_;
    $B_terms //= [1.0];
    $C_terms //= [0.01];

    my $lam_um_sq = ($lambda_nm / 1000.0)**2;
    my $n_sq = ones($lambda_nm) + 0.0;
    for my $i (0 .. $#$B_terms) {
        $n_sq += $B_terms->[$i] * $lam_um_sq / ($lam_um_sq - $C_terms->[$i]);
    }
    $n_sq = $n_sq->clip(0.01, 1e6);
    my $n = sqrt($n_sq);
    my $k = zeroes($lambda_nm);
    return ($n, $k);
}

# Tauc-Lorentz dispersion (Jellison & Modine, 1996)
sub tauc_lorentz_nk {
    my ($lambda_nm, $A, $E0, $Gamma, $Eg, $eps_inf) = @_;
    $A       //= 100;
    $E0      //= 4.0;
    $Gamma   //= 1.0;
    $Eg      //= 3.5;
    $eps_inf //= 1.0;

    my $E = 1239.842 / $lambda_nm;

    # ε₂(E): Tauc-Lorentz imaginary part
    my $eps2 = zeroes($lambda_nm);
    my $above_gap = which($E > $Eg);
    if ($above_gap->nelem > 0) {
        my $Ea = $E->index($above_gap);
        my $numer = $A * $E0 * $Gamma * ($Ea - $Eg)**2;
        my $denom = (($Ea**2 - $E0**2)**2 + $Gamma**2 * $Ea**2) * $Ea;
        $eps2->index($above_gap) .= $numer / $denom;
    }

    # ε₁(E): numerical Kramers-Kronig
    my $eps1 = _kk_transform($E, $eps2) + $eps_inf;

    my $eps = $eps1 + i() * $eps2;
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Drude model for metals: ε(E) = ε_inf - ωp²/(E² + iEΓ)
sub drude_nk {
    my ($lambda_nm, $eps_inf, $omega_p, $gamma) = @_;
    $eps_inf //= 1.0;
    $omega_p //= 10.0;
    $gamma   //= 0.1;

    my $E = 1239.842 / $lambda_nm;
    my $eps = $eps_inf - $omega_p**2 / ($E**2 + i() * $E * $gamma);
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# General oscillator: sum of Lorentz oscillators
# $oscillators: arrayref of [A, E0, Gamma] triplets
sub genosc_nk {
    my ($lambda_nm, $oscillators, $eps_inf) = @_;
    $oscillators //= [];
    $eps_inf //= 1.0;

    my $E = 1239.842 / $lambda_nm;
    my $eps = ones($lambda_nm) * $eps_inf + i() * zeroes($lambda_nm);

    for my $osc (@$oscillators) {
        my ($Ai, $E0i, $Gi) = @$osc;
        $eps += $Ai * $E0i**2 / ($E0i**2 - $E**2 - i() * $Gi * $E);
    }

    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Numerical Kramers-Kronig transform
sub _kk_transform {
    my ($E, $eps2) = @_;
    my $npts = $E->nelem;
    my $eps1 = zeroes($npts);

    for my $j (0 .. $npts - 1) {
        my $Ej = $E->at($j);
        my $mask = abs($E - $Ej) > 0.001;
        my $idx = which($mask);
        next if $idx->nelem < 2;
        my $E_prime = $E->index($idx);
        my $eps2_p  = $eps2->index($idx);
        my $integrand = $E_prime * $eps2_p / ($E_prime**2 - $Ej**2);
        my $dE = $E_prime->(1:) - $E_prime->(0:-2);
        my $avg = ($integrand->(1:) + $integrand->(0:-2)) / 2;
        $eps1->set($j, (2.0 / PI) * sum($dE * $avg)->sclr);
    }
    return $eps1;
}

# Drude-Lorentz hybrid: Drude free-electron + Lorentz interband oscillators
# Combines metallic free-carrier response with bound-electron transitions
sub drude_lorentz_nk {
    my ($lambda_nm, $eps_inf, $omega_p, $gamma_d, $oscillators) = @_;
    $eps_inf     //= 1.0;
    $omega_p     //= 9.0;     # plasma frequency [eV]
    $gamma_d     //= 0.05;    # Drude damping [eV]
    $oscillators //= [];      # arrayref of [A, E0, Gamma] for interband

    my $E = 1239.842 / $lambda_nm;

    # Drude (intraband free carriers)
    my $eps = $eps_inf * ones($lambda_nm) - $omega_p**2 / ($E**2 + i() * $E * $gamma_d);

    # Lorentz oscillators (interband transitions)
    for my $osc (@$oscillators) {
        my ($Ai, $E0i, $Gi) = @$osc;
        $eps += $Ai * $E0i**2 / ($E0i**2 - $E**2 - i() * $Gi * $E);
    }

    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Forouhi-Bloomer model (1986, 1988)
# For amorphous semiconductors and dielectrics
# k(E) = A(E-Eg)^2 / (E^2 - BE + C)  for E > Eg, else 0
# n(E) = n_inf + (B0*E + C0) / (E^2 - BE + C)
# where B0 and C0 are derived from A, B, C, Eg via KK analytically
sub forouhi_bloomer_nk {
    my ($lambda_nm, $params) = @_;
    $params //= {};
    my $A      = $params->{A}      // 0.5;
    my $B      = $params->{B}      // 6.0;
    my $C      = $params->{C}      // 10.0;
    my $Eg     = $params->{Eg}     // 1.5;
    my $n_inf  = $params->{n_inf}  // 1.5;

    my $E = 1239.842 / $lambda_nm;

    # Extinction coefficient
    my $k = zeroes($lambda_nm);
    my $above = which($E > $Eg);
    if ($above->nelem > 0) {
        my $Ea = $E->index($above);
        $k->index($above) .= $A * ($Ea - $Eg)**2 / ($Ea**2 - $B * $Ea + $C);
    }
    $k = $k->clip(0, 1e6);

    # Analytic KK-derived refractive index
    my $Q = sqrt(4 * $C - $B**2) / 2.0;
    my $B0 = $A / $Q * (-$B**2 / 2 + $Eg * $B - $Eg**2 + $C);
    my $C0 = $A / $Q * (($B**2 / 2 - $C) * $Eg + $B * $C / 2 - $Eg**2 * $B / 2);

    my $n = $n_inf + ($B0 * $E + $C0) / ($E**2 - $B * $E + $C);

    return ($n, $k);
}

# Cody-Lorentz model (Ferlauto et al., J. Appl. Phys. 92, 2424, 2002)
# Improved Tauc-Lorentz: adds Urbach tail below gap + Cody absorption shape
# eps2(E) = (E1/E) * exp((E - Et)/Eu)                    for E <= Et
# eps2(E) = (G * (E - Eg)^2) / ((E^2 - E0^2)^2 + G^2*E^2) * (E - Eg)^2 / E  for E > Et
# G = A*E0*Gamma, Et = transition energy, Eu = Urbach energy
sub cody_lorentz_nk {
    my ($lambda_nm, %params) = @_;
    my $A       = $params{A}       // 100;
    my $E0      = $params{E0}      // 4.0;
    my $Gamma   = $params{Gamma}   // 1.0;
    my $Eg      = $params{Eg}      // 1.5;
    my $Ep      = $params{Ep}      // 1.0;    # transition width
    my $Eu      = $params{Eu}      // 0.05;   # Urbach energy [eV]
    my $eps_inf = $params{eps_inf} // 1.0;

    my $E = 1239.842 / $lambda_nm;
    my $eps2 = zeroes($lambda_nm);

    # Transition energy Et
    my $Et = $Eg + $Ep;

    # Lorentz oscillator part for E > Et
    my $above_et = which($E > $Et);
    if ($above_et->nelem > 0) {
        my $Ea = $E->index($above_et);
        my $G = $A * $E0 * $Gamma;
        my $lorentz = $G / (($Ea**2 - $E0**2)**2 + $Gamma**2 * $Ea**2);
        my $cody = ($Ea - $Eg)**2 / (($Ea - $Eg)**2 + $Ep**2);
        $eps2->index($above_et) .= $lorentz * $cody * $Ea;
    }

    # Urbach tail for Eg < E <= Et
    my $urbach_region = which(($E > $Eg) & ($E <= $Et));
    if ($urbach_region->nelem > 0) {
        my $Eu_e = $E->index($urbach_region);
        # Match value at Et
        my $G = $A * $E0 * $Gamma;
        my $l_at_et = $G / (($Et**2 - $E0**2)**2 + $Gamma**2 * $Et**2);
        my $c_at_et = ($Et - $Eg)**2 / (($Et - $Eg)**2 + $Ep**2);
        my $eps2_et = $l_at_et * $c_at_et * $Et;
        $eps2->index($urbach_region) .= $eps2_et * exp(($Eu_e - $Et) / $Eu);
    }

    # KK transform for eps1
    my $eps1 = _kk_transform($E, $eps2) + $eps_inf;

    my $eps = $eps1 + i() * $eps2;
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Critical Point model (Adachi / Kim et al.)
# Models van Hove singularities in crystalline semiconductors
# eps(E) = sum_j C_j * exp(i*phi_j) * (E - E_j + i*Gamma_j)^(-mu_j)
# mu = 0.5 for 3D M0 CP, -0.5 for 3D M1, 0 for 2D (logarithmic)
sub critical_point_nk {
    my ($lambda_nm, $cps, $eps_inf) = @_;
    $cps     //= [];    # arrayref of {C, E, Gamma, phi, mu}
    $eps_inf //= 1.0;

    my $E = 1239.842 / $lambda_nm;
    my $eps = $eps_inf * ones($lambda_nm) + i() * zeroes($lambda_nm);

    for my $cp (@$cps) {
        my $C     = $cp->{C}     // 1.0;
        my $Ecp   = $cp->{E}     // 3.4;
        my $Gamma = $cp->{Gamma} // 0.1;
        my $phi   = $cp->{phi}   // 0.0;   # phase [radians]
        my $mu    = $cp->{mu}    // 0.5;   # exponent

        my $phase_factor = cos($phi) + i() * sin($phi);
        my $z = $E - $Ecp + i() * $Gamma;

        if (abs($mu) < 0.01) {
            # Logarithmic (2D) critical point: C * exp(i*phi) * ln(z)
            # ln(complex) = ln|z| + i*arg(z)
            my $ln_z = log(abs($z)) + i() * carg($z);
            $eps += $C * $phase_factor * $ln_z;
        } else {
            # Power-law: C * exp(i*phi) * z^(-mu)
            # z^(-mu) = exp(-mu * ln(z)) = |z|^(-mu) * exp(-i*mu*arg(z))
            my $mag = abs($z)**(-$mu);
            my $arg_part = -$mu * carg($z);
            my $z_pow = $mag * (cos($arg_part) + i() * sin($arg_part));
            $eps += $C * $phase_factor * $z_pow;
        }
    }

    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Gaussian oscillator model
# eps(E) = sum_j sigma_j(E) + i * eps2_j(E)
# eps2(E) = A * exp(-((E-E0)/(sigma))^2) - A * exp(-((E+E0)/(sigma))^2)
# eps1 from numerical KK
# sigma = Gamma / (2*sqrt(ln(2)))
sub gaussian_nk {
    my ($lambda_nm, $oscillators, $eps_inf) = @_;
    $oscillators //= [];   # arrayref of [A, E0, Gamma] triplets
    $eps_inf     //= 1.0;

    my $E = 1239.842 / $lambda_nm;
    my $eps2 = zeroes($lambda_nm);

    for my $osc (@$oscillators) {
        my ($Ai, $E0i, $Gi) = @$osc;
        my $sigma = $Gi / (2.0 * sqrt(log(2.0)));
        # Gaussian line shape (positive + negative frequency contributions)
        $eps2 += $Ai * exp(-(($E - $E0i) / $sigma)**2)
               - $Ai * exp(-(($E + $E0i) / $sigma)**2);
    }
    $eps2 = $eps2->clip(0, 1e6);

    # KK transform for eps1
    my $eps1 = _kk_transform($E, $eps2) + $eps_inf;

    my $eps = $eps1 + i() * $eps2;
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# B-spline parameterized optical constants
# Uses cubic B-spline basis functions on a knot vector for eps2(E),
# then derives eps1 from numerical KK. Allows model-free fitting.
# $knots: arrayref of energy knot positions [eV]
# $coeffs: arrayref of B-spline coefficients for eps2
sub bspline_nk {
    my ($lambda_nm, $knots, $coeffs, $eps_inf) = @_;
    $knots   //= [1.0, 2.0, 3.0, 4.0, 5.0];
    $coeffs  //= [0.0, 0.5, 1.0, 0.5, 0.0];
    $eps_inf //= 1.0;

    my $E = 1239.842 / $lambda_nm;
    my $eps2 = zeroes($lambda_nm);

    # Evaluate cubic B-spline
    my $nknots = scalar @$knots;
    my $ncoeffs = scalar @$coeffs;

    # Augmented knot vector for cubic (order 4)
    my @aug = (($knots->[0]) x 3, @$knots, ($knots->[-1]) x 3);

    for my $i (0 .. $ncoeffs - 1) {
        my $basis = _bspline_basis(3, $i, \@aug, $E);
        $eps2 += $coeffs->[$i] * $basis;
    }
    $eps2 = $eps2->clip(0, 1e6);

    # KK for eps1
    my $eps1 = _kk_transform($E, $eps2) + $eps_inf;

    my $eps = $eps1 + i() * $eps2;
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Recursive B-spline basis function evaluation (Cox-de Boor)
sub _bspline_basis {
    my ($degree, $i, $knots, $E) = @_;

    if ($degree == 0) {
        # Indicator: 1 where knot[i] <= E < knot[i+1]
        return (($E >= $knots->[$i]) & ($E < $knots->[$i+1]))->double;
    }

    my $left = zeroes($E);
    my $right = zeroes($E);

    my $denom_l = $knots->[$i + $degree] - $knots->[$i];
    if ($denom_l > 1e-10) {
        $left = ($E - $knots->[$i]) / $denom_l
                * _bspline_basis($degree - 1, $i, $knots, $E);
    }

    my $denom_r = $knots->[$i + $degree + 1] - $knots->[$i + 1];
    if ($denom_r > 1e-10) {
        $right = ($knots->[$i + $degree + 1] - $E) / $denom_r
                 * _bspline_basis($degree - 1, $i + 1, $knots, $E);
    }

    return $left + $right;
}

1;
