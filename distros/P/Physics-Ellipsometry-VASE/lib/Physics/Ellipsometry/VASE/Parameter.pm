package Physics::Ellipsometry::VASE::Parameter;
use strict;
use warnings;
use PDL;
use Exporter 'import';

our @EXPORT_OK = qw(param params_to_pdl pdl_to_params make_fit_model get_values);

our $VERSION = '1.03';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::Parameter - Named parameters with bounds,
vary/fix control, and internal transformations for model fitting

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE;
    use Physics::Ellipsometry::VASE::Parameter qw(
        param params_to_pdl pdl_to_params make_fit_model get_values
    );

    # Define model parameters with physical constraints
    my @params = (
        param(name => 'thickness', value => 100.0,
              min  => 0.0, max => 500.0),
        param(name => 'n_cauchy_A', value => 2.1,
              min  => 1.0, max => 4.0),
        param(name => 'n_cauchy_B', value => 0.01,
              min  => 0.0, max => 1.0),
        param(name => 'angle_offset', value => 0.0, vary => 0),  # fixed
    );

    # Convert varying parameters to a PDL for fitting
    my $p0 = params_to_pdl(\@params);   # 3-element piddle (angle_offset excluded)

    # After fitting, update parameter values from the fitted PDL
    pdl_to_params(\@params, $fitted_pdl);

    # Read back all values (fixed and varying)
    my @values = get_values(\@params);
    printf "thickness = %.2f nm\n", $values[0];

=head1 DESCRIPTION

Levenberg-Marquardt fitting operates on an unconstrained vector of real
numbers, but physical model parameters often have hard constraints:
thicknesses cannot be negative, refractive indices must stay within
sensible ranges, and some parameters (e.g., a known substrate angle)
should be held fixed during the fit.

Physics::Ellipsometry::VASE::Parameter provides a lightweight parameter
object that addresses these needs:

=over 4

=item B<Named parameters>

Each parameter carries a human-readable name for identification in
reports and diagnostics.

=item B<Bounds enforcement via smooth transformations>

Rather than clamping (which creates discontinuous derivatives and
confuses gradient-based optimizers), bounded parameters are mapped to
an unbounded internal space using invertible transformations:

=over 4

=item I<Two-sided bounds> (min and max) — logit transform:

    internal = ln( (v − min) / (max − v) )

=item I<Lower bound only> — log transform:

    internal = ln( v − min )

=item I<Upper bound only> — negative log transform:

    internal = −ln( max − v )

=back

The optimizer works in internal space where all parameters are
unconstrained.  The transforms are smooth (C∞), so the Jacobian
computed by finite differences remains well-behaved near the bounds.

=item B<Vary/fix control>

Parameters with C<< vary => 0 >> are held at their current value and
excluded from the fitted PDL vector.  This lets you freeze known
quantities (e.g., substrate optical constants) without rewriting the
model function.

=item B<Scaling>

An optional C<scale> factor adjusts the internal representation for
numerical conditioning.  This is useful when parameters span very
different orders of magnitude.

=back

=head1 FUNCTIONS

=head2 param

    my $p = param(
        name  => 'thickness',
        value => 100.0,
        min   => 0.0,
        max   => 500.0,
        vary  => 1,
        scale => 1.0,
    );

Creates a parameter hashref.  All keyword arguments are optional:

=over 4

=item C<name> — descriptive name (default: C<'unnamed'>)

=item C<value> — current value (default: 0.0)

=item C<min> — lower bound, or C<undef> for unbounded below

=item C<max> — upper bound, or C<undef> for unbounded above

=item C<vary> — 1 to vary during fitting, 0 to hold fixed (default: 1)

=item C<scale> — internal scaling factor (default: 1.0)

=back

    # Unbounded parameter
    param(name => 'offset', value => 0.5)

    # Lower-bounded only (e.g., thickness ≥ 0)
    param(name => 'thickness', value => 50.0, min => 0.0)

    # Fixed parameter (excluded from fit)
    param(name => 'angle', value => 70.0, vary => 0)

=head2 params_to_pdl

    my $pdl = params_to_pdl(\@params);

Extracts the B<varying> parameters from the list, transforms each to
its internal (unbounded) representation, and returns a 1-D PDL piddle
suitable for passing to the fitter.  Fixed parameters are skipped.

=head2 pdl_to_params

    pdl_to_params(\@params, $fitted_pdl);

The inverse of L</params_to_pdl>.  Takes a fitted PDL of internal
values and maps each back to physical space, updating the C<value>
field of each varying parameter in-place.  Fixed parameters are
unchanged.

=head2 get_values

    my @vals = get_values(\@params);

Returns the current C<value> of every parameter (both fixed and
varying), preserving order.  Convenient for building a full parameter
PDL or for printing a summary.

=head2 make_fit_model

    my $wrapped = make_fit_model(\@params, \&full_model);

Creates a closure that bridges the gap between the fitter (which sees
only varying parameters in internal space) and the user's model
function (which expects the full physical parameter vector).

The returned closure has the signature expected by
L<Physics::Ellipsometry::VASE/fit>:

    $wrapped->($vary_pdl, $x_data)  →  $y_pdl

Internally it:

=over 4

=item 1.

Transforms each element of C<$vary_pdl> from internal to physical
space using the inverse bound transform.

=item 2.

Inserts fixed parameter values at the correct positions.

=item 3.

Calls C<$full_model-E<gt>($all_params_pdl, $x_data)>.

=back

=head1 COMPLETE FITTING EXAMPLE

    use PDL;
    use Physics::Ellipsometry::VASE;
    use Physics::Ellipsometry::VASE::Parameter qw(
        param params_to_pdl pdl_to_params make_fit_model get_values
    );

    # 1. Define parameters with physical bounds
    my @params = (
        param(name => 'd',   value => 80.0,  min => 0, max => 500),
        param(name => 'A',   value => 2.0,   min => 1, max => 4),
        param(name => 'B',   value => 0.01,  min => 0, max => 1),
        param(name => 'C',   value => 0.0,   vary => 0),  # fix at zero
    );

    # 2. Write the model in terms of a full parameter vector
    sub my_model {
        my ($all_p, $x) = @_;
        my ($d, $A, $B, $C) = ($all_p->at(0), $all_p->at(1),
                                $all_p->at(2), $all_p->at(3));
        # ... compute psi, delta using TMM ...
        return cat($psi, $delta)->flat;
    }

    # 3. Wrap the model to handle bounds and fixed params
    my $wrapped = make_fit_model(\@params, \&my_model);

    # 4. Fit — optimizer sees only 3 unconstrained variables
    my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
    $vase->load_data('sample.dat');
    $vase->set_model($wrapped);

    my $p0 = params_to_pdl(\@params);
    my $fitted = $vase->fit($p0);

    # 5. Map fitted values back to physical space
    pdl_to_params(\@params, $fitted);
    for my $p (@params) {
        printf "%-12s = %8.4f  %s\n",
               $p->{name}, $p->{value},
               $p->{vary} ? '' : '(fixed)';
    }

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::Optimizer>

=cut

sub param {
    my (%args) = @_;
    return {
        name   => $args{name}  // 'unnamed',
        value  => $args{value} // 0.0,
        min    => $args{min},           # undef = unbounded below
        max    => $args{max},           # undef = unbounded above
        vary   => $args{vary}  // 1,    # 1=vary, 0=fixed
        scale  => $args{scale} // 1.0,  # internal scaling factor
    };
}

# Convert parameter list to internal PDL for fitting (only varying params)
sub params_to_pdl {
    my ($params) = @_;  # arrayref of param hashes
    my @values;
    for my $p (@$params) {
        next unless $p->{vary};
        my $internal = _value_to_internal($p);
        push @values, $internal;
    }
    return pdl(\@values);
}

# Update parameter list from fitted PDL values
sub pdl_to_params {
    my ($params, $fitted_pdl) = @_;
    my $idx = 0;
    for my $p (@$params) {
        next unless $p->{vary};
        my $internal = $fitted_pdl->at($idx);
        $p->{value} = _internal_to_value($p, $internal);
        $idx++;
    }
    return $params;
}

# Get all parameter values as a list (both fixed and varying)
sub get_values {
    my ($params) = @_;
    return map { $_->{value} } @$params;
}

# Create a model wrapper that handles parameter transformation
# Returns a closure compatible with VASE fit()
sub make_fit_model {
    my ($params, $full_model) = @_;
    # $full_model receives ($all_values_pdl, $x_data)
    # Returns wrapper that receives ($vary_pdl, $x_data)

    return sub {
        my ($vary_pdl, $x_data) = @_;
        # Reconstruct full parameter vector
        my @all_values;
        my $vary_idx = 0;
        for my $p (@$params) {
            if ($p->{vary}) {
                my $internal = $vary_pdl->at($vary_idx);
                push @all_values, _internal_to_value($p, $internal);
                $vary_idx++;
            } else {
                push @all_values, $p->{value};
            }
        }
        my $all_pdl = pdl(\@all_values);
        return &$full_model($all_pdl, $x_data);
    };
}

# Transform value to internal (unbounded) space for fitting
sub _value_to_internal {
    my ($p) = @_;
    my $v = $p->{value};

    if (defined $p->{min} && defined $p->{max}) {
        # Bounded: use logit transform
        my $range = $p->{max} - $p->{min};
        my $norm = ($v - $p->{min}) / $range;
        # Clamp to avoid log(0)
        $norm = 0.001 if $norm < 0.001;
        $norm = 0.999 if $norm > 0.999;
        return log($norm / (1.0 - $norm)) * $p->{scale};
    } elsif (defined $p->{min}) {
        # Lower bounded: use log transform
        my $shifted = $v - $p->{min};
        $shifted = 0.001 if $shifted < 0.001;
        return log($shifted) * $p->{scale};
    } elsif (defined $p->{max}) {
        # Upper bounded: use negative log transform
        my $shifted = $p->{max} - $v;
        $shifted = 0.001 if $shifted < 0.001;
        return -log($shifted) * $p->{scale};
    } else {
        # Unbounded
        return $v * $p->{scale};
    }
}

# Transform from internal (unbounded) space back to actual value
sub _internal_to_value {
    my ($p, $internal) = @_;
    my $x = $internal / ($p->{scale} || 1.0);

    if (defined $p->{min} && defined $p->{max}) {
        # Inverse logit (sigmoid)
        my $range = $p->{max} - $p->{min};
        my $sigmoid = 1.0 / (1.0 + exp(-$x));
        return $p->{min} + $range * $sigmoid;
    } elsif (defined $p->{min}) {
        # Inverse log
        return $p->{min} + exp($x);
    } elsif (defined $p->{max}) {
        # Inverse negative log
        return $p->{max} - exp(-$x);
    } else {
        # Unbounded
        return $x;
    }
}

1;
