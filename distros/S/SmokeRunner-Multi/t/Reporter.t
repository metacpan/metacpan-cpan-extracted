use strict;
use warnings;

use Test::More tests => 4;

use File::Spec;
use SmokeRunner::Multi::Reporter;
use SmokeRunner::Multi::Runner;
use SmokeRunner::Multi::TestSet;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();
write_t_files();

my $set = SmokeRunner::Multi::TestSet->new( set_dir => set_dir() );
my $runner = SmokeRunner::Multi::Runner->new( set => $set );

NEW:
{
    my $reporter = eval { SmokeRunner::Multi::Reporter->new() };
    like( $@, qr/mandatory parameter/i,
          'cannot create a runner without a set' );

    $reporter = eval {
        SmokeRunner::Multi::Reporter->new( runner => $runner );
    };
    is( $@, '', 'created runner with a valid runner' );
    isa_ok( $reporter, 'SmokeRunner::Multi::Reporter' );
}

REPORT:
{
    my $reporter
        = SmokeRunner::Multi::Reporter->new( runner => $runner );

    eval { $reporter->report() };
    like( $@, qr/must be overridden/,
          'cannot call report() on base class' );
}
