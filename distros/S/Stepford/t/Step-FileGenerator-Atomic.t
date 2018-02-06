## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Log::Dispatch;
use Log::Dispatch::Null;
use Path::Class qw( tempdir );

use Test::Fatal;
use Test::More;

my $tempdir = tempdir( CLEANUP => 1 );
my $logger
    = Log::Dispatch->new( outputs => [ [ Null => min_level => 'emerg' ] ] );

{
    package AtomicFileGeneratorTest::TooManyFilesStep;

    use Moose;
    use Stepford::Types qw( File );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has [qw( a_production another_production )] => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => File,
    );

    sub run { }
}

{
    my $e = exception {
        AtomicFileGeneratorTest::TooManyFilesStep->new( logger => $logger );
    };
    like(
        $e,
        qr/
            \QThe AtomicFileGeneratorTest::TooManyFilesStep class consumed \E
            \Qthe Stepford::Role::Step::FileGenerator::Atomic role but \E
            \Qcontains more than one production: a_production \E
            \Qanother_production\E
           /x,
        'AtomicFileGeneratorTest::TooManyFilesStep->new dies because it'
            . ' contains more than one production',
    );
}

{
    package AtomicFileGeneratorTest::NoWrittenFileStep;

    use Moose;
    use Path::Class qw( tempdir );
    use Stepford::Types qw( File );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has a_production => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => File,
        default => sub { $tempdir->file('never_written') },
    );

    sub run { }
}

{
    my $iut = AtomicFileGeneratorTest::NoWrittenFileStep->new(
        logger => $logger );
    my $e = exception { $iut->run };
    like(
        $e,
        qr/
            \QThe AtomicFileGeneratorTest::NoWrittenFileStep class consumed \E
            \Qthe Stepford::Role::Step::FileGenerator::Atomic role but \E
            \Qrun produced no pre-commit production file at: \E
           /x,
        'AtomicFileGeneratorTest::NoWrittenFileStep->run dies because the'
            . ' production file was not found after concrete step run',
    );
}

{
    package AtomicFileGeneratorTest::TwoLineFileGenerator;

    use Moose;
    use Stepford::Types qw( Bool File );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has a_file => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => File,
    );

    has should_die => (
        is       => 'ro',
        isa      => Bool,
        required => 1,
    );

    sub run {
        my $self = shift;
        my $file = $self->pre_commit_file;
        $file->spew('line 1');
        die 'expected death' if $self->should_die;
        $file->spew("line 1\nline 2");
    }
}

{
    package AtomicFileGeneratorTest::TwoLineFileGenerator::PathTiny;

    use Moose;

    use MooseX::Types::Path::Tiny qw( Path );
    use Stepford::Types qw( Bool );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has a_file => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => Path,
        coerce => 1,
    );

    has should_die => (
        is       => 'ro',
        isa      => Bool,
        required => 1,
    );

    sub run {
        my $self = shift;
        my $file = $self->pre_commit_file;
        $file->spew('line 1');
        die 'expected death' if $self->should_die;
        $file->spew("line 1\nline 2");
    }
}

for my $class (
    qw( AtomicFileGeneratorTest::TwoLineFileGenerator
    AtomicFileGeneratorTest::TwoLineFileGenerator::PathTiny )
) {
    subtest $class => sub {
        {
            my $file            = $tempdir->file('no_interruption');
            my $step_that_lives = $class->new(
                logger     => $logger,
                should_die => 0,
                a_file     => $file,
            );

            my $pre_commit_file = $step_that_lives->pre_commit_file;
            is(
                $pre_commit_file->parent->stringify,
                $file->parent->stringify,
                'pre_commit_file and final file are in the same directory'
            );

            $step_that_lives->run;
            is(
                $file->slurp,
                "line 1\nline 2",
                'file written correctly to final destination when run not'
                    . ' interrupted',
            );

            undef $step_that_lives;
            ok(
                !-f $pre_commit_file,
                'pre commit file cleaned after step runs'
            );
        }

        {
            my $file           = $tempdir->file('interruption');
            my $step_that_dies = $class->new(
                logger     => $logger,
                should_die => 1,
                a_file     => $file,
            );

            my $pre_commit_file = $step_that_dies->pre_commit_file;

            exception { $step_that_dies->run };
            ok( !-e $file, 'file not written at all when run interrupted' );

            ok(
                !-f $pre_commit_file,
                'pre commit file cleaned even if step dies mid-run'
            );
        }
    };
}

{
    package AtomicFileGeneratorTest::PostCommitExists;

    use Moose;
    use Stepford::Types qw( Bool File );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has a_file => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => File,
    );

    my $x = 0;

    sub run {
        my $self = shift;

        return if -f $self->a_file && $self->a_file !~ /regenerate/;

        $self->pre_commit_file->spew( __PACKAGE__ . ' - ' . $x++ );
    }
}

{
    my $post_commit = $tempdir->file('post-commit-exists-is-ok');
    my $step        = AtomicFileGeneratorTest::PostCommitExists->new(
        a_file => $post_commit,
        logger => $logger,
    );

    $step->run;

    is(
        $post_commit->slurp,
        'AtomicFileGeneratorTest::PostCommitExists - 0',
        'post commit file has expected content after first run'
    );

    is(
        exception { $step->run },
        undef,
        'no exception running step a second time'
    );

    is(
        $post_commit->slurp,
        'AtomicFileGeneratorTest::PostCommitExists - 0',
        'post commit file has expected content after second run'
    );
}

{
    my $post_commit = $tempdir->file('should-regenerate');
    my $step        = AtomicFileGeneratorTest::PostCommitExists->new(
        a_file => $post_commit,
        logger => $logger,
    );

    $step->run;

    is(
        $post_commit->slurp,
        'AtomicFileGeneratorTest::PostCommitExists - 1',
        'post commit file has expected content after first run'
    );

    is(
        exception { $step->run },
        undef,
        'no exception running step a second time'
    );

    is(
        $post_commit->slurp,
        'AtomicFileGeneratorTest::PostCommitExists - 2',
        'pre commit file is used even when post commit file exists'
    );
}

done_testing();
