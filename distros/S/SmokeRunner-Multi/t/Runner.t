use strict;
use warnings;

use Test::More tests => 4;

use File::Spec;
use SmokeRunner::Multi::Runner;
use SmokeRunner::Multi::TestSet;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();
write_t_files();

my $set = SmokeRunner::Multi::TestSet->new( set_dir => set_dir() );

NEW:
{
    my $runner = eval { SmokeRunner::Multi::Runner->new() };
    like( $@, qr/mandatory parameter/i,
          'cannot create a runner without a set' );

    $runner = eval { SmokeRunner::Multi::Runner->new( set => $set ) };
    is( $@, '', 'created runner with a valid set' );
    isa_ok( $runner, 'SmokeRunner::Multi::Runner' );
}

RUN_TESTS:
{
    my $runner = SmokeRunner::Multi::Runner->new( set => $set );

    eval { $runner->run_tests() };
    like( $@, qr/must be overridden/,
          'cannot call run_tests() on base class' );
}
