## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;
use autodie;

use Log::Dispatch;
use Log::Dispatch::Array;
use Path::Class qw( tempdir );
use Stepford::Runner;

use Test::Fatal;
use Test::More;

my @messages;
my $logger = Log::Dispatch->new(
    outputs => [
        [
            'Array',
            name      => 'array',
            array     => \@messages,
            min_level => 'debug',
        ],
    ],
);

my $tempdir    = tempdir( CLEANUP => 1 );
my $last1_file = "$tempdir/last1";
my $last2_file = "$tempdir/last2";
my $last3_file = "$tempdir/last3";

{
    package Test::Step::MakesValue;
    use Moose;
    with 'Stepford::Role::Step';

    has value => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub last_run_time { undef }

    sub run {
        $_[0]->value(42);
    }
}

{
    package Test::Step::Dies;
    use Moose;
    with 'Stepford::Role::Step';

    has value => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has value1 => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub last_run_time { undef }

    sub run {
        die 'This step dies on its own';
    }
}

{
    package Test::Step::Last1;
    use Moose;
    with 'Stepford::Role::Step';

    has value1 => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    sub last_run_time { undef }

    sub run {
        open my $fh, '>', $last1_file or die $!;
        close $fh or die $!;
    }
}

{
    package Test::Step::KillsSelf;
    use Moose;
    with 'Stepford::Role::Step';

    has value => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has value2 => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub last_run_time { undef }

    sub run {
        kill 9, $$ or die 'doh, so broken';
    }
}

{
    package Test::Step::Last2;
    use Moose;
    with 'Stepford::Role::Step';

    has value2 => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    sub last_run_time { undef }

    sub run {
        open my $fh, '>', $last2_file or die $1;
        close $fh;
    }
}

{
    package Test::Step::Exits;
    use Moose;
    with 'Stepford::Role::Step';

    has value => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    has value3 => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub last_run_time { undef }

    sub run {
        exit 42;
    }
}

{
    package Test::Step::Last3;
    use Moose;
    with 'Stepford::Role::Step';

    has value3 => (
        traits => ['StepDependency'],
        is     => 'ro',
    );

    sub last_run_time { undef }

    sub run {
        open my $fh, '>', $last3_file or die $1;
        close $fh;
    }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
        logger          => $logger,
        jobs            => 2,
    );

    like(
        exception { $runner->run( final_steps => 'Test::Step::Last1' ) },
        qr/Child process \d+ died while running step Test::Step::Dies with error:\nThis step dies on its own/,
        'runner aborted run because child process died'
    );

    ok(
        !-f $last1_file,
        'file created by final step does not exist because previous step died'
    );
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
        logger          => $logger,
        jobs            => 2,
    );

    like(
        exception { $runner->run( final_steps => 'Test::Step::Last2' ) },
        qr/Child process \d+ did not send back any data while running step Test::Step::KillsSelf \(exited because of signal 9\)/,
        'runner aborted run because child process exited through a signal'
    );

    ok(
        !-f $last2_file,
        'file created by final step does not exist because previous step was killed'
    );
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
        logger          => $logger,
        jobs            => 2,
    );

    like(
        exception { $runner->run( final_steps => 'Test::Step::Last3' ) },
        qr/Child process \d+ failed while running step Test::Step::Exits \(exited with code 42\)/,
        'runner aborted run because child process exited by calling exit'
    );

    ok(
        !-f $last3_file,
        'file created by final step does not exist because previous step called exit'
    );
}

done_testing();
