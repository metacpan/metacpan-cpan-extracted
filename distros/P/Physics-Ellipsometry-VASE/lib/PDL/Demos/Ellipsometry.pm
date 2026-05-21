package PDL::Demos::Ellipsometry;

use strict;
use warnings;
use PDL;
use Physics::Ellipsometry::VASE;

sub info {('ellipsometry', 'Spectroscopic ellipsometry analysis with Physics::Ellipsometry::VASE (Req.: PDL::Graphics::Simple)')}

# Locate data files shipped alongside this module
sub _data_dir {
    (my $dir = $INC{"PDL/Demos/Ellipsometry.pm"}) =~ s/Ellipsometry\.pm$//;
    return $dir;
}

sub init {'
use PDL;
use PDL::Graphics::Simple;
use PDL::Constants qw(PI);
use PDL::Math;
use Physics::Ellipsometry::VASE;
use File::Temp qw(tempfile);
'}

my @demo = (

# ── Section 1: Introduction ──────────────────────────────────────────
[comment => q{
    +========================================================+
    |   Spectroscopic Ellipsometry with PDL                   |
    |   Physics::Ellipsometry::VASE Demo                      |
    +========================================================+

 Ellipsometry measures how polarized light changes upon
 reflection from a thin-film surface.  Two quantities are
 measured at each wavelength and angle of incidence:

   Psi   -- amplitude ratio of p- and s-polarisations
   Delta -- phase difference between them

 Together they encode the optical constants and thickness
 of each layer in the film stack.

 This demo walks through the analysis workflow using
 Physics::Ellipsometry::VASE and PDL, with plots via
 PDL::Graphics::Simple.
}],

# ── Section 2: Synthetic ellipsometry data ────────────────────────────
[act => q|
  # Generate synthetic ellipsometry data with PDL
  # 5 wavelengths, measured at 70 degrees incidence
  $wavelength = pdl [400, 410, 420, 430, 440];
  $angle      = 70 * ones(5);
  $psi        = 45.0 - 0.05 * $wavelength;   # linear Psi model
  $delta      = 80.0 + 0.10 * $wavelength;   # linear Delta model

  print "Wavelength (nm) : $wavelength\n";
  print "Angle (deg)     : $angle\n";
  print "Psi (deg)       : $psi\n";
  print "Delta (deg)     : $delta\n";
|],

# ── Section 3: Creating a data file and loading it ────────────────────
[act => q|
  # Write synthetic data to a temp file (standard VASE text format)
  ($fh, $tmpfile) = tempfile(SUFFIX => '.dat', UNLINK => 1);
  print $fh "# Wavelength(nm) Angle(deg) Psi(deg) Delta(deg)\n";
  for my $i (0 .. $wavelength->nelem - 1) {
      printf $fh "%.1f  %.1f  %.4f  %.4f\n",
          $wavelength->at($i), $angle->at($i),
          $psi->at($i), $delta->at($i);
  }
  close $fh;

  # Load into a VASE object
  $vase = Physics::Ellipsometry::VASE->new(layers => 1);
  $data = $vase->load_data($tmpfile);
  print "Loaded data shape: ", join('x', $data->dims), "\n";
  print $data;
|],

# ── Section 4: Defining a linear model ────────────────────────────────
[act => q|
  # Model function: receives (params, x) and returns [Psi, Delta] flat
  #   params = [a, b, c, d]
  #   Psi   = a - b * wavelength
  #   Delta = c + d * wavelength

  sub linear_model {
      my ($params, $x) = @_;
      my $a = $params->slice("(0)");
      my $b = $params->slice("(1)");
      my $c = $params->slice("(2)");
      my $d = $params->slice("(3)");
      my $wl  = $x->slice(",(0)")->flat;             # wavelength column
      my $psi = $a - $b * $wl;
      my $del = $c + $d * $wl;
      return cat($psi, $del)->flat;
  }

  print "Linear model function defined.\n";
  print "  Psi   = a - b * wavelength\n";
  print "  Delta = c + d * wavelength\n";
|],

# ── Section 5: Fitting and plotting the linear model ─────────────────
[act => q|
  # Register the model and fit with Levenberg-Marquardt
  $vase->set_model(\&linear_model);

  $p0 = pdl [65, 0.05, 80, 0.1];  # initial parameter guesses
  print "Initial params : $p0\n";

  $fit = $vase->fit($p0);

  my ($a, $b, $c, $d) = list $fit;
  print "\nFitted params:\n";
  printf "  a = %.6f   b = %.6f\n", $a, $b;
  printf "  c = %.6f   d = %.6f\n", $c, $d;
  printf "  Iterations: %d\n", $vase->{iters};
  printf "  MSE: %.6f\n", $vase->mse($fit);
|],

[act => q|
  # Plot the linear model fit using PDL::Graphics::Simple
  $w = pgswin(size => [8,6], multi => [1,2]);

  # Evaluate model at fitted parameters
  $x_plot = $vase->{data}->slice("0:1,:")->xchg(0,1);
  $y_fit = linear_model($fit, $x_plot);
  $np = $wavelength->nelem;
  $psi_fit   = $y_fit->slice("0:" . ($np-1));
  $delta_fit = $y_fit->slice("$np:" . (2*$np-1));

  # Psi panel
  $w->plot(with => 'points', $wavelength, $psi,
           with => 'line',   $wavelength, $psi_fit,
           {title => "Linear Fit: Psi", xlabel => "Wavelength (nm)",
            ylabel => "Psi (deg)", legend => ['Data','Fit']});

  # Delta panel
  $w->plot(with => 'points', $wavelength, $delta,
           with => 'line',   $wavelength, $delta_fit,
           {title => "Linear Fit: Delta", xlabel => "Wavelength (nm)",
            ylabel => "Delta (deg)", legend => ['Data','Fit']});
|],

# ── Section 6: Cauchy dispersion model ────────────────────────────────
[comment => q|
 Now for some real physics!

 The Cauchy dispersion model describes how the refractive
 index of a transparent film varies with wavelength:

     n(lambda) = A + B/lambda^2 + C/lambda^4

 Combined with the Fresnel equations and thin-film
 interference (transfer matrix method), this predicts
 the Psi and Delta measured by the ellipsometer.

 We will generate realistic data for a ~100nm SiO2 film
 on silicon and then fit the Cauchy parameters.
|],

[act => q|
  # Generate realistic SiO2/Si data using the Cauchy + Fresnel model
  # True parameters: A=1.46, B=3400 nm^2, n_sub=3.87, d=100 nm
  $wl_sim = sequence(21) * 15 + 400;    # 400-700 nm in 15nm steps
  $ang_sim = 70 * ones($wl_sim);

  # Cauchy index for SiO2
  $n_true  = 1.46 + 3400.0 / $wl_sim**2;
  print "Simulated Cauchy n(lambda) at selected wavelengths:\n";
  printf "  n(400nm) = %.4f\n", $n_true->at(0);
  printf "  n(550nm) = %.4f\n", $n_true->at(10);
  printf "  n(700nm) = %.4f\n", $n_true->at(20);
|],

[act => q|
  # Compute Psi & Delta via Fresnel equations for a single film on substrate
  sub fresnel_cauchy {
      my ($par, $x) = @_;
      my $A  = $par->slice("(0)");
      my $B  = $par->slice("(1)") * 1e4;   # rescale B
      my $n2 = $par->slice("(2)");          # substrate index
      my $d  = $par->slice("(3)");          # thickness (nm)
      my $n0 = 1.0;                         # ambient (air)

      my $lam    = $x->slice(",(0)")->flat;
      my $theta0 = $x->slice(",(1)")->flat * (PI / 180.0);

      my $n1 = $A + $B / $lam**2;   # Cauchy dispersion

      # Snell's law
      my $sin1 = ($n0 * sin($theta0) / $n1)->clip(-0.999, 0.999);
      my $th1  = asin($sin1);
      my $sin2 = ($n0 * sin($theta0) / $n2)->clip(-0.999, 0.999);
      my $th2  = asin($sin2);

      # Phase thickness
      my $beta = (2 * PI / $lam) * $n1 * $d * cos($th1);

      # Fresnel coefficients (air/film and film/substrate)
      my $r01s = ($n0*cos($theta0) - $n1*cos($th1))
               / ($n0*cos($theta0) + $n1*cos($th1));
      my $r01p = ($n1*cos($theta0) - $n0*cos($th1))
               / ($n1*cos($theta0) + $n0*cos($th1));
      my $r12s = ($n1*cos($th1) - $n2*cos($th2))
               / ($n1*cos($th1) + $n2*cos($th2));
      my $r12p = ($n2*cos($th1) - $n1*cos($th2))
               / ($n2*cos($th1) + $n1*cos($th2));

      # Thin-film reflectance
      my $phase = exp(-2*i()*$beta);
      my $rs = ($r01s + $r12s*$phase) / (1 + $r01s*$r12s*$phase);
      my $rp = ($r01p + $r12p*$phase) / (1 + $r01p*$r12p*$phase);

      # Ellipsometric ratio -> Psi, Delta
      my $rho   = $rp / $rs;
      my $psi   = atan(abs($rho)) * (180.0 / PI);
      my $delta = carg($rho) * (180.0 / PI);

      return cat($psi->re, $delta->re)->flat->double;
  }
  print "Cauchy + Fresnel model defined.\n";
|],

[act => q|
  # Simulate the "measured" data with the true parameters
  $x_sim = cat($wl_sim, $ang_sim);   # shape (npts, 2)
  $true_params = pdl [1.46, 0.34, 3.87, 100.0];  # A, B/1e4, n_sub, d
  $y_sim = fresnel_cauchy($true_params, $x_sim);
  $npts = $wl_sim->nelem;
  $psi_sim   = $y_sim->slice("0:" . ($npts-1));
  $delta_sim = $y_sim->slice("$npts:" . (2*$npts-1));

  # Add small noise for realism (seeded for reproducibility)
  srandom(42);
  $psi_sim   = $psi_sim   + 0.1 * grandom($npts);
  $delta_sim = $delta_sim + 0.2 * grandom($npts);

  # Write to temp file and load into VASE
  ($fh2, $tmpfile2) = tempfile(SUFFIX => '.dat', UNLINK => 1);
  print $fh2 "# Wavelength(nm) Angle(deg) Psi(deg) Delta(deg)\n";
  for my $i (0 .. $npts - 1) {
      printf $fh2 "%.1f  %.1f  %.4f  %.4f\n",
          $wl_sim->at($i), $ang_sim->at($i),
          $psi_sim->at($i), $delta_sim->at($i);
  }
  close $fh2;

  $cauchy_vase = Physics::Ellipsometry::VASE->new(layers => 1, maxiter => 1000);
  $cauchy_vase->load_data($tmpfile2);
  print "Simulated SiO2/Si data loaded ($npts points).\n";
|],

[act => q{
  # Fit the Cauchy model -- start from a deliberately offset guess
  $cauchy_vase->set_model(\&fresnel_cauchy);
  $guess = pdl [1.50, 0.50, 3.50, 80.0];   # off from truth
  print "True params  : $true_params\n";
  print "Initial guess: $guess\n\n";

  eval { $cauchy_fit = $cauchy_vase->fit($guess); };
  if ($@ || !defined $cauchy_fit) {
      # If the offset guess didn't converge, try from closer to truth
      $cauchy_fit = $cauchy_vase->fit(pdl [1.46, 0.35, 3.85, 95.0]);
  }

  my ($A_fit, $Bs_fit, $n2_fit, $d_fit) = list $cauchy_fit;
  my $B_fit = $Bs_fit * 1e4;
  printf "Fit results (Cauchy SiO2 on Si):\n";
  printf "  A (index)      : %.4f   (true: 1.4600)\n", $A_fit;
  printf "  B (nm^2)       : %.1f   (true: 3400.0)\n", $B_fit;
  printf "  n_substrate    : %.4f   (true: 3.8700)\n", $n2_fit;
  printf "  Thickness (nm) : %.2f   (true: 100.00)\n", $d_fit;
  printf "  Iterations     : %d\n", $cauchy_vase->{iters};
  printf "  MSE            : %.4f\n", $cauchy_vase->mse($cauchy_fit);
}],

# ── Cauchy fit plot ──────────────────────────────────────────────────
[act => q|
  # Plot the Cauchy model fit
  $w2 = pgswin(size => [8,6], multi => [1,2]);

  $y_cauchy_fit = fresnel_cauchy($cauchy_fit, $x_sim);
  $psi_cf   = $y_cauchy_fit->slice("0:" . ($npts-1));
  $delta_cf = $y_cauchy_fit->slice("$npts:" . (2*$npts-1));

  $w2->plot(with => 'points', $wl_sim, $psi_sim,
            with => 'line',   $wl_sim, $psi_cf,
            {title => "Cauchy Fit: Psi (SiO2/Si)", xlabel => "Wavelength (nm)",
             ylabel => "Psi (deg)", legend => ['Data','Fit']});

  $w2->plot(with => 'points', $wl_sim, $delta_sim,
            with => 'line',   $wl_sim, $delta_cf,
            {title => "Cauchy Fit: Delta (SiO2/Si)", xlabel => "Wavelength (nm)",
             ylabel => "Delta (deg)", legend => ['Data','Fit']});
|],

# ══════════════════════════════════════════════════════════════════════
# Part 2: Multi-layer modeling
# ══════════════════════════════════════════════════════════════════════

[comment => q|
 MULTI-LAYER THIN FILM MODELING
 ==============================

 Real thin-film stacks have multiple layers. The Transfer
 Matrix Method (TMM) propagates electromagnetic waves
 through each interface and layer:

     Air / Film 1 / Film 2 / ... / Substrate

 Each layer has:
   - Complex refractive index N = n + ik
   - Thickness d (nm)
   - Dispersion model (Cauchy, Tauc-Lorentz, etc.)

 The next section fits a real three-layer stack measured
 with Variable Angle Spectroscopic Ellipsometry (VASE)
 at three angles of incidence (65, 70, 75 degrees):

     Air / Ta2O5 (Cauchy) / EMA roughness / Ta metal

 This uses the built-in TMM, Dispersion, and EMA modules.
|],

[act => q|
  # Load multi-layer sub-modules
  use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
  use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);
  use Physics::Ellipsometry::VASE::EMA qw(ema_linear);
  use Physics::Ellipsometry::VASE::Materials qw(load_material interpolate_material);

  # Locate demo data files shipped with this module
  $demo_dir = PDL::Demos::Ellipsometry::_data_dir();

  # Load Ta metal substrate optical constants (n,k vs wavelength)
  $ta_metal = load_material("${demo_dir}demo_ta_metal.mat");
  printf "Ta metal: %d pts, %.0f-%.0f nm\n",
         $ta_metal->{npts}, $ta_metal->{wav_min}, $ta_metal->{wav_max};
|],

[act => q|
  # Load real Woollam VASE data (3 angles, ~500 pts)
  $ml_vase = Physics::Ellipsometry::VASE->new(
      layers         => 3,
      circular_delta => 1,
      deriv_step     => 1e-3,
      min_deriv_step => 0.01,
  );
  $ml_vase->load_data("${demo_dir}demo_wafer.dat");
  delete $ml_vase->{sigma};  # use unweighted fit

  # Restrict wavelength range to where Ta metal data is available
  $ml_data = $ml_vase->{data};
  $wav_col = $ml_data->slice("(0),:")->flat;
  $wav_min = $ta_metal->{wav_min} > 320 ? $ta_metal->{wav_min} : 320;
  $wav_max = $ta_metal->{wav_max};
  $mask = ($wav_col >= $wav_min) & ($wav_col <= $wav_max);
  $idx  = which($mask);
  $ml_data = $ml_data->dice_axis(1, $idx)->sever;
  $ml_vase->{data} = $ml_data;

  printf "Loaded: %s\n", $ml_vase->{sample_name};
  printf "  %d data points, %.0f-%.0f nm\n",
         $ml_data->getdim(1),
         $ml_data->slice("(0),:")->min,
         $ml_data->slice("(0),:")->max;

  # Show unique angles
  $ml_angles = $ml_data->slice("(1),:")->flat;
  my %seen; @unique_ang = sort { $a <=> $b } grep { !$seen{$_}++ } list $ml_angles;
  printf "  Angles: %s deg\n", join(", ", map { sprintf("%.1f", $_) } @unique_ang);
|],

[act => q|
  # Define multi-layer model: Air / Ta2O5 (Cauchy) / EMA / Ta metal
  # Fit parameters (6 total, scaled to order ~1):
  #   [0] A         - Cauchy coefficient A
  #   [1] B_s       - Cauchy B * 100
  #   [2] C_s       - Cauchy C * 10000
  #   [3] d_ta2o5_s - Ta2O5 thickness / 100 (nm)
  #   [4] d_ema_s   - EMA roughness thickness (nm)
  #   [5] vf_void   - volume fraction of void in EMA layer

  sub multilayer_model {
      my ($params, $x_data) = @_;
      my $A       = $params->at(0);
      my $B       = $params->at(1) / 100;
      my $C       = $params->at(2) / 10000;
      my $d_film  = abs($params->at(3)) * 100;
      my $d_ema   = abs($params->at(4)) * 1.0;
      my $vf_void = $params->at(5);
      $vf_void = 0.01  if $vf_void < 0.01;
      $vf_void = 0.999 if $vf_void > 0.999;

      my $lambda = $x_data->slice(",(0)")->flat;
      my $theta  = $x_data->slice(",(1)")->flat;

      # Layer 1: Ta2O5 via Cauchy dispersion
      my ($n1, $k1) = cauchy_nk($lambda, $A, $B, $C);
      my $N1 = $n1 + i() * $k1;

      # Layer 2: EMA (Ta2O5 + void) via linear mixing
      my $eps_film = $N1**2;
      my $eps_void = pdl(1.0) + i() * pdl(0.0);
      my $N2 = sqrt(ema_linear($eps_film, $eps_void, $vf_void));

      # Substrate: Ta metal (point-by-point interpolation)
      my ($n_ta, $k_ta) = interpolate_material($ta_metal, $lambda);
      my $N3 = $n_ta + i() * $k_ta;

      # Ambient
      my $N0 = pdl(1.0) + i() * pdl(0.0);

      # TMM for the full stack
      my ($psi, $delta) = psi_delta(
          $lambda, $theta,
          [$N0, $N1, $N2, $N3],
          [$d_film, $d_ema],
      );

      return $psi->append($delta);
  }

  print "Multi-layer model defined:\n";
  print "  Air / Ta2O5 (Cauchy) / EMA roughness / Ta metal\n";
  print "  6 fit parameters: A, B, C, d_Ta2O5, d_EMA, vf_void\n";
|],

[act => q{
  # Fit the multi-layer model to the real 3-angle VASE data
  $ml_vase->set_model(\&multilayer_model);

  # Grid search over thickness for a good starting point
  # (thin-film interference creates many local minima in thickness)
  $ml_x = $ml_data->slice("0:1,:")->xchg(0,1);
  $ml_y = $ml_data->slice("(2),:")->flat->append($ml_data->slice("(3),:")->flat);
  $ml_npts = $ml_data->getdim(1);
  $ml_delta_data = $ml_data->slice("(3),:")->flat;

  $best_d = 1.96; $best_cost = 1e30;
  for my $d_s (map { $_ * 0.02 + 1.5 } (0..50)) {
      my $p = pdl [2.10, 1.0, 0.1, $d_s, 1.0, 0.80];
      my $ym = multilayer_model($p, $ml_x);
      my $dm = $ym->slice("$ml_npts:" . (2*$ml_npts-1));
      my $diff = $dm - $ml_delta_data;
      $dm -= 360.0 * rint($diff / 360.0);
      my $cost = sum(($ml_y - $ym)**2)->sclr;
      if ($cost < $best_cost) { $best_cost = $cost; $best_d = $d_s; }
  }
  printf "Grid search: best thickness = %.0f nm (d_s = %.2f)\n", $best_d * 100, $best_d;

  # Levenberg-Marquardt refinement from the grid-search starting point
  $ml_guess = pdl [2.10, 1.0, 0.1, $best_d, 1.0, 0.80];
  print "Fitting with LM refinement...\n";

  eval { $ml_fit = $ml_vase->fit($ml_guess); };
  if ($@ || !defined $ml_fit) {
      print "  LM from grid best did not converge, trying refined guess...\n";
      $ml_fit = $ml_vase->fit(pdl [2.12, 1.8, 0.1, $best_d, 1.0, 0.50]);
  }

  # Unpack results
  my $A_ml       = $ml_fit->at(0);
  my $B_ml       = $ml_fit->at(1) / 100;
  my $C_ml       = $ml_fit->at(2) / 10000;
  my $d_ta2o5    = abs($ml_fit->at(3)) * 1000;  # Angstroms
  my $d_ema_fit  = abs($ml_fit->at(4)) * 10;    # Angstroms
  my $vf_ml      = $ml_fit->at(5);
  $vf_ml = 0.01  if $vf_ml < 0.01;
  $vf_ml = 0.999 if $vf_ml > 0.999;

  my $n600 = $A_ml + $B_ml / 0.6**2 + $C_ml / 0.6**4;

  printf "\nMulti-layer fit results:\n";
  printf "  Ta2O5 thickness : %.1f Angstrom (%.1f nm)\n", $d_ta2o5, $d_ta2o5/10;
  printf "  EMA roughness   : %.1f Angstrom (%.2f nm)\n", $d_ema_fit, $d_ema_fit/10;
  printf "  Void fraction   : %.1f%%\n", $vf_ml * 100;
  printf "  Cauchy A        : %.4f\n", $A_ml;
  printf "  n(600nm)        : %.4f\n", $n600;
  printf "  Iterations      : %d\n", $ml_vase->{iters};
  printf "  MSE             : %.4f\n", $ml_vase->mse($ml_fit, nparams => 6);
}],

# ── Multi-layer fit plot ─────────────────────────────────────────────
[act => q|
  # Plot multi-angle fit: data points vs model curves
  # Evaluate model at the fitted parameters
  $ml_x = $ml_data->slice("0:1,:")->xchg(0,1);
  $ml_ym = multilayer_model($ml_fit, $ml_x);
  $ml_npts = $ml_data->getdim(1);
  $ml_psi_fit   = $ml_ym->slice("0:" . ($ml_npts-1));
  $ml_delta_fit = $ml_ym->slice("$ml_npts:" . (2*$ml_npts-1));
  $ml_wav = $ml_data->slice("(0),:")->flat;
  $ml_psi_data   = $ml_data->slice("(2),:")->flat;
  $ml_delta_data = $ml_data->slice("(3),:")->flat;

  # Separate data by angle for color-coded plotting
  @ml_psi_args = (); @ml_delta_args = ();
  @ang_labels = ();
  for my $ang (@unique_ang) {
      my $m = ($ml_angles == $ang);
      my $ii = which($m);
      my $wl_a   = $ml_wav->index($ii);
      my $psi_d  = $ml_psi_data->index($ii);
      my $del_d  = $ml_delta_data->index($ii);
      my $psi_f  = $ml_psi_fit->index($ii);
      my $del_f  = $ml_delta_fit->index($ii);

      push @ang_labels, sprintf("%.0f data", $ang), sprintf("%.0f fit", $ang);

      push @ml_psi_args, (with => 'points', $wl_a, $psi_d);
      push @ml_psi_args, (with => 'line',   $wl_a, $psi_f);

      push @ml_delta_args, (with => 'points', $wl_a, $del_d);
      push @ml_delta_args, (with => 'line',   $wl_a, $del_f);
  }

  # Plot Psi panel
  $w3 = pgswin(size => [9,6], multi => [1,2]);
  $w3->plot(@ml_psi_args,
    {title => "Air/Ta2O5/EMA/Ta: Psi",
     xlabel => "Wavelength (nm)", ylabel => "Psi (deg)",
     legend => \@ang_labels});

  # Plot Delta panel
  $w3->plot(@ml_delta_args,
    {title => "Air/Ta2O5/EMA/Ta: Delta",
     xlabel => "Wavelength (nm)", ylabel => "Delta (deg)",
     legend => \@ang_labels});

  print "Multi-angle fit plotted: Psi and Delta vs wavelength.\n";
|],

# ── Conclusion ───────────────────────────────────────────────────────
[comment => q|
 This concludes the Physics::Ellipsometry::VASE demo.

 What we covered:
   - Creating and loading ellipsometry data
   - Linear model fitting with Levenberg-Marquardt
   - Single-layer Cauchy + Fresnel model
   - Multi-layer modeling with TMM, EMA, and tabulated data
   - Multi-angle VASE fitting of a real Ta2O5/Ta sample
   - Plotting fits with PDL::Graphics::Simple

 To learn more:
   perldoc Physics::Ellipsometry::VASE
   perldoc Physics::Ellipsometry::VASE::TMM
   perldoc Physics::Ellipsometry::VASE::Dispersion
   https://github.com/jtrujil43/Ellipsometry

 See the examples/ directory for Tauc-Lorentz oscillator
 models and publication-quality plotting with Gnuplot.
|],

);

sub demo { @demo }

sub done {'
  undef $w;
  undef $w2;
  undef $w3;
  undef $vase;
  undef $cauchy_vase;
  undef $ml_vase;
'}

1;

__END__

=encoding utf8

=head1 NAME

PDL::Demos::Ellipsometry - Interactive PDL demo for spectroscopic
ellipsometry analysis

=head1 SYNOPSIS

Launch from the C<perldl> or C<pdl2> shell:

    pdl> demo ellipsometry

Requires L<PDL::Graphics::Simple> for plotting.

=head1 DESCRIPTION

This demo provides a hands-on walkthrough of thin-film optical modelling
and Levenberg-Marquardt fitting using L<Physics::Ellipsometry::VASE> and
PDL.  It progresses from simple linear models to realistic multi-layer
structures, showing the code at each step and generating interactive
plots.

=head1 DEMO SECTIONS

The demo is divided into three parts of increasing complexity.  Each
part shows the code being executed, prints results to the terminal,
and produces plots via L<PDL::Graphics::Simple>.

=head2 Part 1 — Linear model (synthetic data)

Introduces the basic VASE workflow with a trivial linear model.  This
verifies the fitting infrastructure without any optics:

B<Step 1: Generate synthetic data>

    $wavelength = pdl [400, 410, 420, 430, 440];
    $angle      = 70 * ones(5);
    $psi        = 45.0 - 0.05 * $wavelength;
    $delta      = 80.0 + 0.10 * $wavelength;

B<Step 2: Write to a file and load into a VASE object>

    $vase = Physics::Ellipsometry::VASE->new(layers => 1);
    $data = $vase->load_data($tmpfile);

B<Step 3: Define and fit a linear model>

    sub linear_model {
        my ($params, $x) = @_;
        my ($a, $b, $c, $d) = map { $params->slice("($_)") } 0..3;
        my $wl  = $x->slice(",(0)")->flat;
        my $psi = $a - $b * $wl;
        my $del = $c + $d * $wl;
        return cat($psi, $del)->flat;
    }

    $vase->set_model(\&linear_model);
    $fit = $vase->fit(pdl [65, 0.05, 80, 0.1]);

B<Step 4: Plot> — two-panel plot of Psi and Delta vs wavelength, showing
data points and the fitted line.

=head2 Part 2 — Cauchy dispersion on Si (simulated data)

Introduces real thin-film physics: the Cauchy dispersion model combined
with Fresnel equations and thin-film interference.

B<The Cauchy model> predicts the refractive index of a transparent film:

    n(lambda) = A + B/lambda^2 + C/lambda^4

B<Step 1: Simulate realistic SiO2/Si data>

    $wl_sim = sequence(21) * 15 + 400;    # 400–700 nm
    $n_true = 1.46 + 3400.0 / $wl_sim**2;

B<Step 2: Define the Fresnel + Cauchy model> — computes Psi and Delta
from a single-layer Air/SiO2/Si stack using explicit Fresnel
coefficients, Snell's law, and thin-film phase thickness:

    sub fresnel_cauchy {
        my ($par, $x) = @_;
        my $n1 = $A + $B / $lam**2;          # Cauchy dispersion
        my $beta = (2*PI/$lam) * $n1 * $d * cos($th1);  # phase
        # ... Fresnel coefficients, Airy formula ...
        my $rho = $rp / $rs;
        my $psi = atan(abs($rho)) * (180/PI);
        my $delta = carg($rho) * (180/PI);
        return cat($psi->re, $delta->re)->flat->double;
    }

B<Step 3: Fit from a deliberately offset starting guess>

    $true_params = pdl [1.46, 0.34, 3.87, 100.0];  # A, B, n_sub, d
    $guess       = pdl [1.50, 0.50, 3.50,  80.0];  # wrong on purpose
    $cauchy_fit  = $cauchy_vase->fit($guess);

B<Step 4: Plot> — Psi and Delta panels comparing noisy simulated data
with the converged fit.

=head2 Part 3 — Multi-layer TMM fit (real VASE data)

The most advanced section: fits a three-layer model to real
multi-angle spectroscopic ellipsometry data using the built-in
TMM, Dispersion, EMA, and Materials sub-modules.

B<Sample structure:>

    Air / Ta2O5 (Cauchy) / EMA roughness / Ta metal substrate

B<Modules used:>

    use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);
    use Physics::Ellipsometry::VASE::EMA qw(ema_linear);
    use Physics::Ellipsometry::VASE::Materials qw(load_material
                                                   interpolate_material);

B<Step 1: Load tabulated Ta metal substrate>

    $ta_metal = load_material("${demo_dir}demo_ta_metal.mat");

B<Step 2: Load real Woollam VASE data> (three angles of incidence:
65°, 70°, 75°, ~500 data points):

    $ml_vase = Physics::Ellipsometry::VASE->new(
        layers => 3, circular_delta => 1,
    );
    $ml_vase->load_data("${demo_dir}demo_wafer.dat");

B<Step 3: Define the 6-parameter multi-layer model>

    sub multilayer_model {
        my ($params, $x_data) = @_;
        # Cauchy dispersion for Ta2O5
        my ($n1, $k1) = cauchy_nk($lambda, $A, $B, $C);
        # EMA roughness layer (Ta2O5 + void)
        my $N2 = sqrt(ema_linear($N1**2, $eps_void, $vf_void));
        # Ta metal substrate from tabulated data
        my ($n_ta, $k_ta) = interpolate_material($ta_metal, $lambda);
        # TMM for the full stack
        my ($psi, $delta) = psi_delta($lambda, $theta,
            [$N0, $N1, $N2, $N3], [$d_film, $d_ema]);
        return $psi->append($delta);
    }

B<Step 4: Grid search over thickness> to find the correct interference
order, then B<Levenberg-Marquardt refinement>:

    # Grid search
    for my $d_s (map { $_ * 0.02 + 1.5 } (0..50)) { ... }

    # LM refinement from grid-search starting point
    $ml_fit = $ml_vase->fit($ml_guess);

B<Step 5: Plot> — colour-coded multi-angle data and fit curves for both
Psi and Delta.

=head1 DATA FILES

Two data files are shipped alongside this module and used by the
multi-layer demo:

=over 4

=item F<demo_wafer.dat>

Woollam VASE measurement of a Ta2O5-on-Ta sample at three angles of
incidence.

=item F<demo_ta_metal.mat>

Point-by-point optical constants (n, k vs eV) for the tantalum metal
substrate.

=back

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::TMM>,
L<Physics::Ellipsometry::VASE::Dispersion>,
L<Physics::Ellipsometry::VASE::EMA>,
L<Physics::Ellipsometry::VASE::Materials>,
L<PDL::Demos>,
L<PDL::Fit::LM>,
L<PDL::Graphics::Simple>

=head1 AUTHOR

Jovan Trujillo E<lt>jtrujil1@asu.eduE<gt>

=cut
