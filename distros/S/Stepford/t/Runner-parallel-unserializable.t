## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use lib 't/lib';

use Path::Class qw( tempdir );
use Stepford::Runner;

use Test::Fatal;
use Test::More;

my $tempdir = tempdir( CLEANUP => 1 );
my $file1 = $tempdir->file('file1');
$file1->spew('stuff in the file');

my $file2 = $tempdir->file('file2');

{
    package Test::Step::A;

    use autodie;

    use Moose;
    with 'Stepford::Role::Step', 'Stepford::Role::Step::Unserializable';

    has fh => (
        traits => ['StepProduction'],
        is     => 'rw',
    );

    sub run {
        my $self = shift;

        ## no critic (InputOutput::RequireBriefOpen)
        open my $fh, '<', $file1;
        $self->fh($fh);

        return;
    }

    sub last_run_time { }
}

{
    package Test::Step::B;

    use autodie;

    use Moose;
    with 'Stepford::Role::Step';

    has fh => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    sub run {
        my $self = shift;

        my $fh      = $self->fh;
        my @content = <$fh>;
        $file2->spew(@content);
        close $fh;

        return;
    }

    sub last_run_time { }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
        jobs            => 2,
    );

    is(
        exception {
            $runner->run(
                final_steps => 'Test::Step::B',
            );
        },
        undef,
        'no exception running parallel runner to produce Test::Step::B',
    );

    is(
        scalar $file1->slurp,
        scalar $file2->slurp,
        'file1 and file2 contents are identical'
    );
}

done_testing();
