use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Math;
use Physics::Ellipsometry::VASE;
use PDL::Constants qw(PI);
use FindBin;

# Create VASE object with 1 layer
my $vase = Physics::Ellipsometry::VASE->new(
    layers         => 1,
    maxiter        => 500,
    circular_delta => 1,
    deriv_step     => 1e-4,
);

# Load sample data
my $data_file = "$FindBin::Bin/w1_11012006.dat";
$vase->load_data($data_file);

# Restrict to visible-NIR (500-1700 nm) where Cauchy is valid
# Below ~400 nm Ta2O5 absorbs; below 500 the Si oscillator model is less accurate
my $data = $vase->{data};
my $wav_col = $data->(0,:)->flat;
my $mask = ($wav_col >= 500);
my $idx  = which($mask);
$vase->{data} = $data->(:,$idx)->sever;
# Also restrict sigma if present
if (defined $vase->{sigma}) {
    $vase->{sigma} = $vase->{sigma}->(:,$idx)->sever;
}
printf "Using %d points (500-%.0f nm) from %d total\n",
       $idx->nelem, $wav_col->index($idx)->max, $wav_col->nelem;

# Tabulated Si optical constants (Aspnes & Studna 1983, Salzberg & Villa 1957)
# Format: wavelength(nm), n, k
my @SI_TABLE = (
    [245, 1.570, 3.565], [250, 1.545, 3.637], [260, 1.637, 3.876],
    [270, 1.800, 4.013], [280, 2.059, 4.087], [290, 2.491, 4.075],
    [300, 3.473, 3.768], [310, 4.355, 2.993], [320, 5.010, 2.538],
    [330, 5.448, 2.380], [340, 5.834, 2.407], [350, 5.932, 2.795],
    [360, 6.366, 2.863], [370, 6.596, 1.878], [380, 5.976, 0.631],
    [390, 5.609, 0.451], [400, 5.370, 0.387], [410, 5.150, 0.329],
    [420, 4.995, 0.266], [430, 4.857, 0.219], [440, 4.735, 0.195],
    [450, 4.653, 0.169], [460, 4.554, 0.133], [470, 4.476, 0.118],
    [480, 4.411, 0.106], [490, 4.350, 0.095], [500, 4.293, 0.073],
    [520, 4.197, 0.060], [540, 4.117, 0.050], [550, 4.084, 0.041],
    [560, 4.050, 0.037], [580, 3.992, 0.030], [600, 3.939, 0.025],
    [620, 3.891, 0.020], [640, 3.851, 0.016], [660, 3.815, 0.013],
    [680, 3.780, 0.011], [700, 3.750, 0.010], [720, 3.722, 0.008],
    [740, 3.700, 0.007], [760, 3.680, 0.005], [780, 3.660, 0.004],
    [800, 3.642, 0.004], [850, 3.600, 0.002], [900, 3.565, 0.001],
    [950, 3.536, 0.001], [1000, 3.510, 0.000], [1050, 3.488, 0.000],
    [1100, 3.468, 0.000], [1200, 3.440, 0.000], [1300, 3.417, 0.000],
    [1400, 3.400, 0.000], [1500, 3.387, 0.000], [1600, 3.376, 0.000],
    [1700, 3.367, 0.000],
);

# Pre-compute Si optical constants as PDL for interpolation
my $si_wav = pdl [map { $_->[0] } @SI_TABLE];
my $si_n   = pdl [map { $_->[1] } @SI_TABLE];
my $si_k   = pdl [map { $_->[2] } @SI_TABLE];

sub interp_si {
    my ($lambda_in) = @_;
    my $lambda = $lambda_in->flat;  # ensure 1D
    my $n_out = zeroes($lambda);
    my $k_out = zeroes($lambda);
    for my $i (0 .. $lambda->nelem - 1) {
        my $lam = $lambda->at($i);
        # Clamp to table range
        $lam = 245 if $lam < 245;
        $lam = 1700 if $lam > 1700;
        # Find bracketing indices
        my $j = 0;
        for my $jj (0 .. $#SI_TABLE - 1) {
            if ($SI_TABLE[$jj][0] <= $lam && $SI_TABLE[$jj+1][0] >= $lam) {
                $j = $jj; last;
            }
        }
        my $l0 = $SI_TABLE[$j][0]; my $l1 = $SI_TABLE[$j+1][0];
        my $t = ($lam - $l0) / ($l1 - $l0);
        $n_out->set($i, $SI_TABLE[$j][1]*(1-$t) + $SI_TABLE[$j+1][1]*$t);
        $k_out->set($i, $SI_TABLE[$j][2]*(1-$t) + $SI_TABLE[$j+1][2]*$t);
    }
    return ($n_out, $k_out);
}

sub cauchy_model {
    my ($params, $x) = @_;

    # Fit parameters: [A, B_scaled, d]
    # B_scaled = B / 1e4 so all params are order ~1
    my $a  = $params->(0);
    my $b  = $params->(1) * 1e4;  # rescale B back to nm^2
    my $d  = $params->(2);        # thickness [nm]

    # Fixed: ambient (air)
    my $n0 = 1.0;

    # Unpack independent vars
    my $lambda = $x->(:,0); # wavelength [nm]
    my $theta0 = $x->(:,1) * (PI / 180.0); # incident angle [radians]

    # Film refractive index from Cauchy (2-term, transparent)
    my $N1 = $a + $b / ($lambda**2);

    # Si substrate: tabulated optical constants (interpolated)
    my ($n_si, $k_si) = interp_si($lambda);
    my $N2 = $n_si + i() * $k_si;

    # Complex Snell's law
    my $cos_theta0 = cos($theta0);
    my $sin_theta0 = sin($theta0);
    my $cos_theta1 = sqrt(1.0 - ($n0 * $sin_theta0 / $N1)**2);
    my $cos_theta2 = sqrt(1.0 - ($n0 * $sin_theta0)**2 / $N2**2);

    # Phase thickness
    my $beta = (2 * PI / $lambda) * $N1 * $d * $cos_theta1;

    # Fresnel coefficients (complex)
    # Air/film
    my $r01s = ($n0*$cos_theta0 - $N1*$cos_theta1)
               / ($n0*$cos_theta0 + $N1*$cos_theta1);
    my $r01p = ($N1*$cos_theta0 - $n0*$cos_theta1)
               / ($N1*$cos_theta0 + $n0*$cos_theta1);

    # Film/substrate
    my $r12s = ($N1*$cos_theta1 - $N2*$cos_theta2)
               / ($N1*$cos_theta1 + $N2*$cos_theta2);
    my $r12p = ($N2*$cos_theta1 - $N1*$cos_theta2)
               / ($N2*$cos_theta1 + $N1*$cos_theta2);

    # Thin-film Fresnel reflectances (Airy formula)
    my $phase = exp(-2*i()*$beta);
    my $rs = ($r01s + $r12s*$phase) / (1 + $r01s*$r12s*$phase);
    my $rp = ($r01p + $r12p*$phase) / (1 + $r01p*$r12p*$phase);

    # Ellipsometric ratio
    my $rho = $rp / $rs;

    # Psi and Delta
    my $psi = atan( abs($rho) ) * (180.0 / PI);
    my $delta = carg($rho) * (180.0 / PI);
    # Map delta to [0, 360) to match VASE data convention
    $delta = $delta + 360.0 * ($delta < 0);

    return cat($psi->re, $delta->re)->flat->double;
}

$vase->set_model(\&cauchy_model);

# Cauchy params: [A, B_scaled, thickness(nm)]
# Ta2O5 typical: A~2.1, B~20000 nm^2 (B_scaled~2.0)
# Si substrate is fixed (tabulated optical constants)
# Use grid search over A, B, and thickness to avoid local minima
my $best_d = 95; my $best_a = 2.1; my $best_b = 2.0; my $best_mse = 1e30;
my $x_data = $vase->{data}->(0:1,:)->xchg(0,1);
my $y_data = $vase->{data}->(2,:)->flat->append($vase->{data}->(3,:)->flat);
my $npts_fit = $vase->{data}->getdim(1);

# Grid: A from 2.0 to 2.3, B_scaled from 1.0 to 4.0, d from 50 to 200
for my $d_try (map { $_ * 5 + 50 } 0..30) {
    for my $a_try (map { $_ * 0.05 + 2.0 } 0..6) {
        for my $b_try (map { $_ * 0.5 + 1.0 } 0..6) {
            my $p = pdl [$a_try, $b_try, $d_try];
            my $ym = cauchy_model($p, $x_data);
            # Use circular delta residuals for cost
            my $psi_res = $y_data->slice("0:" . ($npts_fit-1))
                        - $ym->slice("0:" . ($npts_fit-1));
            my $delta_res = $y_data->slice("$npts_fit:" . (2*$npts_fit-1))
                          - $ym->slice("$npts_fit:" . (2*$npts_fit-1));
            $delta_res -= 360.0 * rint($delta_res / 360.0);
            my $cost = (sum($psi_res**2) + sum($delta_res**2))->sclr / (2*$npts_fit);
            if ($cost < $best_mse) {
                $best_mse = $cost; $best_d = $d_try;
                $best_a = $a_try; $best_b = $b_try;
            }
        }
    }
}
printf "Grid search: best A=%.2f, B_sc=%.1f, d=%d nm (MSE ~ %.1f)\n",
       $best_a, $best_b, $best_d, $best_mse;

my $initial_params = pdl [$best_a, $best_b, $best_d];

print "Fitting Cauchy model to Ta2O5/Si data (transparent region)...\n";
my $fit_params = $vase->fit($initial_params);

# Extract results
my ($a, $b_scaled, $d) = list $fit_params;
my $b = $b_scaled * 1e4;
print "\nCauchy Fit Results:\n";
print "=" x 40, "\n";
printf "  Cauchy A:       %.6f\n", $a;
printf "  Cauchy B:       %.2f nm^2\n", $b;
printf "  Thickness:      %.2f nm\n", $d;
printf "  n(550nm):       %.4f\n", $a + $b / 550**2;
printf "  n(632nm):       %.4f\n", $a + $b / 632**2;
printf "  MSE:            %.4f\n", $vase->mse($fit_params, nparams => 3);
printf "  Iterations:     %d\n", $vase->{iters};
print "=" x 40, "\n";

# Plot fit vs data
$vase->plot($fit_params,
    output => "$FindBin::Bin/cauchy_fit.png",
    title  => 'Ta_2O_5 Cauchy Fit (400+ nm)',
);
