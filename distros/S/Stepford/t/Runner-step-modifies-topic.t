## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Stepford::Runner;

use Test::Fatal qw( exception );
use Test::More;

{
    package Test::Step::P1;
    use Moose;
    with 'Stepford::Role::Step';

    has dep => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run {
        $_ = undef;
    }

    sub last_run_time { $_ = undef; }
}

{
    package Test::Step::Top;
    use Moose;
    with 'Stepford::Role::Step';

    has dep => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has top => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub run {
        $_ = undef;
    }

    sub last_run_time { $_ = undef; }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
    );

    is(
        exception {
            $runner->run(
                final_steps => 'Test::Step::Top',
                )
        },
        undef,
        'no exception when topic variable is modified by a step'
    );

}

done_testing();
