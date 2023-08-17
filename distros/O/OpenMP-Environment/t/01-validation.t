use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use Test::More;
use Test::Exception;

use_ok('OpenMP::Environment');

my $env = OpenMP::Environment->new;
isa_ok( $env, 'OpenMP::Environment' );

note q{Testing validation for all OpenMP Environmental Variables that have checks implemented};

# OMP_CANCELLATION
note q{## OMP_CANCELLATION's valid values are: 'TRUE', 'FALSE', and may be unset};
is $env->omp_cancellation(q{TRUE}),  q{TRUE},  q{OMP_CANCELLATION can be set to 'TRUE' };
is $env->omp_cancellation(q{true}),  q{TRUE},  q{OMP_CANCELLATION can be set to 'TRUE' via 'true' };
is $env->unset_omp_cancellation(),   q{TRUE},  q{unset_omp_cancellation returns last known value if OMP_CANCELLATION is set};
is $env->omp_cancellation(q{FALSE}), q{FALSE}, q{OMP_CANCELLATION can be set to 'FALSE' };
is $env->omp_cancellation(q{false}), q{FALSE}, q{OMP_CANCELLATION can be set to 'FALSE' via 'false' };
is $env->unset_omp_cancellation(),   q{FALSE}, q{unset_omp_cancellation returns last known value if OMP_CANCELLATION is set};
is $env->omp_cancellation,           undef,    q{OMP_CANCELLATION has indeed been unset};
ok !exists( $ENV{OMP_CANCELLATION} ), q/$ENV{OMP_CANCELLATION} doesn't exist, as expected/;
dies_ok( sub { $env->omp_cancellation(q{Invalid value xxx}) }, q{omp_cancellation dies on invalid input} );

# OMP_DYNAMIC
note q{## OMP_DYNAMIC's valid values are: 'true', 1, 'false', 0, and may be unset};
is $env->omp_dynamic(q{true}),  q{true}, q{OMP_DYNAMIC can be set to 'true' via 'true' };
is $env->unset_omp_dynamic(),   q{true}, q{unset_omp_dynamic returns last known value if OMP_DYNAMIC is set};
is $env->omp_dynamic(q{1}),     q{1},    q{OMP_DYNAMIC can be set to '1' via '1' };
is $env->unset_omp_dynamic(),   q{1},    q{unset_omp_dynamic returns last known value if OMP_DYNAMIC is set};
is $env->omp_dynamic(q{false}), undef,   q{OMP_DYNAMIC can be set to 'false' via 'false' };
is $env->unset_omp_dynamic(),   undef,   q{unset_omp_dynamic returns undef when OMP_DYNAMIC already doesn't exist};
is $env->omp_dynamic(q{1}),     q{1},    q{OMP_DYNAMIC can be set to '1' via '1' };
is $env->omp_dynamic(q{0}),     1,       q{OMP_DYNAMIC can be unset via '0', if set returns 1};
is $env->unset_omp_dynamic(),   undef,   q{unset_omp_dynamic returns last known value if OMP_DYNAMIC is set, including undef if unset};
is $env->omp_dynamic,           undef,   q{OMP_DYNAMIC has indeed been unset};
ok !exists( $ENV{OMP_DYNAMIC} ), q/$ENV{OMP_DYNAMIC} doesn't exist, as expected/;
dies_ok( sub { $env->omp_dynamic(q{Invalid value xxx}) }, q{omp_dynamic dies on invalid input} );

# OMP_NESTED
note q{## OMP_NESTED's valid values are: 'TRUE', 'FALSE', and may be unset};
is $env->omp_nested(q{TRUE}),  q{TRUE}, q{OMP_NESTED can be set to 'TRUE' };
is $env->omp_nested(q{true}),  q{TRUE}, q{OMP_NESTED can be set to 'TRUE' via 'true' };
is $env->unset_omp_nested(),   q{TRUE}, q{unset_omp_nested returns last known value if OMP_NESTED is set};
is $env->omp_nested(q{TRUE}),  q{TRUE}, q{OMP_NESTED can be set to 'TRUE' };
is $env->omp_nested(q{FALSE}), q{TRUE}, q{OMP_NESTED is deleted from %ENV when set to 'FALSE' };
is $env->omp_nested(q{false}), undef,   q{OMP_NESTED is deleted from %ENV when set to 'false' };
is $env->unset_omp_nested(),   undef,   q{unset_omp_nested returns last known value if OMP_NESTED is set};
is $env->omp_nested,           undef,   q{OMP_NESTED has indeed been unset};
ok !exists( $ENV{OMP_NESTED} ), q/$ENV{OMP_NESTED} doesn't exist, as expected/;
dies_ok( sub { $env->omp_nested(q{Invalid value xxx}) }, q{omp_nested dies on invalid input} );

# OMP_WAIT_POLICY
note q{## OMP_WAIT_POLICY's valid values are: 'ACTIVE', 'PASSIVE', and may be unset};
is $env->omp_wait_policy(q{ACTIVE}),  q{ACTIVE},  q{OMP_WAIT_POLICY can be set to 'ACTIVE' };
is $env->omp_wait_policy(q{active}),  q{ACTIVE},  q{OMP_WAIT_POLICY can be set to 'ACTIVE' via 'active' };
is $env->unset_omp_wait_policy(),     q{ACTIVE},  q{unset_omp_wait_policy returns last known value if OMP_WAIT_POLICY is set};
is $env->omp_wait_policy(q{PASSIVE}), q{PASSIVE}, q{OMP_WAIT_POLICY can be set to 'PASSIVE' };
is $env->omp_wait_policy(q{passive}), q{PASSIVE}, q{OMP_WAIT_POLICY can be set to 'PASSIVE' via 'passive' };
is $env->unset_omp_wait_policy(),     q{PASSIVE}, q{unset_omp_wait_policy returns last known value if OMP_WAIT_POLICY is set};
is $env->omp_wait_policy,             undef,      q{OMP_WAIT_POLICY has indeed been unset};
ok !exists( $ENV{OMP_WAIT_POLICY} ), q/$ENV{OMP_WAIT_POLICY} doesn't exist, as expected/;
dies_ok( sub { $env->omp_wait_policy(q{Invalid value xxx}) }, q{omp_wait_policy dies on invalid input} );

# GOMP_DEBUG
note q{## GOMP_DEBUG's valid values are: '1', '0', and may be unset};
is $env->gomp_debug(q{1}),   q{1},  q{GOMP_DEBUG can be set to '1' };
is $env->unset_gomp_debug(), q{1},  q{unset_gomp_debug returns last known value if GOMP_DEBUG is set};
is $env->gomp_debug(q{0}),   q{0},  q{GOMP_DEBUG can be set to '0' };
is $env->unset_gomp_debug(), q{0},  q{unset_gomp_debug returns last known value if GOMP_DEBUG is set};
is $env->gomp_debug,         undef, q{GOMP_DEBUG has indeed been unset};
ok !exists( $ENV{GOMP_DEBUG} ), q/$ENV{GOMP_DEBUG} doesn't exist, as expected/;
dies_ok( sub { $env->gomp_debug(q{Invalid value xxx}) }, q{gomp_debug dies on invalid input} );

# OMP_DISPLAY_ENV
note q{## OMP_DISPLAY_ENV's valid values are: 'TRUE', 'VERBOSE', 'FALSE', and may be unset};
is $env->omp_display_env(q{TRUE}),    q{TRUE},    q{OMP_DISPLAY_ENV can be set to 'TRUE' };
is $env->omp_display_env(q{true}),    q{TRUE},    q{OMP_DISPLAY_ENV can be set to 'TRUE' via 'true' };
is $env->unset_omp_display_env(),     q{TRUE},    q{unset_omp_display_env returns last known value if OMP_DISPLAY_ENV is set};
is $env->omp_display_env(q{VERBOSE}), q{VERBOSE}, q{OMP_DISPLAY_ENV can be set to 'VERBOSE' };
is $env->omp_display_env(q{verbose}), q{VERBOSE}, q{OMP_DISPLAY_ENV can be set to 'VERBOSE' via 'verbose' };
is $env->unset_omp_display_env(),     q{VERBOSE}, q{unset_omp_display_env returns last known value if OMP_DISPLAY_ENV is set};
is $env->omp_display_env(q{FALSE}),   q{FALSE},   q{OMP_DISPLAY_ENV can be set to 'FALSE' };
is $env->omp_display_env(q{false}),   q{FALSE},   q{OMP_DISPLAY_ENV can be set to 'FALSE' via 'false' };
is $env->unset_omp_display_env(),     q{FALSE},   q{unset_omp_display_env returns last known value if OMP_DISPLAY_ENV is set};
is $env->omp_display_env,             undef,      q{OMP_DISPLAY_ENV has indeed been unset};
ok !exists( $ENV{OMP_DISPLAY_ENV} ), q/$ENV{OMP_DISPLAY_ENV} doesn't exist, as expected/;
dies_ok( sub { $env->omp_display_env(q{Invalid value xxx}) }, q{omp_display_env dies on invalid input} );

# OMP_TARGET_OFFLOAD
note q{## OMP_TARGET_OFFLOAD's valid values are: 'MANDATORY', 'DISABLED', 'DEFAULT', and may be unset};
is $env->omp_target_offload(q{MANDATORY}), q{MANDATORY}, q{OMP_TARGET_OFFLOAD can be set to 'MANDATORY' };
is $env->omp_target_offload(q{mandatory}), q{MANDATORY}, q{OMP_TARGET_OFFLOAD can be set to 'MANDATORY' via 'mandatory' };
is $env->unset_omp_target_offload(),       q{MANDATORY}, q{unset_omp_target_offload returns last known value if OMP_TARGET_OFFLOAD is set};
is $env->omp_target_offload(q{DISABLED}),  q{DISABLED},  q{OMP_TARGET_OFFLOAD can be set to 'DISABLED' };
is $env->omp_target_offload(q{disabled}),  q{DISABLED},  q{OMP_TARGET_OFFLOAD can be set to 'DISABLED' via 'disabled' };
is $env->unset_omp_target_offload(),       q{DISABLED},  q{unset_omp_target_offload returns last known value if OMP_TARGET_OFFLOAD is set};
is $env->omp_target_offload(q{DEFAULT}),   q{DEFAULT},   q{OMP_TARGET_OFFLOAD can be set to 'DEFAULT' };
is $env->omp_target_offload(q{default}),   q{DEFAULT},   q{OMP_TARGET_OFFLOAD can be set to 'DEFAULT' via 'default' };
is $env->unset_omp_target_offload(),       q{DEFAULT},   q{unset_omp_target_offload returns last known value if OMP_TARGET_OFFLOAD is set};
is $env->omp_target_offload,               undef,        q{OMP_TARGET_OFFLOAD has indeed been unset};
ok !exists( $ENV{OMP_TARGET_OFFLOAD} ), q/$ENV{OMP_TARGET_OFFLOAD} doesn't exist, as expected/;
dies_ok( sub { $env->omp_target_offload(q{Invalid value xxx}) }, q{omp_target_offload dies on invalid input} );

# >= 1
# OMP_DEFAULT_DEVICE
note q{## OMP_DEFAULT_DEVICE's valid values are integers 0 or greater (>= 0)};
is $env->omp_default_device(0),      0,    q{OMP_DEFAULT_DEVICE can be set to 0};
is $env->unset_omp_default_device(), 0,    q{unset_omp_default_device returns last known value if OMP_DEFAULT_DEVICE is set};
is $env->omp_default_device(q{0}),   q{0}, q{OMP_DEFAULT_DEVICE can be set to '0'};
is $env->unset_omp_default_device(), q{0}, q{unset_omp_default_device returns last known value if OMP_DEFAULT_DEVICE is set};
for my $i ( 1 .. 10 ) {
    is $env->omp_default_device($i),     $i,     qq{OMP_DEFAULT_DEVICE can be set to $i};
    is $env->unset_omp_default_device(), $i,     q{unset_omp_default_device returns last known value if OMP_DEFAULT_DEVICE is set};
    is $env->omp_default_device(qq{$i}), qq{$i}, qq{OMP_DEFAULT_DEVICE can be set to '$i'};
    is $env->unset_omp_default_device(), qq{$i}, q{unset_omp_default_device returns last known value if OMP_DEFAULT_DEVICE is set};
}
dies_ok( sub { $env->omp_default_device(-1) },     q{omp_default_device dies on invalid input (-1)} );
dies_ok( sub { $env->omp_default_device(-2) },     q{omp_default_device dies on invalid input (-2)} );
dies_ok( sub { $env->omp_default_device(q{foo}) }, q{omp_default_device dies on invalid input ('foo')} );

# OMP_MAX_TASK_PRIORITY
note q{## OMP_MAX_TASK_PRIORITY's valid values are integers 0 or greater (>= 0)};
is $env->omp_max_task_priority(0),      0,    q{OMP_MAX_TASK_PRIORITY can be set to 0};
is $env->unset_omp_max_task_priority(), 0,    q{unset_omp_max_task_priority returns last known value if OMP_MAX_TASK_PRIORITY is set};
is $env->omp_max_task_priority(q{0}),   q{0}, q{OMP_MAX_TASK_PRIORITY can be set to '0'};
is $env->unset_omp_max_task_priority(), q{0}, q{unset_omp_max_task_priority returns last known value if OMP_MAX_TASK_PRIORITY is set};
for my $i ( 1 .. 10 ) {
    is $env->omp_max_task_priority($i),     $i,     qq{OMP_MAX_TASK_PRIORITY can be set to $i};
    is $env->unset_omp_max_task_priority(), $i,     q{unset_omp_max_task_priority returns last known value if OMP_MAX_TASK_PRIORITY is set};
    is $env->omp_max_task_priority(qq{$i}), qq{$i}, qq{OMP_MAX_TASK_PRIORITY can be set to '$i'};
    is $env->unset_omp_max_task_priority(), qq{$i}, q{unset_omp_max_task_priority returns last known value if OMP_MAX_TASK_PRIORITY is set};
}
dies_ok( sub { $env->omp_max_task_priority(-1) },     q{omp_max_task_priority dies on invalid input (-1)} );
dies_ok( sub { $env->omp_max_task_priority(-2) },     q{omp_max_task_priority dies on invalid input (-2)} );
dies_ok( sub { $env->omp_max_task_priority(q{foo}) }, q{omp_max_task_priority dies on invalid input ('foo')} );

# >= 0
# OMP_MAX_ACTIVE_LEVELS
note q{## OMP_MAX_ACTIVE_LEVELS's valid values are integers 0 or greater (>= 1)};
for my $i ( 1 .. 10 ) {
    is $env->omp_max_active_levels($i),     $i,     qq{OMP_MAX_ACTIVE_LEVELS can be set to $i};
    is $env->unset_omp_max_active_levels(), $i,     q{unset_omp_max_active_levels returns last known value if OMP_MAX_ACTIVE_LEVELS is set};
    is $env->omp_max_active_levels(qq{$i}), qq{$i}, qq{OMP_MAX_ACTIVE_LEVELS can be set to '$i'};
    is $env->unset_omp_max_active_levels(), qq{$i}, q{unset_omp_max_active_levels returns last known value if OMP_MAX_ACTIVE_LEVELS is set};
}
dies_ok( sub { $env->omp_max_active_levels(0) },      q{omp_max_active_levels dies on invalid input (0)} );
dies_ok( sub { $env->omp_max_active_levels(-1) },     q{omp_max_active_levels dies on invalid input (-1)} );
dies_ok( sub { $env->omp_max_active_levels(-2) },     q{omp_max_active_levels dies on invalid input (-2)} );
dies_ok( sub { $env->omp_max_active_levels(q{foo}) }, q{omp_max_active_levels dies on invalid input ('foo')} );

# OMP_NUM_THREADS
note q{## OMP_NUM_THREADS's valid values are integers 0 or greater (>= 1)};
for my $i ( 1 .. 10 ) {
    is $env->omp_num_threads($i),     $i,     qq{OMP_NUM_THREADS can be set to $i};
    is $env->unset_omp_num_threads(), $i,     q{unset_omp_num_threads returns last known value if OMP_NUM_THREADS is set};
    is $env->omp_num_threads(qq{$i}), qq{$i}, qq{OMP_NUM_THREADS can be set to '$i'};
    is $env->unset_omp_num_threads(), qq{$i}, q{unset_omp_num_threads returns last known value if OMP_NUM_THREADS is set};
}
dies_ok( sub { $env->omp_num_threads(0) },      q{omp_num_threads dies on invalid input (0)} );
dies_ok( sub { $env->omp_num_threads(-1) },     q{omp_num_threads dies on invalid input (-1)} );
dies_ok( sub { $env->omp_num_threads(-2) },     q{omp_num_threads dies on invalid input (-2)} );
dies_ok( sub { $env->omp_num_threads(q{foo}) }, q{omp_num_threads dies on invalid input ('foo')} );

# OMP_NUM_TEAMS
note q{## OMP_NUM_TEAMS's valid values are integers 0 or greater (>= 1)};
for my $i ( 1 .. 10 ) {
    is $env->omp_num_teams($i),     $i,     qq{OMP_NUM_TEAMS can be set to $i};
    is $env->unset_omp_num_teams(), $i,     q{unset_omp_num_teams returns last known value if OMP_NUM_TEAMS is set};
    is $env->omp_num_teams(qq{$i}), qq{$i}, qq{OMP_NUM_TEAMS can be set to '$i'};
    is $env->unset_omp_num_teams(), qq{$i}, q{unset_omp_num_teams returns last known value if OMP_NUM_TEAMS is set};
}
dies_ok( sub { $env->omp_num_teams(0) },      q{omp_num_teams dies on invalid input (0)} );
dies_ok( sub { $env->omp_num_teams(-1) },     q{omp_num_teams dies on invalid input (-1)} );
dies_ok( sub { $env->omp_num_teams(-2) },     q{omp_num_teams dies on invalid input (-2)} );
dies_ok( sub { $env->omp_num_teams(q{foo}) }, q{omp_num_teams dies on invalid input ('foo')} );

# OMP_THREAD_LIMIT
note q{## OMP_THREAD_LIMIT's valid values are integers 0 or greater (>= 1)};
for my $i ( 1 .. 10 ) {
    is $env->omp_thread_limit($i),     $i,     qq{OMP_THREAD_LIMIT can be set to $i};
    is $env->unset_omp_thread_limit(), $i,     q{unset_omp_thread_limit returns last known value if OMP_THREAD_LIMIT is set};
    is $env->omp_thread_limit(qq{$i}), qq{$i}, qq{OMP_THREAD_LIMIT can be set to '$i'};
    is $env->unset_omp_thread_limit(), qq{$i}, q{unset_omp_thread_limit returns last known value if OMP_THREAD_LIMIT is set};
}
dies_ok( sub { $env->omp_thread_limit(0) },      q{omp_thread_limit dies on invalid input (0)} );
dies_ok( sub { $env->omp_thread_limit(-1) },     q{omp_thread_limit dies on invalid input (-1)} );
dies_ok( sub { $env->omp_thread_limit(-2) },     q{omp_thread_limit dies on invalid input (-2)} );
dies_ok( sub { $env->omp_thread_limit(q{foo}) }, q{omp_thread_limit dies on invalid input ('foo')} );

# OMP_TEAMS_THREAD_LIMIT
note q{## OMP_TEAMS_THREAD_LIMIT's valid values are integers 0 or greater (>= 1)};
for my $i ( 1 .. 10 ) {
    is $env->omp_teams_thread_limit($i),     $i,     qq{OMP_THREAD_LIMIT can be set to $i};
    is $env->unset_omp_teams_thread_limit(), $i,     q{unset_omp_teams_thread_limit returns last known value if OMP_THREAD_LIMIT is set};
    is $env->omp_teams_thread_limit(qq{$i}), qq{$i}, qq{OMP_THREAD_LIMIT can be set to '$i'};
    is $env->unset_omp_teams_thread_limit(), qq{$i}, q{unset_omp_teams_thread_limit returns last known value if OMP_THREAD_LIMIT is set};
}
dies_ok( sub { $env->omp_teams_thread_limit(0) },      q{omp_teams_thread_limit dies on invalid input (0)} );
dies_ok( sub { $env->omp_teams_thread_limit(-1) },     q{omp_teams_thread_limit dies on invalid input (-1)} );
dies_ok( sub { $env->omp_teams_thread_limit(-2) },     q{omp_teams_thread_limit dies on invalid input (-2)} );
dies_ok( sub { $env->omp_teams_thread_limit(q{foo}) }, q{omp_teams_thread_limit dies on invalid input ('foo')} );

## not validated, but test set/unset
## no convenient 'uc' filters, either
# OMP_PROC_BIND
ok $env->omp_proc_bind(q{TRUE}), q{omp_proc_bind sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_proc_bind(), q{TRUE}, q{unset_omp_proc_bind returns last known value if OMP_PROC_BIND is set};
ok $env->omp_proc_bind(q{FALSE}), q{omp_proc_bind sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_proc_bind(), q{FALSE}, q{unset_omp_proc_bind returns last known value if OMP_PROC_BIND is set};
ok $env->omp_proc_bind(q{MASTER,CLOSE,SPREAD}), q{omp_proc_bind sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_proc_bind(), q{MASTER,CLOSE,SPREAD}, q{unset_omp_proc_bind returns last known value if OMP_PROC_BIND is set};

# OMP_PLACES
ok $env->omp_places(q/{0,1,2}, {3,4,6}, {7,8,9}, {10,11,12}/), q{omp_places sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_places(), q/{0,1,2}, {3,4,6}, {7,8,9}, {10,11,12}/, q{unset_omp_places returns last known value if OMP_PLACES is set};

# OMP_STACKSIZE
ok $env->omp_stacksize(1024), q{omp_stacksize sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_stacksize(), 1024, q{unset_omp_stacksize returns last known value if OMP_STACKSIZE is set};
ok $env->omp_stacksize(q{1024G}), q{omp_stacksize sets arbitrary value ok, no validation (yet)};
is $env->unset_omp_stacksize(), q{1024G}, q{unset_omp_stacksize returns last known value if OMP_STACKSIZE is set};

# OMP_SCHEDULE
ok $env->omp_schedule(q{static,10}), q{omp_schedule sets arbitrary (static,10) value ok, no validation (yet)};
is $env->unset_omp_schedule(), q{static,10}, q{unset_omp_schedule returns last known value if OMP_SCHEDULE is set};
ok $env->omp_schedule(q{dynamic,10}), q{omp_schedule sets arbitrary (dynamic,10) value ok, no validation (yet)};
is $env->unset_omp_schedule(), q{dynamic,10}, q{unset_omp_schedule returns last known value if OMP_SCHEDULE is set};
ok $env->omp_schedule(q{guided,10}), q{omp_schedule sets arbitrary (guided,10) value ok, no validation (yet)};
is $env->unset_omp_schedule(), q{guided,10}, q{unset_omp_schedule returns last known value if OMP_SCHEDULE is set};

# GOMP_CPU_AFFINITY
ok $env->gomp_cpu_affinity(q{0 3 1-2 4-15:2}), q{gomp_cpu_affinity sets arbitrary (0 3 1-2 4-15:2) value ok, no validation (yet)};
is $env->unset_gomp_cpu_affinity(), q{0 3 1-2 4-15:2}, q{unset_gomp_cpu_affinity returns last known value if OMP_PLACES is set};

# GOMP_STACKSIZE
ok $env->gomp_stacksize(1024), q{gomp_stacksize sets arbitrary (1024) value ok, no validation (yet)};
is $env->unset_gomp_stacksize(), 1024, q{unset_gomp_stacksize returns last known value if GOMP_STACKSIZE is set};

# GOMP_SPINCOUNT
ok $env->gomp_spincount(q{not sure about this one}), q{gomp_spincount sets arbitrary value ok, no validation (yet)};
is $env->unset_gomp_spincount(), q{not sure about this one}, q{unset_gomp_spincount returns last known value if GOMP_SPINCOUNT is set};

# GOMP_RTEMS_THREAD_POOLS
ok $env->gomp_rtems_thread_pools(q{not sure about this one}), q{gomp_rtems_thread_pools sets arbitrary value ok, no validation (yet)};
is $env->unset_gomp_rtems_thread_pools(), q{not sure about this one}, q{unset_gomp_rtems_thread_pools returns last known value if GOMP_RTEMS_THREAD_POOLS is set};

done_testing;

exit;
__END__
