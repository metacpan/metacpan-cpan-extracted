## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable, Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Path::Class qw( tempdir );
use Stepford::Runner;
use Time::HiRes qw( sleep );

use Test::More;

my $dir   = tempdir( CLEANUP => 1 );
my $file1 = $dir->file('file1');
my $file2 = $dir->file('file2');
my $file3 = $dir->file('file3');
my $wait  = $dir->file('wait');

# How this test works:
#
#   Step 1: Just creates 'file1' on disk
#   Step 2: Dependent on Step 1, create 'file2' on disk with the contents of 'file1'
#   Step 3: Dependent on Step 2, create 'file3' on disk with the contents of 'file2'
#
#  The first time through we run step 3 that creates all the files
#
#  The second time through we run things but since the files haven't changed
#  the steps aren't re-run

#  The third time through we remove 'file1' before running things.  This causes
#  last_run_time of that step to return "undef", which means it will
#  unconditionally run.
#
#  The fourth time through we touch 'file2' before running things.  Because
#  the dependency has been altered the second and third step are re-run again,
#  but the first step isn't re-run (because that hasn't changed.)

#  The fifth time though we turn on force_step_execution when running things.
#  We expect everything to be re-run because we explictly told it to

my $iteration = 1;

{
    package Test::Step::Step1;
    use Stepford::Types qw( File );
    use Moose;
    with 'Stepford::Role::Step::FileGenerator';

    has file1 => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => File,
        default => sub { $file1 },
    );

    sub run {
        return if -f $_[0]->file1;
        $_[0]->file1->spew( __PACKAGE__ . " - $iteration\n" );
    }
}

{
    package Test::Step::Step2;
    use Stepford::Types qw( File );
    use Moose;
    with 'Stepford::Role::Step::FileGenerator';

    has file1 => (
        traits   => ['StepDependency'],
        is       => 'ro',
        isa      => File,
        required => 1,
    );

    has file2 => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => File,
        default => sub { $file2 },
    );

    sub run {
        $_[0]->file2->spew(
            $_[0]->file1->slurp . __PACKAGE__ . " - $iteration\n" );
    }
}

{
    package Test::Step::Step3;
    use Stepford::Types qw( File );
    use Moose;
    with 'Stepford::Role::Step::FileGenerator';

    has file2 => (
        traits   => ['StepDependency'],
        is       => 'ro',
        isa      => File,
        required => 1,
    );

    has file3 => (
        traits  => ['StepProduction'],
        is      => 'ro',
        isa     => File,
        default => sub { $file3 },
    );

    sub run {
        $_[0]->file3->spew(
            $_[0]->file2->slurp . __PACKAGE__ . " - $iteration\n" );
        $iteration++;
    }
}

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test::Step',
    );

    $runner->run(
        final_steps => 'Test::Step::Step3',
    );

    for my $file ( $file1, $file2, $file3 ) {
        ok(
            -f $file,
            $file->basename . ' exists after running all steps'
        );
    }

    my $expect = <<'EOF';
Test::Step::Step1 - 1
Test::Step::Step2 - 1
Test::Step::Step3 - 1
EOF

    is(
        scalar $file3->slurp,
        $expect,
        $file3->basename . ' contains expected content'
    );

    $runner->run(
        final_steps => 'Test::Step::Step3',
    );

    is(
        scalar $file3->slurp,
        $expect,
        $file3->basename
            . ' content does not change if file1 is not regenerated on second run'
    );

    # The way this test is meant to work is that deleting file1 causes file2
    # and file3 to be regenerated also because file1 is missing and will be
    # regenerated causing it to have a new modification time.
    #
    # The use of $wait here is to make sure the file system is able to
    # detect that file1 was re-written.  Because some file systems (e.g. HFS)
    # have one-second granularity on their modification times then this test
    # can fail as deleting file1 and then having file1 recreated within the
    # same second as it was originally created means that when we get to step2
    # we have the same timestamp and step2 is not run.

    $wait->touch;
    $file1->remove or diag "Could not remove file1!\n";
    touch_and_ensure_new_mtime($wait);

    $runner->run(
        final_steps => 'Test::Step::Step3',
    );

    $expect = <<'EOF';
Test::Step::Step1 - 2
Test::Step::Step2 - 2
Test::Step::Step3 - 2
EOF

    is(
        scalar $file3->slurp,
        $expect,
        $file3->basename
            . ' content does change when file1 is regenerated on third run'
    );

    touch_and_ensure_new_mtime($file2);

    $runner->run(
        final_steps => 'Test::Step::Step3',
    );

    $expect = <<'EOF';
Test::Step::Step1 - 2
Test::Step::Step2 - 2
Test::Step::Step3 - 3
EOF

    is(
        scalar $file3->slurp,
        $expect,
        $file3->basename
            . ' content does change when file3 is regenerated on fourth run'
    );

    $runner->run(
        final_steps          => 'Test::Step::Step3',
        force_step_execution => 1,
    );

    $expect = <<'EOF';
Test::Step::Step1 - 2
Test::Step::Step2 - 4
Test::Step::Step3 - 4
EOF

    is(
        scalar $file3->slurp,
        $expect,
        'everything changes when we force_step_execution'
    );
}

done_testing();

sub touch_and_ensure_new_mtime {
    my $file = shift;

    # the simple case, where the file system has sub-second modification times
    my $mtime = $file->stat->mtime;
    sleep 0.01;
    $file->touch;
    return if $mtime != $file->stat->mtime;

    # in *theory* we could use utime here to do things, but that comes with
    # its own portability issues when I looked into it

    # okay, some systems (e.g. OSX's HFS+, various Windows file systems)
    # may have one to two second resoluton times. Wait until that's updated
    foreach ( 1 .. ( 2 / 0.01 ) ) {
        sleep 0.01;
        $file->touch;
        return if $mtime != $file->stat->mtime;
    }

    # pathological case here, where the stat times aren't updating at all.
    # This typically happens with something like NFS with stat caching
    # enabled.  Rather than touching the file, let's try re-writing it
    $file->spew( $file->slurp );
    return if $mtime != $file->stat->mtime;

    die "Can't update modification time of $file";
}
