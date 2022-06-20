# NAME

PDL::Opt::Simplex::Simple - A simplex optimizer for the rest of us
(who may not know PDL).

# SYNOPSIS

        use PDL::Opt::Simplex::Simple;

        # Simple single-variable invocation

        $simpl = PDL::Opt::Simplex::Simple->new(
                vars => {
                        # initial guess for x
                        x => 1 
                },
                f => sub { 
                                # Parabola with minima at x = -3
                                return (($_->{x}+3)**2 - 5) 
                        }
        );

        $simpl->optimize();
        $result_vars = $simpl->get_result_simple();

        print "x=" . $result_vars->{x} . "\n";  # x=-3


        # Multi-vector Optimization and other settings:

        $simpl = PDL::Opt::Simplex::Simple->new(
                vars => {
                        # initial guess for arbitrarily-named vectors:
                        vec1 => { values => [ 1, 2, 3 ], enabled => [1, 1, 0] }
                        vec2 => { values => [ 4, 5 ],    enabled => [0, 1] }
                },
                f => sub { 
                                my ($vec1, $vec2) = ($_->{vec1}, $_->{vec2});
                                
                                # do something with $vec1 and $vec2
                                # and return() the result to be minimized by simplex.
                        },
                log => sub { }, # log callback
                ssize => 0.1,   # initial simplex size, smaller means less perturbation
                max_iter => 100 # max iterations
        );


        $result_vars = $simpl->optimize();

        use Data::Dumper;

        print Dumper($result_vars);

# DESCRIPTION

This class uses [PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex) to find the values for `vars`
that cause the `f` coderef to return the minimum value.  The difference
between [PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex) and [PDL::Opt::Simplex::Simple](https://metacpan.org/pod/PDL::Opt::Simplex::Simple) is that
[PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex) expects all data to be in PDL format and it is
more complicated to manage, whereas, [PDL::Opt::Simplex:Simple](https://metacpan.org/pod/PDL::Opt::Simplex:Simple) uses
all scalar Perl values. (PDL values are supported, too, see the PDL use case
note below.)

With the original [PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex) module, a single vector array
had to be sliced into the different variables represented by the array.
This was non-intuitive and error-prone.  This class attempts to improve
on that by defining data structure of variables, values, and whether or
not a value is enabled for optimization.

This means you can selectively disable a particular value and it will be
excluded from optimization but still included when passed to the user's
callback function `f`.  Internal functions in this class compile the state
of this variable structure into the vector array needed by simplex,
and then extract values into a usable format to be passed to the user's
callback function.

# FUNCTIONS

- $self->new(%args) - Instantiate class
- $self->optimize() - Run the optimization
- $self->get\_vars\_expanded() - Returns the original `vars` in a fully expanded format
- $self->get\_vars\_simple() - Returns `vars` in the simplified format

    This format is suitable for passing into your `f` callback.

- $self->get\_vars\_orig() - Returns `vars` in originally passed format
- $self->get\_result\_expanded() - Returns the optimization result in expanded format.
- $self->get\_result\_simple() - Returns the optimization result in the simplified format

    This format is suitable for passing into your `f` callback.

- $self->set\_vars(\\%vars) - Set `vars` as if passed to the constructor.

    This can be used to feed a result from $self->get\_result\_expanded() into
    a new refined simplex iteration.

- $self->set\_ssize($ssize) - Set `ssize` as if passed to the constructor.

    Useful for calling simplex again with refined values

- $self->scale\_ssize($scale) - Multiply the current `ssize` by `$scale`

# ARGUMENTS

## \* `vars` - Hash of variables to optimize: the answer to your question.

### - Simple `vars` Format

Thes are the variables being optimized to find a minimized result.
The simplex() function returns minimized set of `vars`. In its Simple
Format, the `vars` setting can assign values for vars directly as in the
synopsis above:

        vars => {
                # initial guesses:
                x => 1,
                y => 2, ...
        }

or as vectors of (possibly) different lengths:

        vars => {
                # initial guess for x
                u => [ 4, 5, 6 ],
                v => [ 7, 8 ], ...
        }

### - Expanded `vars` Format

You may find during optimization that it would
be convenient to disable certain elements of the vector being optimized
if, for example, you know that one value is already optimal but that it
needs to be available to the f() callback.  The expanded format shows
that the 4th element is excluded from optimization by setting enabled=0
for that index.

Expanded format:  

        vars => {
                varname => {
                        "values"         =>  [...],
                        "minmax"         =>  [ [min=>max],  ...
                        "perturb_scale"  =>  [...],
                        "enabled"        =>  [...],
                },  ...
        }

- `varname`: the name of the variable being used.
- `values`:  an arrayref of values to be optimized
- `minmax`:  a double-array of min-max pairs (per index for vectors)

    Min-max pairs are clamped before being evaluated by simplex.

- `round_result`:  Round the value to the nearest increment of this value upon completion

    You may need to round the final output values to a real-world limit after optimization
    is complete.  Setting round\_result will round after optimization finishes, but leave 
    full precision while iterating.  See also: `round_each`.

    This function uses [Math::Round](https://metacpan.org/pod/Math::Round)'s `nearest` function:

            nearest(10, 44)    yields  40
            nearest(10, 46)            50
            nearest(10, 45)            50
            nearest(25, 328)          325
            nearest(.1, 4.567)          4.6
            nearest(10, -45)          -50

- `round_each`:  Round the value to the nearest increment of this value on each iteration.

    It is probably best to round at the end (`round_result`) to keep precision
    during each iteration, but the option is available in case you wish to
    use it.

- `perturb_scale`:  Scale parameter before being evaluated by simplex (per index for vectors)

    This is useful because Simplex's `ssize` parameter is the same for all
    values and you may find that some values need to be perturbed more or
    less than others while simulating.  User interaction with `f` and the
    result of `optimize` will use the normally scaled values supplied by
    the user, this is just an internal scale for simplex.

    - Bigger value:  perturb more
    - Smaller value:  perturb less

    Internal details: The value passed to simplex is divided by perturb\_scale
    parameter before being passed and multiplied by perturb\_scale when
    returned.  Thus, perturb\_scale=0.1 would make simplex see the value as
    being 10x larger effectively perturbing it less, whereas, perturb\_scale=10
    would make it 10x smaller and perturb it more.

- `enabled`: 1 or 0: enabled a specific index to be optimized (per index for vectors)
    - If 'enabled' is undefined then all values are enabled.
    - If 'enabled' is not an array, it can be a scalar 0 or 1 to
    indicate that all values are enabled/disabled.  In this case your original
    structure will be replaced with an arrayref of all 0/1 values.
    - Enabling or disabling a variable may be useful in testing
    certain geometry charactaristics during optimization.

        Internally, all values are vectors, even if the vectors are of length 1,
        but you can pass them as singletons like `spaces` as shorthand shown below instead
        of writing "spaces => \[5\]".  In that example you can see that `spaces` is disabled
        as well, so simplex will not optimize that value.  

            spaces => [ 5 ]

            # Element lengths                                                
            vars => {
                lengths => {                                                     
                    values         =>  [  1.038,       0.955,        0.959 ],
                    minmax         =>  [  [0.5=>1.5],  [0.3=>1.2],  [0.2=>1.1] ],
                    perturb_scale  =>  [  10,          100,          1 ],
                    enabled        =>  [  1,           1,            1 ],
                },                                                       
                spaces => {
                    values => 5, 
                    enabled => 0
                },
                ...
            }

## \* `f` - Callback function to operate upon `vars`

The `f` argument is a coderef that is called by the optimizer.  It is passed a hashref of `vars` in 
the Simple Format and must return a scalar result:

        f->({ lengths => [ 1.038, 0.955, 0.959, 0.949, 0.935 ], spaces => 5 });

Note that a single-length vector will always be passed as a scalar to `f`:

        vars => { x => [5] } will be passed as f->({ x => 5 })

The Simplex algorithm will work to minimize the return value of your `f` coderef, so return 
smaller values as your variables change to produce a (more) desired outcome.

## \* `log` - Callback function log status for each iteration.

        log => sub { 
                        my ($vars, $state) = @_;
                
                        print "LOG: " . Dumper($vars, $state);
                }

The log() function is passed the current state of `vars` in the
same format as the `f` callback.  A second `$state` argument is passed
with information about the The return value is ignored.  The following 
values are available in the `$state` hashref:

    {
        'ssize' => '704.187123721893',  # current ssize during iteration
        'minima' => '53.2690700664067', # current minima returned by f()
        'elapsed' => '3.12',            # elapsed time in seconds since last log() call.
        'srand' => 55294712,            # the random seed for this run
        'log_count' => 5,               # how many times _log has been called
        'optimization_pass' => 3,       # pass# if multiple ssizes are used
        'num_passes' => 6,              # total number of passes
        'best_pass' =>  3,              # the pass# that had the best goal result
        'log_count' => 22,              # number of times log has been called
        'prev_minima_count' => 10,      # number of same minima's in a row
        'cancel' =>     0,              # true if the simplex iteration is being cancelled
        'all_vars' => [{x=>1},...],     # multiple var options from simplex are logged here
        'cache_hits' => 100,            # Number of times simplex asked to try the same vars
        'cache_misses' => 1000,         # Number of times simplex asked to try unique vars
    }

## \* `ssize` - Initial simplex size, see [PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex)

Think of this as "step size" but not really, a bigger value makes larger
jumps but the value doesn't translate to a unit.  (It actually stands
for simplex size, and it initializes the size of the simplex tetrahedron.)

You will need to scale the `ssize` argument depending on your search
space.  Smaller `ssize` values will search a smaller space of possible
values provided in `vars`.  This is problem-space dependent and may
require some trial and error to tune it where you need it to be.

Example for optimizing geometry in an EM simulation: Because it is
proportional to wavelength, lower frequencies need a larger value and
higher frequencies need a lower value.

The `ssize` parameter may be an arrayref:  If an arrayref is specified
then it will run simplex to completion using the first ssize and then
restart with the next `ssize` value in the array.  Each iteration uses
the best result as the input to the next simplex iteration in an attempt
to find increasingly better results.  For example, 4 iterations with each
`ssize` one-half of the previous:

        ssize => [ 4, 2, 1, 0.5 ]

Default: 1

## \* `nocache` - Disable result caching

By default we try not to re-calculate the same values.  This is particularly
useful when `round_each` is used because it will round values from before
passing them to `f`, which increases the chance of a cache hit.

If you wish to disable caching then set "nocache => 1"

Default: undef (cache enabled)

## \* `max_iter` - Maximim number of Simplex iterations

Note that one Simplex iteration may call `f` multiple times.

Default: 1000

## \* `tolerance` - Conversion tolerance for Simplex

The default is 1e-6.  It tells Simplex to stop before `max_iter` if 
very little change is being made between iterations.

Default: 1e-6

## \* `srand` - Value to seed srand

Simplex makes use of random perturbation, so setting this value will make
the simulation deterministic from run to run.

The default when not defined is to call srand() without arguments and use
a randomly generated seed.  If set, it will call srand($self->{srand})
to initialize the initial seed.  The result of this seed (whether passed
or generated) is available in the status structure defined above.

Default: system generated.

## \* `stagnant_minima_count` - Abort the simplex iteration if the minima is not changing

This is the maximum number of iterations that can return a worse minima
than the previous minima. Once reaching this limit the current iteration
is cancelled due to stagnation. Setting this too low will provide poor
results, setting it too high will just take longer to iterate when it
gets stuck.

Note: This value may be somewhat dependent on the number of variables
you are optimizing.  The more variables, the bigger the value.  A value
of 30 seems to work well for 10 variables, so adjust if necessary.

Simplex will not cancel due to stagnation when `stagnant_minima_count` is
undefined.

Default: undef

## \* `stagnant_minima_tolerance` - threshold to count toward `stagnant_minima_count`

When `abs($prev_minima - $cur_minima) < $stagnant_minima_count` then the
iteration will be counted toward stagnation when `stagnant_minima_count` is
defined (see above).  Otherwise, we assume progress is being made and the
stagnation count is reset.

Default: same as `tolerance` (see above)

# BEST PRACTICES AND USE CASES

## Antenna Geometry: Use an array for the `ssize` parameter from coarse to fine perturbation.

This `PDL::Opt::Simplex::Simple` module was originally written to optimize
antenna geometries in conjunction with the "Optimizer Output" feature of the
xnec2c ([https://www.xnec2c.org](https://www.xnec2c.org)) antenna simulator. The behavior is best
described by Neoklis Kyriazis, 5B4AZ who originally wrote xnec2c:
[http://www.5b4az.org/pages/antenna\_designs.html](http://www.5b4az.org/pages/antenna_designs.html)

        "Xnec2c monitors its .nec input file for changes and re-runs the
        frequency stepping loop which recalculates new data and prints to the
        .csv file. It is therefore possible to arrange the optimizer program to
        read the .csv data file, recalculate antenna parameters and save them
        to the .nec input file.

        Xnec2c will then recalculate and save new frequency-dependent data to
        the .csv file.  If the optimizer program is arranged to monitor changes
        to the .csv file, then a continuous loop can be created in which new
        antenna parameters are calculated and saved to the .nec file, new
        frequency dependent data are calculated and saved to the .csv file and
        the loop repeated until the desired results (optimization) are
        obtained."

We find that a coarse "first pass" value for `ssize` may not produce optimal
results, so `PDL::Opt::Simplex::Simple` will perform additional simplex
iterations if you specify `ssize` with multiple values to retry once a
previous iteration finds a "good" (but not "great") result; the best minima
from across all simplex passes is kept as the final result in case latter passes
do not perform as well:

        ssize => [ 0.090, 0.075, 0.050, 0.025, 0.012 ]

This allows us to optimize antenna gain from 10.2 dBi with a single pass to
11.3 dBi after 5 passes, in addition to a much improved VSWR value.

See [https://github.com/KJ7LNW/xnec2c-optimize](https://github.com/KJ7LNW/xnec2c-optimize) for sample graphs and more
information, including documentation to setup the demo so you can see
`PDL::Opt::Simplex::Simple` in action as the graphs update in real-time during
the optimization process.

## PID Controller: Set ssize to 1 and scale perturb\_scale for each variable.

We were using a proportional-integral-derivative ("PID") controller to
optimize antenna motion for tracking orbiting satellites like the International
Space Station.  The goal is to minimize rotor overshoot and increase accuracy
for the azimuth and elevation axis.  Without getting into the PID controller
implementation, just know that there are 3 primary terms in a PID controller
that define its behavior (Kp, Ki, and Kd),  and the satellite tracking is
"good" if the overshoot is minimal.  Here is a trivial implementation:

        $simpl = PDL::Opt::Simplex::Simple->new(
                vars => {
                        # initial guess for kp, ki, kd:
                        kp => 150,
                        ki => 120,
                        kd => 5
                },
                ssize => 1,
                f => sub { 
                                my $vars = shift;
                                
                                return track_satellite_get_overshoot(
                                        kp => $vars->{kp},
                                        ki => $vars->{ki},
                                        kd => $vars->{kd});
                        }
        );

        print Dumper $simpl->optimize();

Note that `ssize=1` so simplex will purturb the kp/ki/kd values in the range of about 1.  This 
is great if you are already close to a solution, but in our case kp, ki, and kd need perturbed 
different amounts.  It turns out that kd is quite small, while the optimal kp and ki values
need a larger search space.

You might consider increasing `ssize`, to `ssize=20` but then kd will scale too quickly.  To achieve
this we used the extended variable format as follows:

        $simpl = PDL::Opt::Simplex::Simple->new(
                vars => {
                        # initial guess for kp, ki, kd:
                        kp => {
                                values => 150,
                                perturb_scale => 20,
                        },

                        ki => {
                                values => 120,
                                perturb_scale => 15,
                        },

                        kd => {
                                values => 5,
                                perturb_scale => 1,
                        },
                },
                ssize => 1, # <- ssize is still set to 1 !
                f => sub { 
                                my $vars = shift;
                                
                                return track_satellite_get_overshoot(
                                        kp => $vars->{kp},
                                        ki => $vars->{ki},
                                        kd => $vars->{kd});
                        }
        );

        print Dumper $simpl->optimize();

As you can see above, the `perturb_scale` value is different for each value;
you could think of `perturb_scale` as a "local ssize".  Note that `ssize`
will still scale everything so if you wish to leave the relative scales defiend
by `perturb_scale` but double the search space, then set `ssize=2`.  

Ultimately simplex found the values to work best around Kp=190.90, Ki=166.33,
and Kd=1.02.  These values are specific to our hardware implementation
(rotational mass, motor speed, etc) so the procedure is what is important here,
not the values.  Typically simplex is used against mathematical models, and it
was interesting to run simplex against a real physical machine to calculate
ideal values for its control.  

If you are interested, here is a video about the antenna construction: 
[https://youtu.be/Ab\_oJHlENwo](https://youtu.be/Ab_oJHlENwo)

## PDL variable considerations

You can use pdl's as vars in your code, but at the moment those pdl's must be singletons.

This will work:

        ->new({
                vars => { x => pdl(5) }
        }, ...)

but this will not:

        ->new({
                vars => { x => pdl([1,2,3]) }
        }, ...)

If you need PDL vectors in your `f()` call then this could work because
[PDL::Opt::Simplex::Simple](https://metacpan.org/pod/PDL::Opt::Simplex::Simple) can optimize perl ARRAY ref's:

        ->new({
                vars => { x => [1,2,3] }
        }, 
        f => sub {
                my $vars = shift;
                my $x = pdl $vars->{x};

                # do stuff here, maybe return the sum:

                return unpdl(sum $x);
        },
        ...)

Future support for this is possible, but there is one major consideration: PDLs
need to be generically decomposed into a 1-dimensionaly PDL before passing it
to simplex() and then convert it back to the original N-dimensional form before
passing it to the user's `f()` call.  This would then enable hash-named
N-dimensional pdl optimization.

Patches welcome ;)

# SEE ALSO

## Upstream modules:

- Video about how optimization algorithms like Simplex work, visually: [https://youtu.be/NI3WllrvWoc](https://youtu.be/NI3WllrvWoc)
- Wikipedia Article: [https://en.wikipedia.org/wiki/Simplex\_algorithm](https://en.wikipedia.org/wiki/Simplex_algorithm),
- PDL Implementation of Simplex: [PDL::Opt::Simplex](https://metacpan.org/pod/PDL::Opt::Simplex), [http://pdl.perl.org/](http://pdl.perl.org/)
- This modules github repository: [https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple](https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple)

## Example links:

- Antenna Geometry Optimization: [https://github.com/KJ7LNW/xnec2c-optimize](https://github.com/KJ7LNW/xnec2c-optimize)

# AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
optimize antenna geometry for the [https://www.xnec2c.org](https://www.xnec2c.org) project.

# COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. [https://www.linuxglobal.com/](https://www.linuxglobal.com/)

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see &lt;http://www.gnu.org/licenses/>.
