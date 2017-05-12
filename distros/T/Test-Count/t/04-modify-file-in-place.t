#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use File::Spec;
use File::Copy;
use File::Temp qw(tempdir);
use Carp;

use Test::Count::FileMutator;
use IO::Scalar;

sub _mycopy
{
    my ($src, $dest) = @_;

    File::Copy::copy($src, $dest)
        or Carp::confess("Copy failed $!");

    # This is to make the resultant file read/write on Windows.
    # See:
    # http://www.nntp.perl.org/group/perl.cpan.testers.discuss/2011/07/msg2523.html
    chmod(0644, $dest);

    return 1;
}

{
    # We need to copy everything into a temporary directory because MS
    # Windows testers do not like us writing to tests in the working copy:
    #
    # http://www.cpantesters.org/cpan/report/4936c342-71bd-1014-a781-9481788a0512

    my $temp_dir = tempdir( CLEANUP => 1);
    my $temp_lib_dir = File::Spec->catdir($temp_dir, "lib");

    my $orig_dir = File::Spec->catdir(
        File::Spec->curdir(), qw(t sample-data test-scripts)
    );

    mkdir ($temp_lib_dir);

    _mycopy (
        File::Spec->catfile($orig_dir, "lib", "MyMoreTests.pm"),
        File::Spec->catfile($temp_lib_dir, "MyMoreTests.pm")
    );

    my $orig_fn = File::Spec->catfile($orig_dir, "with-include.t");
    my $fn = File::Spec->catfile($temp_dir, "with-include-temp.t");

    _mycopy($orig_fn, $fn);

    my $mutator = Test::Count::FileMutator->new(
        {
            filename => $fn,
        }
    );

    $mutator->modify();

    open my $in, "<", $fn
        or die "Could not open '$fn' - $!.";

    my $found = 0;
    LINES_LOOP:
    while (my $l = <$in>)
    {
        chomp($l);
        if ($l eq "use Test::More tests => 3;")
        {
            $found = 1;
            last LINES_LOOP;
        }
    }

    close($in);

    # TEST
    ok ($found, "The appropriate line was found - 3 tests.");

    unlink($fn);
}

{
    my $temp_dir = tempdir( CLEANUP => 1);

    my $orig_dir = File::Spec->catdir(
        File::Spec->curdir(), qw(t sample-data test-scripts)
    );

    my $orig_fn = File::Spec->catfile($orig_dir, "with-indented-plan.t");
    my $fn = File::Spec->catfile($temp_dir,  "with-indented-plan.t");

    _mycopy($orig_fn, $fn);

    my $mutator = Test::Count::FileMutator->new(
        {
            filename => $fn,
        }
    );

    $mutator->modify();

    open my $in, "<", $fn
        or die "Could not open '$fn' - $!.";

    my $found = 0;
    my $value;
    LINES_LOOP:
    while (my $l = <$in>)
    {
        chomp($l);
        if (($value) = $l =~ m{\A\s+plan tests => (\d+);\z})
        {
            $found = 1;
            last LINES_LOOP;
        }
    }

    close($in);

    # TEST
    ok ($found, "The appropriate line was found - plan tests.");

    # TEST
    is ($value, 2, '2 tests in indented output.');

    unlink($fn);
}
