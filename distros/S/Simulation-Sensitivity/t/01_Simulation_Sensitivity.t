use strict;
use warnings;

# Simulation::Sensitivity

use Test::More tests => 10;

require_ok('Simulation::Sensitivity');

#--------------------------------------------------------------------------#
# define a test calculation -- simple addition
#--------------------------------------------------------------------------#

my $test_calc = sub {
    my $p = shift;
    return $p->{alpha} + $p->{beta};
};

#--------------------------------------------------------------------------#
# results array sorting function
#--------------------------------------------------------------------------#

#sub sort_results { return [ sort { @$a[1] <=> @$b[1] } @{$_[0]} ] }

#--------------------------------------------------------------------------#
# Tests
#--------------------------------------------------------------------------#

eval { Simulation::Sensitivity->new() };
ok( defined $@, 'new() dies without valid parameters' );

ok(
    my $obj = Simulation::Sensitivity->new(
        calculation => $test_calc,
        parameters  => {
            alpha => 1,
            beta  => 4
        },
        delta => .25
    ),
    'creating a Simulation::Sensitivity object'
);

isa_ok( $obj, 'Simulation::Sensitivity' );

is( $obj->base(), 5, 'comparing base case to expected' );

ok( my $results = $obj->run(), 'running sensitivity analysis' );

my $expected = {
    alpha => {
        "+25%" => 5.25,
        "-25%" => 4.75
    },
    beta => {
        "+25%" => 6,
        "-25%" => 4
    }
};

is_deeply( $results, $expected, 'comparing expected results' );

#--------------------------------------------------------------------------#
# Test reporting
#--------------------------------------------------------------------------#

my $report = <<TXT;
   Parameter      +25%      -25%
------------------------------------
       alpha     +5.00%     -5.00%
        beta    +20.00%    -20.00%
TXT

is( $obj->text_report($results), $report, 'comparing expected text report' );

my $bad_base_obj = Simulation::Sensitivity->new(
    calculation => $test_calc,
    parameters  => {
        alpha => 0,
        beta  => 0
    },
    delta => .25
);

is( $bad_base_obj->base, 0, 'setting up a simulation with base case of 0' );
eval { $bad_base_obj->text_report };
ok( defined $@, 'text_report dies with base case of 0' );

