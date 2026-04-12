package Physics::Ellipsometry::VASE;
use strict;
use warnings;
use PDL;
use PDL::Fit::LM;
use PDL::NiceSlice;

our $VERSION = '0.02';

# Constructor
sub new {
    my ($class, %args) = @_;
    my $self = {
        layers => $args{layers} || 1,
        model  => $args{model}  || sub { die "Model not implemented" },
        data   => undef,
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
        # Parse Woollam header
        chomp(my $sample_name = $lines[0]);
        $self->{sample_name} = $sample_name;

        if ($lines[1] =~ /^VASEmethod\[(.+)\]/) {
            $self->{vase_method} = $1;
        }

        if ($lines[2] =~ /^Original\[(.+)\]/) {
            $self->{original_file} = $1;
        }

        chomp(my $units = $lines[3]);
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
    my ($self, $initial_params) = @_;
    my $data = $self->{data};
    my $model = $self->{model};

    # data shape is (nfields, npts); dim0=fields, dim1=data points
    # Extract x as (npts, 2) so $x->(:,0)=wavelength, $x->(:,1)=angle
    my $x_data = $data->(0:1,:)->xchg(0,1);

    # Build y to match model output order: [psi_all, delta_all]
    my $y_data = $data->((2),:)->flat->append($data->((3),:)->flat);

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
    my $fit_func = sub {
        my ($x, $par, $ym, $dyda) = @_;

        my $y_model = &$model($par, $x_data);
        $ym .= $y_model;

        # Numerical partial derivatives via finite differences
        my $np  = $par->nelem;
        for my $i (0 .. $np - 1) {
            my $par_h = $par->copy;
            my $p_i = $par->slice("($i)")->sclr;
            my $eps = abs($p_i) * 1e-7 + 1e-10;
            $par_h->slice("($i)") += $eps;
            $dyda->slice(",($i)") .= (&$model($par_h, $x_data) - $y_model) / $eps;
        }
    };

    my ($ym, $finalp, $covar, $iters) = lmfit(
        $x_fit, $y_data, $sigma, $fit_func, $initial_params,
        {Maxiter => 300, Eps => 1e-7}
    );

    $self->{covar} = $covar;
    $self->{iters} = $iters;
    $self->{ym}    = $ym;

    return $finalp;
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
          key    => 'top right box' },
        @psi_curves,
    );

    # --- Delta panel ---
    $gp->plot(
        { title  => '{/Symbol D} (Delta)',
          xlabel => 'Wavelength (nm)',
          ylabel => '{/Symbol D} (deg)',
          key    => 'top left box' },
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

Physics::Ellipsometry::VASE - Variable Angle Spectroscopic Ellipsometry data fitting

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use PDL;
    use PDL::NiceSlice;
    use Physics::Ellipsometry::VASE;

    # Create a VASE fitter for a single-layer model
    my $vase = Physics::Ellipsometry::VASE->new(layers => 1);

    # Load experimental data (auto-detects Woollam format)
    $vase->load_data('measurement.dat');

    # Define an optical model
    sub cauchy_model {
        my ($params, $x) = @_;
        my $wavelength = $x->(:,0);   # nm
        my $psi   = $params->(0) + $params->(1) / $wavelength**2;
        my $delta = $params->(2) + $params->(3) * $wavelength;
        return cat($psi, $delta)->flat;
    }

    $vase->set_model(\&cauchy_model);

    my $fitted = $vase->fit(pdl [45, 1e4, 120, 0.01]);

    # Plot results (requires PDL::Graphics::Gnuplot)
    $vase->plot($fitted, output => 'fit.png');

=head1 DESCRIPTION

Physics::Ellipsometry::VASE provides a framework for fitting optical thin-film
models to variable angle spectroscopic ellipsometry (VASE) data using the
Levenberg-Marquardt algorithm.

Ellipsometry measures the change in polarization state of light reflected from
a sample surface.  The two measured quantities are B<Psi> (related to the
amplitude ratio of p- and s-polarized reflectances) and B<Delta> (the phase
difference).  By fitting a physical model to these measurements across
wavelength and angle of incidence, one can extract optical constants (refractive
index, extinction coefficient) and film thicknesses.

The module handles:

=over 4

=item *

Loading data in both simple whitespace-delimited format and the native
J.A. Woollam VASE instrument format (auto-detected).

=item *

Automatic numerical Jacobian computation via relative-step finite differences.

=item *

Weighted fitting using measured uncertainties (sigma columns in Woollam files).

=item *

Multi-angle plotting of data and fit overlays via L<PDL::Graphics::Gnuplot>.

=back

=head1 CONSTRUCTOR

=head2 new

    my $vase = Physics::Ellipsometry::VASE->new(%args);

Creates a new VASE analysis object.

=over 4

=item B<layers> (optional, default 1)

Number of thin-film layers in the optical model.  Currently informational;
the actual layer structure is encoded in the user-supplied model function.

=item B<model> (optional)

A code reference for the model function.  Can also be set later with
L</set_model>.

=back

=head1 METHODS

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

=head1 DATA FORMAT

=head2 Simple Format

    # Wavelength(nm)  Angle(deg)  Psi(deg)  Delta(deg)
    400  70  45.0  120.0

=head2 Woollam VASE Format

    sample_name
    VASEmethod[EllipsometerType=4, ...]
    Original[filename.dat]
    nm
    400.000  70.000  45.000  120.000  0.010  0.020
    ...

Columns: wavelength, angle, psi, delta, sigma_psi, sigma_delta.

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

__END__

=head1 NAME

Physics::Ellipsometry::VASE - Variable Angle Spectroscopic Ellipsometry data fitting

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PDL;
    use PDL::NiceSlice;
    use Physics::Ellipsometry::VASE;

    my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
    $vase->load_data('data.dat');

    sub my_model {
        my ($params, $x) = @_;
        my $a = $params->(0);
        my $b = $params->(1);
        my $c = $params->(2);
        my $d = $params->(3);
        my $wavelength = $x->(:,0);

        my $psi   = $a - $b * $wavelength;
        my $delta = $c + $d * $wavelength;

        return cat($psi, $delta)->flat;
    }

    $vase->set_model(\&my_model);

    my $fit_params = $vase->fit(pdl [65, 0.05, 80, 0.1]);
    print "Fitted: $fit_params\n";

=head1 DESCRIPTION

Physics::Ellipsometry::VASE provides Levenberg-Marquardt fitting of
user-defined optical models to variable angle spectroscopic ellipsometry
(VASE) data.  It wraps L<PDL::Fit::LM> and handles the bookkeeping of
mapping between the simple user model interface and the lmfit calling
convention, including automatic numerical computation of the Jacobian
via finite differences.

Ellipsometry measures the change in polarization state of light reflected
from a surface.  The two measured quantities are B<Psi> (amplitude ratio)
and B<Delta> (phase difference).  This module fits models that predict
both Psi and Delta simultaneously as a function of wavelength and
angle of incidence.

=head1 DATA FORMAT

Input files should contain whitespace-separated columns:

    # Wavelength(nm)  Angle(deg)  Psi(deg)  Delta(deg)
    400  70  45.0  120.0
    410  70  44.5  121.0

Lines beginning with C<#> and blank lines are skipped.

=head1 MODEL FUNCTIONS

A model function receives two arguments and must return a single
flattened PDL piddle:

    sub model {
        my ($params, $x) = @_;

        # $params: PDL piddle of fit parameters
        # $x:      PDL piddle of shape (npoints, 2)
        #          $x->(:,0) = wavelength (nm)
        #          $x->(:,1) = angle of incidence (deg)

        my $psi   = ...;   # compute Psi  (npoints)
        my $delta = ...;   # compute Delta (npoints)

        return cat($psi, $delta)->flat;
    }

The Jacobian (partial derivatives with respect to parameters) is
computed automatically via numerical finite differences.

=head1 METHODS

=head2 new

    my $vase = Physics::Ellipsometry::VASE->new(%args);

Constructor.  Accepts:

=over 4

=item layers

Number of layers in the optical model (default: 1).

=item model

Optional code reference to a model function.

=back

=head2 load_data

    $vase->load_data($filename);

Reads ellipsometry data from a whitespace-delimited file.
Returns the loaded data as a PDL piddle.

=head2 set_model

    $vase->set_model(\&model_func);

Sets the model function used for fitting.

=head2 fit

    my $fitted_params = $vase->fit($initial_params);

Performs Levenberg-Marquardt fitting.  C<$initial_params> is a PDL
piddle of initial guesses.  Returns a PDL piddle of fitted parameters.

=head2 plot

    $vase->plot($fit_params);
    $vase->plot($fit_params, output => 'fit.png');
    $vase->plot($fit_params, output => 'fit.pdf', title => 'My Fit');

Plots raw data points with model fit overlay in a two-panel layout
(Psi on top, Delta on bottom).  Requires L<PDL::Graphics::Gnuplot>.

Options:

=over 4

=item output

File path for saving the plot.  Format is inferred from the extension
(C<.png>, C<.pdf>, C<.svg>, C<.eps>).  If omitted, displays an
interactive window.

=item title

Overall plot title (default: C<VASE Fit Results>).

=back

=head1 DEPENDENCIES

L<PDL>, L<PDL::Fit::LM>, L<PDL::NiceSlice>

L<PDL::Graphics::Gnuplot> is required only for the C<plot> method.

=head1 AUTHOR

jtrujil1

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
