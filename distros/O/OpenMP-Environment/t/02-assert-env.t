use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use Test::More;
use Test::Exception;

use_ok('OpenMP::Environment');

my $env = OpenMP::Environment->new;
isa_ok( $env, 'OpenMP::Environment' );

# Set up environment as if done externally
local %ENV = %ENV;

# the following are technically valid, but not guarenteed to be self-consistent;
# they are, however, validated
sub set_valid {
    $ENV{OMP_CANCELLATION}      = q{TRUE};
    $ENV{OMP_DISPLAY_ENV}       = q{TRUE};
    $ENV{OMP_TARGET_OFFLOAD}    = q{MANDATORY};
    $ENV{OMP_DYNAMIC}           = q{TRUE};
    $ENV{OMP_DEFAULT_DEVICE}    = 0;
    $ENV{OMP_MAX_ACTIVE_LEVELS} = 1;
    $ENV{OMP_MAX_TASK_PRIORITY} = 0;
    $ENV{OMP_NESTED}            = q{TRUE};
    $ENV{OMP_NUM_THREADS}       = 16;
    $ENV{OMP_THREAD_LIMIT}      = 1;
    $ENV{OMP_WAIT_POLICY}       = q{PASSIVE};
    $ENV{GOMP_DEBUG}            = 0;
}

ok $env->assert_omp_environment, q{External OpenMP is not set, deemed validated as expected};

set_valid();

note $env->_omp_summary;

ok $env->assert_omp_environment, q{External OpenMP validated as expected};

note qq{Setting up non-validated variables via %ENV ...\n\n};

# the following are technically valid, but not guarenteed to be self-consistent;
# nor are these validated directly
$ENV{OMP_PROC_BIND}           = q{MASTER,CLOSE,SPREAD};
$ENV{OMP_PLACES}              = q/{0,1,2}, {3,4,6}, {7,8,9}, {10,11,12}/;
$ENV{OMP_STACKSIZE}           = 1024;
$ENV{GOMP_STACKSIZE}          = q{1024G};
$ENV{OMP_SCHEDULE}            = q{dynamic,16};
$ENV{GOMP_CPU_AFFINITY}       = q{0 3 1-2 4-15:2};
$ENV{GOMP_SPINCOUNT}          = q{INFINITY};
$ENV{GOMP_RTEMS_THREAD_POOLS} = q{1@WRK0:3$4@WRK1};

note $env->_omp_summary;
note q{};
note q{Now testing assert_omp_environment for each validated variable};

$ENV{OMP_CANCELLATION} = q{xxx};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_CANCELLATION is invalid} );

set_valid();
$ENV{OMP_DISPLAY_ENV} = q{yyy};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_DISPLAY_ENV is invalid} );

set_valid();

$ENV{OMP_TARGET_OFFLOAD} = q{xxx};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_TARGET_OFFLOAD is invalid} );

set_valid();

$ENV{OMP_DYNAMIC} = q{xxx};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_DYNAMIC is invalid} );

set_valid();

$ENV{OMP_DEFAULT_DEVICE} = -1;
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_DEFAULT_DEVICE is invalid} );

set_valid();

$ENV{OMP_MAX_ACTIVE_LEVELS} = -1;
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_MAX_ACTIVE_LEVELS is invalid} );

set_valid();

$ENV{OMP_MAX_TASK_PRIORITY} = -1;
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_MAX_TASK_PRIORITY is invalid} );

set_valid();

$ENV{OMP_NESTED} = q{yyy};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_NESTED is invalid} );

set_valid();

$ENV{OMP_NUM_THREADS} = q{figgy};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_NUM_THREADS is invalid} );

set_valid();

$ENV{OMP_THREAD_LIMIT} = q{aaa};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_THREAD_LIMIT is invalid} );

set_valid();

$ENV{OMP_WAIT_POLICY} = q{PASSIVE-AGGRESSIVE};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when OMP_WAIT_POLICY is invalid} );

set_valid();

$ENV{GOMP_DEBUG} = q{bbb};
dies_ok( sub { $env->assert_omp_environment }, q{Fails as expectedly when GOMP_DEBUG is invalid} );

done_testing;

exit;
__END__
