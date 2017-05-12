## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Stepford::Runner;

use Test::More;

my $dep_of_multiple_steps_run_count;
my $parent_step_1_run_count;
my $parent_step_2_run_count;
my $top_step_run_count;

{
    package Test::Step::DepOfMultipleSteps;
    use Moose;
    with 'Stepford::Role::Step';

    has popular_dep => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run {
        $dep_of_multiple_steps_run_count++;
    }

    sub last_run_time { }
}

{
    package Test::Step::Parent1;
    use Moose;
    with 'Stepford::Role::Step';

    has popular_dep => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has parent_dep_1 => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run {
        $parent_step_1_run_count++;
    }

    sub last_run_time { }
}

{
    package Test::Step::Parent2;
    use Moose;
    with 'Stepford::Role::Step';

    has popular_dep => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has parent_dep_2 => (
        traits => ['StepProduction'],
        is     => 'ro',
    );

    sub run {
        $parent_step_2_run_count++;
    }

    sub last_run_time { }
}

{
    package Test::Step::Top;
    use Moose;
    with 'Stepford::Role::Step';

    has parent_dep_1 => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has parent_dep_2 => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has top => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub run {
        $top_step_run_count++;
    }

    sub last_run_time { }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
    );

    $runner->run(
        final_steps => 'Test::Step::Top',
    );

    is(
        $dep_of_multiple_steps_run_count, 1,
        'ran step that is child of multiple parents once'
    );
    is( $parent_step_1_run_count, 1, 'Ran parent 1 once' );
    is( $parent_step_2_run_count, 1, 'Ran parent 2 once' );
    is( $top_step_run_count,      1, 'Ran top step once' );
}

done_testing();
