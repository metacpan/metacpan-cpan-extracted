## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Stepford::Runner;

use Test::More;

my $ran_step_1;
my $ran_step_2;
my $ran_step_3;

{
    package Test::Step::Step1;
    use Moose;
    use Stepford::Types qw( Str );
    with 'Stepford::Role::Step';

    has str1 => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => Str,
        default => sub { 1 },
    );

    sub run {
        $ran_step_1 = 1;
    }

    sub last_run_time { undef }
}

{
    package Test::Step::Step2;
    use Moose;
    use Stepford::Types qw( Str );
    with 'Stepford::Role::Step';

    has str1 => (
        traits   => ['StepDependency'],
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has str2 => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => Str,
        default => sub { 'str2' },
    );

    sub run {
        $ran_step_2 = 1;
    }

    sub last_run_time { 1 }
}

{
    package Test::Step::Step3;
    use Moose;
    use Stepford::Types qw( Str );
    with 'Stepford::Role::Step';

    has str2 => (
        traits   => ['StepDependency'],
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has str3 => (
        traits  => ['StepProduction'],
        is      => 'rw',
        isa     => Str,
        default => sub { 'str3' },
    );

    sub run {
        $ran_step_3 = 1;
    }

    sub last_run_time { 2 }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
    );

    $runner->run(
        final_steps => 'Test::Step::Step3',
    );

    ok( $ran_step_1, 'Step 1 with undef last_run_time ran' );
    ok( $ran_step_2, 'Step 2 with dependency with undef last_run_time' );
    ok(
        !$ran_step_3,
        'Step 3 with dependency with older last_run_time did not run',
    );
}

done_testing();
