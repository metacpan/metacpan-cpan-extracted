## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;
use autodie;

use lib 't/lib';

use Path::Class qw( dir tempdir );
use Stepford::Runner;
use Test::More;
use Test::Differences;

my $tempdir = tempdir( CLEANUP => 1 );

{
    package DryTest::Step::A;

    use Moose;
    with 'Stepford::Role::Step';

    has thing_a => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run           { }
    sub last_run_time { }
}

{
    package DryTest::Step::B;

    use Moose;
    with 'Stepford::Role::Step';

    has thing_a => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has thing_b => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run           { }
    sub last_run_time { }
}

{
    package DryTest::Step::C;

    use Moose;
    with 'Stepford::Role::Step';

    has thing_b => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has thing_c => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run           { }
    sub last_run_time { }
}

{
    package DryTest::Step::D;
    use Stepford::Types qw( File );

    use Moose;
    with 'Stepford::Role::Step::FileGenerator';

    has thing_b => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has thing_c => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has thing_d => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => File,
    );

    sub run {
        my $self = shift;
        use Path::Class qw( file );
        my $file = $tempdir->file('d');
        $file->spew('line 1');
    }

    sub last_run_time { }
}

{
    use Capture::Tiny qw( capture );
    my $runner = Stepford::Runner->new(
        step_namespaces => 'DryTest::Step',
    );

    my ( $stdout, $stderr, @result ) = capture {
        $runner->run(
            final_steps => 'DryTest::Step::D',
            dry_run     => 'txt',
        );
    };

    is $stderr, q{}, 'nothing on stderr';
    eq_or_diff(
        $stdout,
        $runner->_make_root_graph_builder(
            ['DryTest::Step::D'],
            {},
        )->graph->as_string,
        'printed graph as_string'
    );

    ok !( -e $tempdir->file('d') ), 'dry run did not create files';

}

done_testing();
