package Physics::Ellipsometry::VASE;
use strict;
use warnings;
use PDL;
use PDL::Fit::LM;
use PDL::NiceSlice;
use PDL::Constants qw(PI);

our $VERSION = '1.03';

# Sub-modules (loaded on demand)
# use Physics::Ellipsometry::VASE::TMM;
# use Physics::Ellipsometry::VASE::Dispersion;
# use Physics::Ellipsometry::VASE::EMA;
# use Physics::Ellipsometry::VASE::Materials;
# use Physics::Ellipsometry::VASE::Parameter;
# use Physics::Ellipsometry::VASE::Optimizer;

# Constructor
sub new {
    my ($class, %args) = @_;
    my $self = {
        layers     => $args{layers} || 1,
        model      => $args{model}  || sub { die "Model not implemented" },
        data       => undef,
        # Fitting options
        deriv_step     => $args{deriv_step}     || 1e-4,
        min_deriv_step => $args{min_deriv_step} || 0.001,
        maxiter        => $args{maxiter}        || 500,
        eps            => $args{eps}            || 1e-7,
        # Delta handling
        circular_delta => $args{circular_delta} // 1,  # use circular residuals
        # LM regularization
        lm_reg_floor   => $args{lm_reg_floor}  || 1e-10,
    };
    bless $self, $class;
    return $self;
}

# Load data from file (auto-detects Woollam VASE format)
sub load_data {
    my ($self, $filename) = @_;
    open my $fh, '<', $filename or die "Cannot open $filename: $!";
    my @lines = <$fh>;
    close $fh;

    # Detect Woollam VASE format: line 2 starts with VASEmethod[
    my $is_woollam = (@lines >= 4 && $lines[1] =~ /^VASEmethod\[/);

    my @data;
    if ($is_woollam) {
        # Parse Woollam header (strip Windows \r)
        chomp(my $sample_name = $lines[0]);
        $sample_name =~ s/\r//g;
        $self->{sample_name} = $sample_name;

        if ($lines[1] =~ /^VASEmethod\[(.+)\]/) {
            $self->{vase_method} = $1;
        }

        if ($lines[2] =~ /^Original\[(.+)\]/) {
            $self->{original_file} = $1;
        }

        chomp(my $units = $lines[3]);
        $units =~ s/\r//g;
        $self->{units} = $units;

        # Data starts at line 5 (index 4)
        for my $i (4 .. $#lines) {
            my $line = $lines[$i];
            chomp $line;
            next if $line =~ /^\s*$/;
            my @fields = split ' ', $line;
            # Skip lines whose first field is not numeric (e.g. Mueller labels)
            next unless $fields[0] =~ /^[-+]?\d*\.?\d+([eE][-+]?\d+)?$/;
            push @data, \@fields;
        }
    } else {
        # Original format: skip #comments and blank lines
        for my $line (@lines) {
            next if $line =~ /^\s*#/;   # skip comment lines
            next if $line =~ /^\s*$/;    # skip blank lines
            my @fields = split ' ', $line;
            push @data, \@fields;
        }
    }

    my $data = pdl \@data;

    # Woollam files have 6 columns; extract sigma and keep standard 4
    if ($is_woollam && $data->getdim(0) >= 6) {
        $self->{sigma} = $data->(4:5,:);
        $data = $data->(0:3,:)->sever;
    }

    $self->{data} = $data;
    return $data;
}

# Set model function
sub set_model {
    my ($self, $model) = @_;
    $self->{model} = $model;
}

# Fit data to model
sub fit {
    my ($self, $initial_params, %opts) = @_;
    my $data = $self->{data};
    my $model = $self->{model};

    # data shape is (nfields, npts); dim0=fields, dim1=data points
    # Extract x as (npts, 2) so $x->(:,0)=wavelength, $x->(:,1)=angle
    my $x_data = $data->(0:1,:)->xchg(0,1);

    # Build y to match model output order: [psi_all, delta_all]
    my $psi_data   = $data->((2),:)->flat;
    my $delta_data = $data->((3),:)->flat;
    my $y_data = $psi_data->append($delta_data);
    my $npts = $psi_data->nelem;

    # Use measured uncertainties from Woollam data when available
    my $sigma;
    if (defined $self->{sigma}) {
        $sigma = $self->{sigma}->((0),:)->flat->append($self->{sigma}->((1),:)->flat);
    } else {
        $sigma = ones($y_data->nelem);
    }

    # lmfit sizes $dyda from $x->getdim(0), so pass a dummy x whose
    # first dimension equals the number of y values (2*npts)
    my $x_fit = sequence($y_data->nelem);

    # Wrapper: adapts user model to lmfit interface ($x, $par, $ym, $dyda)
    my $circular = $self->{circular_delta};
    my $fit_func = sub {
        my ($x, $par, $ym, $dyda) = @_;

        my $y_model = &$model($par, $x_data);
        
        # Apply circular delta residual alignment
        if ($circular) {
            my $delta_model = $y_model->slice("$npts:" . (2*$npts-1));
            my $diff = $delta_model - $delta_data;
            my $correction = 360.0 * rint($diff / 360.0);
            $delta_model -= $correction;
        }
        
        $ym .= $y_model;

        # Numerical partial derivatives via finite differences
        my $np  = $par->nelem;
        for my $i (0 .. $np - 1) {
            my $par_h = $par->copy;
            my $p_i = $par->slice("($i)")->sclr;
            my $eps = abs($p_i) * ($self->{deriv_step}) + 1e-10;
            $eps = $self->{min_deriv_step} if $eps < $self->{min_deriv_step};
            $par_h->slice("($i)") += $eps;
            my $y_pert = &$model($par_h, $x_data);
            if ($circular) {
                my $dm = $y_pert->slice("$npts:" . (2*$npts-1));
                my $diff2 = $dm - $delta_data;
                $dm -= 360.0 * rint($diff2 / 360.0);
            }
            $dyda->slice(",($i)") .= ($y_pert - $ym) / $eps;
        }
    };

    my ($ym, $finalp, $covar, $iters) = lmfit(
        $x_fit, $y_data, $sigma, $fit_func, $initial_params,
        {Maxiter => $self->{maxiter}, Eps => $self->{eps}}
    );

    $self->{covar} = $covar;
    $self->{iters} = $iters;
    $self->{ym}    = $ym;

    return $finalp;
}

# Calculate MSE (WVASE convention: sqrt(χ²/(2N-M)))
sub mse {
    my ($self, $fit_params, %opts) = @_;
    my $data  = $self->{data};
    my $model = $self->{model};
    my $nparams = $opts{nparams} // $fit_params->nelem;

    my $x_data = $data->(0:1,:)->xchg(0,1);
    my $npts   = $data->getdim(1);
    my $y_data = $data->((2),:)->flat->append($data->((3),:)->flat);

    my $y_fit = &$model($fit_params, $x_data);

    # Apply circular delta alignment for MSE calculation
    if ($self->{circular_delta}) {
        my $delta_data  = $data->((3),:)->flat;
        my $delta_model = $y_fit->slice("$npts:" . (2*$npts-1));
        my $diff = $delta_model - $delta_data;
        $delta_model -= 360.0 * rint($diff / 360.0);
    }

    my $chi2 = sum(($y_data - $y_fit)**2)->sclr;
    return sqrt($chi2 / (2*$npts - $nparams));
}

# Plot raw data with model fit overlay
sub plot {
    my ($self, $fit_params, %opts) = @_;
    require PDL::Graphics::Gnuplot;

    my $data  = $self->{data};
    my $model = $self->{model};

    my $wavelength = $data->((0),:)->flat;
    my $angles     = $data->((1),:)->flat;
    my $psi_data   = $data->((2),:)->flat;
    my $delta_data = $data->((3),:)->flat;

    # Evaluate model at fitted parameters
    my $x_data  = $data->(0:1,:)->xchg(0,1);
    my $y_model = &$model($fit_params, $x_data);
    my $npts    = $wavelength->nelem;
    my $psi_fit   = $y_model->slice("0:" . ($npts - 1));
    my $delta_fit = $y_model->slice("$npts:" . (2 * $npts - 1));

    my $output = $opts{output};
    my $title  = $opts{title} // 'VASE Fit Results';

    # Find unique angles for grouping
    my @unique_angles = sort { $a <=> $b }
                        do { my %s; grep { !$s{$_}++ } list $angles };

    # Color palette for multiple angles
    my @colors = ('#0072B2', '#D55E00', '#009E73', '#CC79A7', '#F0E442',
                  '#56B4E9', '#E69F00', '#000000');

    # Select terminal and construct gpwin
    my $gp;
    if ($output) {
        my ($term, @topts);
        if    ($output =~ /\.png$/i) { $term = "pngcairo"; @topts = (size => [900,700,"px"]) }
        elsif ($output =~ /\.pdf$/i) { $term = "pdfcairo"; @topts = (size => [7,5.5,"in"]) }
        elsif ($output =~ /\.svg$/i) { $term = "svg";      @topts = (size => [900,700,"px"]) }
        elsif ($output =~ /\.eps$/i) { $term = "epscairo" }
        else                         { $term = "pngcairo"; @topts = (size => [900,700,"px"]) }
        $gp = PDL::Graphics::Gnuplot::gpwin($term, output => $output, enhanced => 1, @topts);
    } else {
        $gp = PDL::Graphics::Gnuplot::gpwin(enhanced => 1);
    }

    # Multiplot: Psi on top, Delta on bottom
    $gp->multiplot(layout => [1, 2], title => $title);

    # Build plot curves grouped by angle
    my (@psi_curves, @delta_curves);
    for my $ai (0 .. $#unique_angles) {
        my $ang = $unique_angles[$ai];
        my $mask = ($angles == $ang);
        my $idx = which($mask);
        my $wl   = $wavelength->index($idx);
        my $psid = $psi_data->index($idx);
        my $deld = $delta_data->index($idx);
        my $psif = $psi_fit->index($idx);
        my $delf = $delta_fit->index($idx);
        my $col  = $colors[$ai % scalar @colors];
        my $label = sprintf("%.1f{/Symbol \260}", $ang);

        push @psi_curves,
            (with => 'points', legend => "$label data",
                pt => 7, ps => 0.6, lc => "rgb \"$col\"",
                $wl, $psid),
            (with => 'lines', legend => "$label fit",
                lw => 2, lc => "rgb \"$col\"",
                $wl, $psif);

        push @delta_curves,
            (with => 'points', legend => "$label data",
                pt => 7, ps => 0.6, lc => "rgb \"$col\"",
                $wl, $deld),
            (with => 'lines', legend => "$label fit",
                lw => 2, lc => "rgb \"$col\"",
                $wl, $delf);
    }

    # --- Psi panel ---
    $gp->plot(
        { title  => '{/Symbol Y} (Psi)',
          xlabel => '',
          ylabel => '{/Symbol Y} (deg)',
          key    => 'outside right' },
        @psi_curves,
    );

    # --- Delta panel ---
    $gp->plot(
        { title  => '{/Symbol D} (Delta)',
          xlabel => 'Wavelength (nm)',
          ylabel => '{/Symbol D} (deg)',
          key    => 'outside right' },
        @delta_curves,
    );

    $gp->end_multi;

    if ($output) {
        $gp->close;
        print "Plot saved to $output\n";
    }

    return $gp;
}

1;

__END__

=head1 NAME

Physics::Ellipsometry::VASE - Variable Angle Spectroscopic Ellipsometry analysis

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use PDL;
    use PDL::NiceSlice;
    use Physics::Ellipsometry::VASE;
    use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy);
    use Physics::Ellipsometry::VASE::EMA qw(ema_bruggeman);
    use Physics::Ellipsometry::VASE::Materials qw(load_material interpolate_material);
    use Physics::Ellipsometry::VASE::Optimizer qw(differential_evolution);

    # Create VASE fitter with built-in delta handling
    my $vase = Physics::Ellipsometry::VASE->new(
        layers         => 3,
        circular_delta => 1,       # circular residuals for Delta
        deriv_step     => 1e-3,
        min_deriv_step => 0.01,
    );
    $vase->load_data('measurement.dat');

    # Use built-in dispersion, EMA, TMM
    my $cauchy_fn = cauchy(A => 2.1, B => 0.01, C => 0.001);
    my $substrate = load_material('ta_pbp.mat');

    $vase->set_model(sub { ... });
    my $fitted = $vase->fit(pdl [...]);
    my $mse = $vase->mse($fitted, nparams => 6);
    $vase->plot($fitted, output => 'fit.png');

=head1 DESCRIPTION

Physics::Ellipsometry::VASE v1.03 provides a complete framework for
spectroscopic ellipsometry analysis including:

=over

=item * Transfer Matrix Method (VASE::TMM)

=item * Dispersion models: Cauchy, Sellmeier, Tauc-Lorentz, Drude, Genosc (VASE::Dispersion)

=item * EMA mixing: Linear, Bruggeman, Maxwell-Garnett (VASE::EMA)

=item * Material file loader with eV/nm conversion (VASE::Materials)

=item * Parameter bounds and vary/fix control (VASE::Parameter)

=item * Global optimizer: Differential Evolution (VASE::Optimizer)

=item * Circular Delta residuals in LM fitting

=item * Robust LM regularization (diagonal floor prevents singular matrices)

=back

=head1 METHODS

=head2 new

    my $vase = Physics::Ellipsometry::VASE->new(%args);

Constructor.  Accepts the following options: C<layers> (number of thin-film
layers), C<circular_delta> (enable circular Delta residuals),
C<deriv_step>, C<min_deriv_step>, C<maxiter>, C<eps>, C<lm_reg_floor>.

=head2 load_data

    my $data = $vase->load_data($filename);

Reads ellipsometry data from C<$filename>.  The format is auto-detected:

=over 4

=item B<Simple format>

Whitespace-separated columns.  Lines starting with C<#> are comments; blank
lines are skipped.

    # Wavelength(nm)  Angle(deg)  Psi(deg)  Delta(deg)
    400  70  45.0  120.0
    410  70  44.5  121.0

=item B<Woollam VASE format>

Recognised when line 2 starts with C<VASEmethod[>.  The four-line header is
parsed and stored as object attributes:

    $vase->{sample_name}    # line 1
    $vase->{vase_method}    # VASEmethod[...] content
    $vase->{original_file}  # Original[...] content
    $vase->{units}          # line 4 (e.g. "nm")

Columns 5-6 (sigma_psi, sigma_delta) are extracted into C<< $vase->{sigma} >>
and automatically used as weights during fitting.

=back

Returns a PDL piddle of shape C<(4, npts)> where the columns are wavelength,
angle, psi, delta.

=head2 set_model

    $vase->set_model(\&my_model);

Sets the model function used for fitting.  The function receives two
arguments:

    sub my_model {
        my ($params, $x) = @_;
        # $params - PDL piddle of fit parameters
        # $x      - PDL piddle of shape (npts, 2):
        #           column 0 = wavelength (nm)
        #           column 1 = angle of incidence (degrees)

        my $psi   = ...;  # compute psi   (npts values)
        my $delta = ...;  # compute delta (npts values)

        return cat($psi, $delta)->flat;   # concatenated 1-D piddle
    }

The return value B<must> be a flat piddle of length C<2*npts> with all psi
values followed by all delta values.

=head2 fit

    my $fitted_params = $vase->fit($initial_params);

Performs a Levenberg-Marquardt fit of the current model to the loaded data.

C<$initial_params> is a PDL piddle of starting parameter values.  Returns
a piddle of optimised parameters.

After fitting, the following attributes are available:

    $vase->{covar}  # covariance matrix (PDL)
    $vase->{iters}  # number of LM iterations
    $vase->{ym}     # model values at the fitted parameters

The fit uses relative-step finite differences for the numerical Jacobian
(step size C<|p_i| * 1e-7 + 1e-10>) and converges when the relative change
in chi-squared falls below 1e-7, or after 300 iterations.

=head2 mse

    my $mse = $vase->mse($fit_params, nparams => $n);

Calculates WVASE-convention mean squared error:
C<sqrt(chi2 / (2*npts - nparams))>.

=head2 plot

    $vase->plot($fit_params, %options);

Plots measured data with the model fit overlaid.  Requires
L<PDL::Graphics::Gnuplot> (loaded on demand).

Options:

=over 4

=item B<output>

Filename for the plot image.  The format is inferred from the extension:
C<.png>, C<.pdf>, C<.svg>, C<.eps>.  If omitted, an interactive window is
opened.

=item B<title>

Title string for the plot (default: C<"VASE Fit Results">).

=back

When multiple angles of incidence are present, each angle is plotted as a
separate colour-coded series.

=head1 EXAMPLES

The C<examples/> directory in the distribution contains:

=over 4

=item L<fit_linear.pl|https://github.com/jtrujil43/Ellipsometry/blob/main/examples/fit_linear.pl>

Minimal example fitting a linear dispersion model.

=item L<vase_test_fit.pl|https://github.com/jtrujil43/Ellipsometry/blob/main/examples/vase_test_fit.pl>

Cauchy thin-film model with complex Fresnel equations for Ta2O5 on Si.

=item L<vase_tauc_lorentz_fit.pl|https://github.com/jtrujil43/Ellipsometry/blob/main/examples/vase_tauc_lorentz_fit.pl>

Tauc-Lorentz oscillator model with numerical Kramers-Kronig integration.

=back

=head1 DEPENDENCIES

=over 4

=item L<PDL> (E<ge> 2.0)

=item L<PDL::Fit::LM>

=item L<PDL::NiceSlice>

=item L<PDL::Graphics::Gnuplot> (optional, for plotting)

=back

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE::Anisotropy>,
L<Physics::Ellipsometry::VASE::Dispersion>,
L<Physics::Ellipsometry::VASE::EMA>,
L<Physics::Ellipsometry::VASE::MagnetoOptic>,
L<Physics::Ellipsometry::VASE::Materials>,
L<Physics::Ellipsometry::VASE::Optimizer>,
L<Physics::Ellipsometry::VASE::Parameter>,
L<Physics::Ellipsometry::VASE::Temperature>,
L<Physics::Ellipsometry::VASE::TMM>,
L<PDL::Demos::Ellipsometry>

L<PDL>, L<PDL::Fit::LM>, L<PDL::Graphics::Gnuplot>

H. Fujiwara, I<Spectroscopic Ellipsometry: Principles and Applications>,
John Wiley & Sons, 2007.

G.E. Jellison and F.A. Modine, "Parameterization of the optical functions
of amorphous materials in the interband region", I<Appl. Phys. Lett.>
B<69>, 371 (1996).

=head1 AUTHOR

Jovan Trujillo C<< <jtrujil1 at asu.edu> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Jovan Trujillo.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.  See
L<https://dev.perl.org/licenses/> for details.

=cut
