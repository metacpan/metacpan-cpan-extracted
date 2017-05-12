#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Path::Tiny;
use autodie;

use Mite::MakeMaker;

my $Orig_Dir = Path::Tiny->cwd;

tests "change_parent_dir" => sub {
    is Mite::MakeMaker::change_parent_dir(
        path("lib"),
        path("blib/lib"),
        path("lib/Foo/Bar.pm")
       ),
       "blib/lib/Foo/Bar.pm";
};

tests "fix_pm_to_blib" => sub {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my @blib_want;

    # Set up some test files for moving.
    path("lib/Foo.pm")->touchpath;
    path("lib/Foo.pm.mite.pm")->touchpath;
    push @blib_want,
      path("blib/lib/Foo.pm"),
      path("blib/lib/Foo.pm.mite.pm");

    # Deliberately has no mite file.
    path("lib/Bar.pm")->touchpath;
    push @blib_want,
      path("blib/lib/Bar.pm");

    # A subdirectory to ensure it's recusive.
    path("lib/Foo/Bar/Woof.pm")->touchpath;
    path("lib/Foo/Bar/Woof.pm.mite.pm")->touchpath;
    push @blib_want,
      path("blib/lib/Foo/Bar/Woof.pm"),
      path("blib/lib/Foo/Bar/Woof.pm.mite.pm");

    my $blib = path("blib/lib");
    $blib->mkpath;

    Mite::MakeMaker->fix_pm_to_blib("lib", "blib/lib");

    my @blib_have;
    my $blib_iter = $blib->iterator({ recurse => 1 });
    while( my $path = $blib_iter->() ) {
        next if -d $path;
        push @blib_have, $path;
    }

    cmp_deeply \@blib_have, bag(@blib_want);

    chdir $Orig_Dir;
};


done_testing;
