use strict;
use warnings;

use Test::More tests => 13;

use File::Which qw( which );
use SmokeRunner::Multi;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();

NEW:
{
    my $smoker = SmokeRunner::Multi->new();
    isa_ok( $smoker, 'SmokeRunner::Multi' );
}

NEXT_TEST_SET:
{
    write_four_sets();

    my $smoker = SmokeRunner::Multi->new();

    my $next_set = $smoker->next_set();
    is( $next_set->name(), 'set1', 'next_set() returns expected set' );
}

_CLASS_FOR:
{
    my $smoker = SmokeRunner::Multi->new();

    eval { $smoker->_class_for( 'Runner' ) };
    like( $@, qr/\QNo config for runner/,
          'cannot call _class_for with one arg' );

    eval { $smoker->_class_for( 'Runner', undef ) };
    like( $@, qr/\QNo config for runner/,
          'cannot call _class_for with undef as second arg' );

    eval { $smoker->_class_for( 'Runner', 'DoesNotExist' ) };
    like( $@, qr/\QCan't locate/,
          'cannot call _class_for with invalid class name' );

    is( $smoker->_class_for( 'Runner', 'TAPArchive' ),
        'SmokeRunner::Multi::Runner::TAPArchive',
        '_class_for() returns full class name' );

    is( $smoker->_class_for( 'Runner', 'TAPArchive' ),
        'SmokeRunner::Multi::Runner::TAPArchive',
        '_class_for() returns full class name on second call' );

    is( $smoker->_class_for( 'Runner', 'SmokeRunner::Multi::Runner::TAPArchive' ),
        'SmokeRunner::Multi::Runner::TAPArchive',
        '_class_for() returns full class name when given full class name' );
}

MAKE_THINGS:
{
    my $smoker = SmokeRunner::Multi->new();

    my $next_set = $smoker->next_set();

    my $runner = $smoker->make_runner( set => $next_set );
    isa_ok( $runner, 'SmokeRunner::Multi::Runner::Prove' );

    my $reporter = $smoker->make_reporter( runner => $runner );
    isa_ok( $reporter, 'SmokeRunner::Multi::Reporter::Test' );
}

RUN_AND_REPORT_NEXT_SET:
{
 SKIP:
    {
        skip 'These tests require that prove be in the PATH.', 3
            unless which('prove');

        my $smoker = SmokeRunner::Multi->new();
        my $next_set = $smoker->next_set();

        my $last_run_time = $next_set->last_run_time();
        $next_set->prioritize();

        my $reporter = $smoker->run_and_report_next_set();

        like( $reporter->output(), qr/01-a/,
              'reporter has some output' );

        my $set = SmokeRunner::Multi::TestSet->new( set_dir => $next_set->set_dir() );

        ok( ! $set->is_prioritized(),
            'set is no longer prioritized and calling run_and_report_next_set()' );
        cmp_ok( $set->last_run_time(), '>', $last_run_time,
                'last run time for set was updated' );
    }
}
