use strict;
use warnings;

use Test::More;

BEGIN
{
    unless ( eval "use Test::Output; 1;" )
    {
        plan skip_all => 'These tests require Test::Output';
    }
}

plan tests => 4;

use File::Spec;
use File::Which qw( which );
use SmokeRunner::Multi::Reporter::Screen;
use SmokeRunner::Multi::Runner::Prove;
use SmokeRunner::Multi::TestSet;
use YAML::Syck qw( LoadFile );

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();
write_t_files();

my $set = SmokeRunner::Multi::TestSet->new( set_dir => set_dir() );


NEW:
{
    my $runner = SmokeRunner::Multi::Runner->new( set => $set );

    my $reporter = eval {
        SmokeRunner::Multi::Reporter::Screen->new( runner => $runner );
    };
    isa_ok( $reporter, 'SmokeRunner::Multi::Reporter::Screen' );
}

REPORT:
{
 SKIP:
    {
        skip 'These tests require that prove be in the PATH.', 3
            unless which('prove');

        my $runner = SmokeRunner::Multi::Runner::Prove->new( set => $set );
        $runner->run_tests();

        my $reporter =
            SmokeRunner::Multi::Reporter::Screen->new( runner => $runner );

        my $output = Test::Output::stdout_from( sub { $reporter->report() } );

        like( $runner->output(), qr/01-a/,
              'reporter printed 01-a.t' );
        like( $runner->output(), qr/02-b/,
              'reporter printed 02-b.t' );
        like( $runner->output(), qr{Test Summary Report|Failed 1/2},
              'reporter printed summary output' );
    }
}
