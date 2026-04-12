use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Math;
use Physics::Ellipsometry::VASE;
use PDL::Constants qw(PI);
use FindBin;

# ============================================================
# Tauc-Lorentz fit for Ta2O5 on Si
# ============================================================
# The Tauc-Lorentz oscillator model (Jellison & Modine, 1996)
# provides a Kramers-Kronig consistent dielectric function
# suitable for amorphous dielectrics in the UV-Vis-NIR range.
#
# Fit parameters (6 total, all rescaled to order ~1):
#   [0] eps_inf      - high-freq dielectric constant (~1-4)
#   [1] A_scaled     - oscillator amplitude / 100 (eV)
#   [2] E0           - oscillator center energy (eV)
#   [3] C            - oscillator broadening (eV)
#   [4] Eg           - Tauc band gap energy (eV)
#   [5] d_scale      - film thickness / 100 (nm)
# Si substrate uses a fixed two-oscillator model (Aspnes & Studna).
# ============================================================

my $vase = Physics::Ellipsometry::VASE->new(layers => 1);

my $data_file = "$FindBin::Bin/../data/Metal_Oxides/tantalum oxide/Cap_11012006/w1_11012006.dat";
$vase->load_data($data_file);

# ----------------------------------------------------------
# Tauc-Lorentz dielectric function
#
# eps2(E) = (A E0 C (E - Eg)^2) / ((E^2 - E0^2)^2 + C^2 E^2) / E
#           for E > Eg, else 0
#
# eps1(E) = eps_inf + (2/pi) * P integral[ xi * eps2(xi) / (xi^2 - E^2) dxi ]
#
# The analytic Kramers-Kronig integral for eps1 is from
# Jellison & Modine, Appl. Phys. Lett. 69, 371 (1996).
# ----------------------------------------------------------

sub tauc_lorentz_dielectric {
    my ($E, $A, $E0, $C, $Eg, $eps_inf) = @_;

    # eps2: imaginary part
    my $eps2 = zeroes($E);
    my $above_gap = which($E > $Eg);
    if ($above_gap->nelem > 0) {
        my $Ea = $E->index($above_gap);
        my $num = $A * $E0 * $C * ($Ea - $Eg)**2;
        my $den = (($Ea**2 - $E0**2)**2 + $C**2 * $Ea**2) * $Ea;
        $eps2->index($above_gap) .= $num / $den;
    }

    # eps1 via numerical Kramers-Kronig integration
    # eps1(E) = eps_inf + (2/pi) * P integral[ xi * eps2(xi) / (xi^2 - E^2) dxi ]
    # Use a fine energy grid for integration
    my $Emin = 0.5;
    my $Emax = 10.0;
    my $npts = 200;
    my $dxi  = ($Emax - $Emin) / $npts;
    my $xi   = $Emin + ($dxi * (sequence($npts) + 0.5));

    # eps2 on integration grid
    my $eps2_xi = zeroes($xi);
    my $above_xi = which($xi > $Eg);
    if ($above_xi->nelem > 0) {
        my $xia = $xi->index($above_xi);
        my $num_xi = $A * $E0 * $C * ($xia - $Eg)**2;
        my $den_xi = (($xia**2 - $E0**2)**2 + $C**2 * $xia**2) * $xia;
        $eps2_xi->index($above_xi) .= $num_xi / $den_xi;
    }

    # Numerical principal-value integral via midpoint rule (vectorized)
    # integrand_num is [npts], E is [ndata]
    my $integrand_num = $xi * $eps2_xi;  # [npts]
    # Build [npts x ndata] matrix: xi_j^2 - E_k^2
    my $xi_col  = $xi->dummy(1, $E->nelem);       # [npts, ndata]
    my $E_row   = $E->dummy(0, $npts);             # [npts, ndata]
    my $denom   = $xi_col**2 - $E_row**2;          # [npts, ndata]
    my $safe    = (abs($denom) > 1e-6);
    $denom      = $denom + (1 - $safe) * 1e30;     # avoid division by zero
    my $fn_col  = $integrand_num->dummy(1, $E->nelem);  # [npts, ndata]
    my $eps1    = $eps_inf + (2.0 / PI) * $dxi * ($fn_col * $safe / $denom)->sumover;

    return ($eps1, $eps2);
}

# ----------------------------------------------------------
# Silicon dielectric function (simple model for substrate)
# Aspnes & Studna, Phys. Rev. B 27, 985 (1983)
# Parameterized for 245-1700 nm range
# ----------------------------------------------------------
sub si_dielectric {
    my ($E) = @_;

    # Two-oscillator model for Si
    # Oscillator 1 (E1 critical point ~3.4 eV)
    my $E1 = 3.38;  my $A1 = 12.0; my $C1 = 0.3;
    # Oscillator 2 (E2 critical point ~4.3 eV)
    my $E2cp = 4.27; my $A2 = 40.0; my $C2 = 1.0;

    my $eps1 = 1.0;
    my $eps2 = zeroes($E);

    for my $osc ([$A1, $E1, $C1], [$A2, $E2cp, $C2]) {
        my ($Ai, $Ei, $Ci) = @$osc;
        my $denom = ($E**2 - $Ei**2)**2 + $Ci**2 * $E**2;
        $eps1 = $eps1 + $Ai * ($Ei**2 - $E**2) / $denom;
        $eps2 = $eps2 + $Ai * $Ci * $E / $denom;
    }

    return ($eps1, $eps2);
}

# ----------------------------------------------------------
# Model function for VASE fitting
# ----------------------------------------------------------
sub tauc_lorentz_model {
    my ($params, $x) = @_;

    # Unpack scaled parameters — soft-clamp to avoid unphysical values
    # Use smooth penalty rather than hard clip to preserve Jacobian
    my $eps_inf  = $params->(0);
    my $A        = $params->(1) * 100;   # rescale A
    my $E0       = $params->(2);
    my $C_osc    = $params->(3);
    my $Eg       = $params->(4);
    my $d        = $params->(5) * 100;   # rescale thickness (nm)

    # Ensure positivity via abs() — smooth and differentiable
    $A     = abs($A)     + 0.01;
    $C_osc = abs($C_osc) + 0.01;
    $Eg    = abs($Eg);
    $d     = abs($d)     + 0.1;

    my $n0 = 1.0;  # ambient (air)

    # Independent variables
    my $lambda = $x->(:,0);                     # wavelength [nm]
    my $theta0 = $x->(:,1) * (PI / 180.0);      # incident angle [rad]

    # Convert wavelength to photon energy (eV)
    my $E = 1239.842 / $lambda;  # hc = 1239.842 eV*nm

    # Compute dielectric functions for unique energies only, then broadcast
    my $E_uniq = $E->uniq->qsort;
    my ($eps1_fu, $eps2_fu) = tauc_lorentz_dielectric($E_uniq, $A, $E0, $C_osc, $Eg, $eps_inf);
    my ($eps1_su, $eps2_su) = si_dielectric($E_uniq);

    # Map unique results back to full data array via interpolation (exact match)
    my ($eps1_f, $eps2_f, $eps1_s, $eps2_s);
    if ($E_uniq->nelem == $E->nelem) {
        # All energies already unique — no mapping needed
        ($eps1_f, $eps2_f, $eps1_s, $eps2_s) = ($eps1_fu, $eps2_fu, $eps1_su, $eps2_su);
    } else {
        # Use interpolation for the lookup (energies are exact matches)
        $eps1_f = $E->interpol($E_uniq, $eps1_fu);
        $eps2_f = $E->interpol($E_uniq, $eps2_fu);
        $eps1_s = $E->interpol($E_uniq, $eps1_su);
        $eps2_s = $E->interpol($E_uniq, $eps2_su);
    }

    # Complex refractive index of film: N = n + ik = sqrt(eps1 + i*eps2)
    my $eps_f = $eps1_f + i() * $eps2_f;
    my $N1 = sqrt($eps_f);

    # Silicon substrate
    my $eps_s = $eps1_s + i() * $eps2_s;
    my $N2 = sqrt($eps_s);

    # Complex Snell's law
    my $cos_theta0 = cos($theta0);
    my $sin_theta0 = sin($theta0);
    my $sin2_theta0 = $sin_theta0**2;

    my $cos_theta1 = sqrt(1.0 - ($n0 * $sin_theta0)**2 / $N1**2);
    my $cos_theta2 = sqrt(1.0 - ($n0 * $sin_theta0)**2 / $N2**2);

    # Phase thickness
    my $beta = (2 * PI / $lambda) * $N1 * $d * $cos_theta1;

    # Fresnel coefficients (complex)
    # Air/film interface
    my $r01s = ($n0 * $cos_theta0 - $N1 * $cos_theta1)
             / ($n0 * $cos_theta0 + $N1 * $cos_theta1);
    my $r01p = ($N1 * $cos_theta0 - $n0 * $cos_theta1)
             / ($N1 * $cos_theta0 + $n0 * $cos_theta1);

    # Film/substrate interface
    my $r12s = ($N1 * $cos_theta1 - $N2 * $cos_theta2)
             / ($N1 * $cos_theta1 + $N2 * $cos_theta2);
    my $r12p = ($N2 * $cos_theta1 - $N1 * $cos_theta2)
             / ($N2 * $cos_theta1 + $N1 * $cos_theta2);

    # Total reflectance (thin-film interference)
    my $phase = exp(-2 * i() * $beta);
    my $rs = ($r01s + $r12s * $phase) / (1 + $r01s * $r12s * $phase);
    my $rp = ($r01p + $r12p * $phase) / (1 + $r01p * $r12p * $phase);

    # Ellipsometric ratio rho = rp/rs
    my $rho = $rp / $rs;

    # Psi and Delta in degrees
    my $psi   = atan(abs($rho)) * (180.0 / PI);
    my $delta = carg($rho) * (180.0 / PI);

    return cat($psi->re, $delta->re)->flat->double;
}

# ============================================================
# Run the fit
# ============================================================
$vase->set_model(\&tauc_lorentz_model);

# Initial parameters (scaled):
#   eps_inf=1.5, A=50(eV)/100=0.5, E0=4.6eV, C=1.0eV, Eg=3.8eV,
#   d=100nm/100=1.0
my $initial_params = pdl [1.5, 0.5, 4.6, 1.0, 3.8, 1.0];

print "Fitting Tauc-Lorentz model to Ta2O5 data...\n";
my $fit_params = $vase->fit($initial_params);

# Unpack results
my ($eps_inf, $A_s, $E0, $C_osc, $Eg, $d_s) = list $fit_params;
my $A  = $A_s * 100;
my $d  = $d_s * 100;

print "\nTauc-Lorentz Fit Results:\n";
print "=" x 40, "\n";
printf "  eps_inf:        %.4f\n", $eps_inf;
printf "  A (amplitude):  %.2f eV\n", $A;
printf "  E0 (center):    %.4f eV\n", $E0;
printf "  C (broadening): %.4f eV\n", $C_osc;
printf "  Eg (band gap):  %.4f eV\n", $Eg;
printf "  Thickness:      %.2f nm\n", $d;
printf "  Iterations:     %d\n", $vase->{iters};
print "=" x 40, "\n";

# Plot fit vs data
$vase->plot($fit_params,
    output => "$FindBin::Bin/tauc_lorentz_fit.png",
    title  => 'Ta_2O_5 Tauc-Lorentz Fit — w1\_11012006',
);
