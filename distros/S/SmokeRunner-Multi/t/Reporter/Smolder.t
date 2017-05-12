use strict;
use warnings;

use Test::More tests => 8;

use File::Spec;
use SmokeRunner::Multi::Reporter::Smolder;
use SmokeRunner::Multi::Runner::TAPArchive;
use SmokeRunner::Multi::TestSet;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();
write_t_files();

my $set = SmokeRunner::Multi::TestSet->new( set_dir => set_dir() );

my $path_sep = $^O eq 'MSWin32' ? ';' : ':';
$ENV{PATH} = join $path_sep, 't/bin', File::Spec->path();


NEW:
{
    my $runner = SmokeRunner::Multi::Runner->new( set => $set );
    my $reporter =
        eval { SmokeRunner::Multi::Reporter::Smolder->new( runner => $runner ); };
    like( $@, qr/No config item for smolder server/,
          'cannot create a new Smolder reporter without smolder config' );

    write_smolder_config();
    $reporter =
        eval { SmokeRunner::Multi::Reporter::Smolder->new( runner => $runner ); };
    like( $@, qr/\QRunner must be a TAPArchive runner/,
          'cannot create a new Smolder reporter with a base runner' );

    $runner = SmokeRunner::Multi::Runner::TAPArchive->new( set => $set );
    $runner->run_tests();

    $reporter =
        eval { SmokeRunner::Multi::Reporter::Smolder->new( runner => $runner ); };
    isa_ok( $reporter, 'SmokeRunner::Multi::Reporter::Smolder' );
}

REPORT:
{
    my $runner = SmokeRunner::Multi::Runner::TAPArchive->new( set => $set );
    $runner->run_tests();

    my $reporter =
        SmokeRunner::Multi::Reporter::Smolder->new( runner => $runner );

    my $signal;
    {
        no warnings 'redefine';
        *SmokeRunner::Multi::Reporter::Smolder::safe_run =
            sub { $signal = { @_ } };
    }

    $reporter->report();

    my %args = @{ $signal->{args} };

    for my $k ( qw( server username password ) )
    {
        is( $args{"--$k"}, SmokeRunner::Multi::Config->instance()->smolder()->{$k},
            "$k passed to smolder_smoke_signal is same as $k in config" );
    }

    is( $args{'--project'}, $set->name(),
        'project passed to smolder_smoke_signal was set name' );
    ok( -f $args{'--file'},
        'file passed to smolder_smoke_signal exists' );
}
