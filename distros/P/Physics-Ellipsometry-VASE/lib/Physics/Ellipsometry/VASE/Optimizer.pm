package Physics::Ellipsometry::VASE::Optimizer;
use strict;
use warnings;
use PDL;
use Exporter 'import';

our @EXPORT_OK = qw(differential_evolution grid_search);

our $VERSION = '1.03';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::Optimizer - Global optimization algorithms
for ellipsometry model fitting

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::Optimizer qw(differential_evolution
                                                   grid_search);

    # Define an objective function (e.g., MSE from a VASE model)
    my $objective = sub {
        my ($params_pdl) = @_;
        # ... evaluate model, return scalar cost (chi², MSE, etc.)
    };

    # Differential Evolution — find global minimum
    my ($best, $cost) = differential_evolution(
        objective => $objective,
        bounds    => [ [0, 500], [1, 4], [0, 1] ],
        verbose   => 1,
    );
    printf "DE result: cost=%.4f  params=%s\n", $cost, $best;

    # Grid Search — scan a 1-D or 2-D landscape
    my ($best_g, $cost_g) = grid_search(
        objective   => $objective,
        base_params => pdl([100, 2.0, 0.01]),
        grid        => [ { index => 0, min => 10, max => 300, steps => 30 } ],
    );

=head1 DESCRIPTION

Levenberg-Marquardt (LM) is a local optimizer — it converges quickly
but can get trapped in local minima, especially when the initial
parameter guesses are far from the true values.  This is a common
problem in ellipsometry, where the cost surface often has multiple
minima due to thin-film interference periodicity (thickness ambiguity)
and correlations between dispersion parameters.

Physics::Ellipsometry::VASE::Optimizer provides B<global> search
strategies that explore the parameter space broadly and return a
good starting point for subsequent LM refinement.  The typical
workflow is:

    1. Global search  →  approximate minimum
    2. LM refinement  →  precise, converged fit

=head1 FUNCTIONS

=head2 differential_evolution

    my ($best_pdl, $best_cost) = differential_evolution(%args);

B<Differential Evolution> (DE/rand/1/bin) is a population-based
stochastic optimizer introduced by Storn and Price (1997).  It
maintains a population of candidate solutions and evolves them through
mutation, crossover, and selection — similar in spirit to a genetic
algorithm, but operating directly on real-valued vectors with no
encoding step.

B<How it works:>

=over 4

=item 1. B<Initialisation> — random population within the bounds.

=item 2. B<Mutation> — for each member I<x_i>, create a mutant vector:

    v = x_r0 + F · (x_r1 − x_r2)

where r0, r1, r2 are distinct random population members and I<F> is
the mutation factor controlling the step size.

=item 3. B<Crossover> — mix the mutant with the current member using
binomial crossover with probability I<CR>.

=item 4. B<Selection> — keep the trial if it has lower cost.

=item 5. B<Convergence> — stop when the population diversity (relative
spread across each dimension) falls below the tolerance, or after
C<maxiter> generations.

=back

B<Arguments:>

=over 4

=item C<objective> (required)

Code reference.  Receives a PDL piddle of parameters and returns a
scalar cost value (lower is better).

=item C<bounds> (required)

Arrayref of C<[min, max]> pairs, one per parameter dimension.

=item C<pop_size>

Population size.  Default: 30, but automatically raised to at least
5× the number of dimensions.

=item C<F>

Mutation factor (0 to 2).  Default: 0.7.  Higher values explore more
aggressively; lower values exploit locally.

=item C<CR>

Crossover probability (0 to 1).  Default: 0.9.  Higher values mix
more dimensions per trial.

=item C<maxiter>

Maximum number of generations.  Default: 200.

=item C<tol>

Convergence tolerance on population diversity.  Default: 1e-6.

=item C<seed>

Optional random seed for reproducibility.

=item C<verbose>

Print progress every 20 generations.  Default: 0.

=back

B<Returns:> C<($best_pdl, $best_cost)>.

B<Example — find thickness and Cauchy A for a single-layer film:>

    use Physics::Ellipsometry::VASE;
    use Physics::Ellipsometry::VASE::Optimizer qw(differential_evolution);
    use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
    use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);

    my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
    $vase->load_data('sample.dat');

    my $objective = sub {
        my ($p) = @_;
        my $d = $p->at(0);
        my $A = $p->at(1);
        my ($n, $k) = cauchy_nk($vase->{wavelength}, $A, 0.01, 0.0);
        my $N_film = $n + i() * $k;
        my ($psi, $delta) = psi_delta(
            $vase->{wavelength}, $vase->{angle},
            [$vase->{N_air}, $N_film, $vase->{N_sub}], [$d],
        );
        my $resid = ($psi - $vase->{psi_data})**2
                  + ($delta - $vase->{delta_data})**2;
        return sum($resid)->sclr;
    };

    my ($best, $cost) = differential_evolution(
        objective => $objective,
        bounds    => [ [1, 500], [1.3, 3.0] ],   # thickness, Cauchy A
        pop_size  => 50,
        maxiter   => 300,
        verbose   => 1,
        seed      => 42,
    );

    printf "Best: d=%.1f nm, A=%.4f  (cost=%.4f)\n",
           $best->at(0), $best->at(1), $cost;

    # Now refine with LM
    $vase->set_model(sub { ... });
    my $refined = $vase->fit($best);

=head2 grid_search

    my ($best_pdl, $best_cost) = grid_search(%args);

B<Grid search> systematically evaluates the objective function at
every point on a regularly spaced grid over one or more parameter
dimensions.  All parameters not included in the grid are held at
their C<base_params> values.

This is a brute-force method best suited for:

=over 4

=item * B<1-D scans> — e.g., sweeping thickness to find the correct
interference order before LM refinement.

=item * B<2-D maps> — e.g., scanning thickness + refractive index to
visualise the cost landscape.

=back

For three or more parameters the number of evaluations grows
exponentially and DE is usually a better choice.

B<Arguments:>

=over 4

=item C<objective> (required)

Code reference.  Receives a PDL piddle of parameters and returns a
scalar cost value.

=item C<base_params> (required)

PDL piddle of default parameter values.  Grid dimensions override
their respective elements; all others stay fixed.

=item C<grid> (required)

Arrayref of grid axis specifications, each a hashref:

    { index => $param_index,      # 0-based position in params PDL
      min   => $lower_value,
      max   => $upper_value,
      steps => $number_of_points }

=item C<verbose>

Print the best cost at the end.  Default: 0.

=back

B<Returns:> C<($best_pdl, $best_cost)>.

B<Example — 1-D thickness scan:>

    my ($best, $cost) = grid_search(
        objective   => $objective,
        base_params => pdl([100.0, 2.1, 0.01]),
        grid        => [
            { index => 0, min => 10, max => 500, steps => 100 },
        ],
        verbose => 1,
    );
    printf "Best thickness = %.1f nm  (cost = %.4f)\n",
           $best->at(0), $cost;

B<Example — 2-D thickness × refractive index map:>

    my ($best, $cost) = grid_search(
        objective   => $objective,
        base_params => pdl([100.0, 2.1, 0.01]),
        grid        => [
            { index => 0, min => 10,  max => 500, steps => 50 },
            { index => 1, min => 1.3, max => 3.0, steps => 50 },
        ],
        verbose => 1,
    );
    printf "Best: d=%.1f nm, n=%.3f  (cost=%.4f)\n",
           $best->at(0), $best->at(1), $cost;

=head1 CHOOSING A STRATEGY

=over 4

=item B<Few parameters (1–2), known ranges> → L</grid_search>

Fast, deterministic, easy to visualise.

=item B<Many parameters (3+), or unknown ranges> → L</differential_evolution>

Handles high dimensions, robust against local minima, stochastic.

=item B<Hybrid approach> (recommended)

Use grid search or DE to find the basin of attraction, then pass the
result to L<Physics::Ellipsometry::VASE/fit> for LM refinement:

    my ($coarse, $_) = differential_evolution(...);
    my $precise = $vase->fit($coarse);

=back

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE>,
L<Physics::Ellipsometry::VASE::Parameter>

R. Storn and K. Price, "Differential Evolution — A Simple and Efficient
Heuristic for Global Optimization over Continuous Spaces",
I<J. Global Optim.> B<11>, 341 (1997).

=cut

# Differential Evolution (DE/rand/1/bin)
# $objective->($params_pdl) returns scalar cost (e.g., chi²)
# $bounds: arrayref of [min, max] pairs for each parameter
# Returns: best parameter PDL
sub differential_evolution {
    my (%args) = @_;
    die "Need objective function" unless defined $args{objective};
    die "Need parameter bounds"   unless defined $args{bounds};
    my $objective = $args{objective};
    my $bounds    = $args{bounds};
    my $np        = $args{pop_size}  // 30;
    my $F         = $args{F}         // 0.7;
    my $CR        = $args{CR}        // 0.9;
    my $maxiter   = $args{maxiter}   // 200;
    my $tol       = $args{tol}       // 1e-6;
    my $seed      = $args{seed};
    my $verbose   = $args{verbose}   // 0;

    srand($seed) if defined $seed;

    my $ndim = scalar @$bounds;
    $np = $ndim * 10 if $np < $ndim * 5;  # ensure adequate population

    # Initialize population randomly within bounds
    my @population;
    my @costs;
    for my $i (0 .. $np - 1) {
        my @individual;
        for my $d (0 .. $ndim - 1) {
            my ($lo, $hi) = @{$bounds->[$d]};
            push @individual, $lo + rand() * ($hi - $lo);
        }
        my $ind_pdl = pdl(\@individual);
        push @population, $ind_pdl;
        push @costs, $objective->($ind_pdl);
    }

    # Find initial best
    my $best_idx = 0;
    for my $i (1 .. $#costs) {
        $best_idx = $i if $costs[$i] < $costs[$best_idx];
    }
    my $best_cost = $costs[$best_idx];
    my $best = $population[$best_idx]->copy;

    printf "  DE: initial best cost = %.4f\n", $best_cost if $verbose;

    # Evolution loop
    for my $gen (1 .. $maxiter) {
        my $improved = 0;

        for my $i (0 .. $np - 1) {
            # Select 3 distinct random indices ≠ i
            my @r;
            while (@r < 3) {
                my $idx = int(rand($np));
                next if $idx == $i || grep { $_ == $idx } @r;
                push @r, $idx;
            }

            # Mutation: v = x_r0 + F*(x_r1 - x_r2)
            my $v = $population[$r[0]] + $F * ($population[$r[1]] - $population[$r[2]]);

            # Clip to bounds
            for my $d (0 .. $ndim - 1) {
                my ($lo, $hi) = @{$bounds->[$d]};
                my $val = $v->at($d);
                $val = $lo if $val < $lo;
                $val = $hi if $val > $hi;
                $v->set($d, $val);
            }

            # Crossover: binomial
            my $trial = $population[$i]->copy;
            my $j_rand = int(rand($ndim));
            for my $d (0 .. $ndim - 1) {
                if (rand() < $CR || $d == $j_rand) {
                    $trial->set($d, $v->at($d));
                }
            }

            # Selection
            my $trial_cost = $objective->($trial);
            if ($trial_cost < $costs[$i]) {
                $population[$i] = $trial;
                $costs[$i] = $trial_cost;
                $improved++;

                if ($trial_cost < $best_cost) {
                    $best_cost = $trial_cost;
                    $best = $trial->copy;
                }
            }
        }

        if ($verbose && $gen % 20 == 0) {
            printf "  DE gen %d: best=%.4f, improved=%d/%d\n",
                   $gen, $best_cost, $improved, $np;
        }

        # Convergence check: population diversity
        if ($gen > 10) {
            my $spread = 0;
            for my $d (0 .. $ndim - 1) {
                my @vals = map { $_->at($d) } @population;
                my $min_v = (sort { $a <=> $b } @vals)[0];
                my $max_v = (sort { $b <=> $a } @vals)[0];
                my ($lo, $hi) = @{$bounds->[$d]};
                $spread += ($max_v - $min_v) / (($hi - $lo) || 1);
            }
            $spread /= $ndim;
            last if $spread < $tol;
        }
    }

    printf "  DE: final best cost = %.4f\n", $best_cost if $verbose;
    return ($best, $best_cost);
}

# Grid search over specified parameter dimensions
# $objective->($params_pdl) returns scalar cost
# $base_params: PDL with default parameter values
# $grid_spec: arrayref of {index => param_idx, min => val, max => val, steps => N}
sub grid_search {
    my (%args) = @_;
    die "Need objective function" unless defined $args{objective};
    die "Need base_params PDL"   unless defined $args{base_params};
    die "Need grid specification" unless defined $args{grid};
    my $objective   = $args{objective};
    my $base_params = $args{base_params};
    my $grid_spec   = $args{grid};
    my $verbose     = $args{verbose} // 0;

    my $best_cost   = 1e30;
    my $best_params = $base_params->copy;

    # For 1D or 2D grid search
    my @axes;
    for my $spec (@$grid_spec) {
        my $step = ($spec->{max} - $spec->{min}) / ($spec->{steps} - 1);
        my @values;
        for my $i (0 .. $spec->{steps} - 1) {
            push @values, $spec->{min} + $i * $step;
        }
        push @axes, { index => $spec->{index}, values => \@values };
    }

    # Recursive grid evaluation
    _grid_recurse(\@axes, 0, $base_params->copy, $objective,
                  \$best_cost, \$best_params);

    printf "  Grid: best cost = %.4f\n", $best_cost if $verbose;
    return ($best_params, $best_cost);
}

sub _grid_recurse {
    my ($axes, $depth, $params, $objective, $best_cost_ref, $best_params_ref) = @_;

    if ($depth >= scalar @$axes) {
        my $cost = $objective->($params);
        if ($cost < $$best_cost_ref) {
            $$best_cost_ref = $cost;
            $$best_params_ref = $params->copy;
        }
        return;
    }

    my $axis = $axes->[$depth];
    for my $val (@{$axis->{values}}) {
        my $p = $params->copy;
        $p->set($axis->{index}, $val);
        _grid_recurse($axes, $depth + 1, $p, $objective, $best_cost_ref, $best_params_ref);
    }
}

1;
