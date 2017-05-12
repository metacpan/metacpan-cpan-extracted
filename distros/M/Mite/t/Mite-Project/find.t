#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Project;
use Path::Tiny;
use autodie;

tests "find_pms and mites" => sub {
    my $orig_dir = Path::Tiny->cwd;
    my $dir = Path::Tiny->tempdir;

    chdir $dir;

    $dir->child("lib", "Foo")->mkpath;
    $dir->child("lib", "Foo.pm")->touch;
    $dir->child("lib", "Foo", "Bar.pm")->touch;
    $dir->child("lib", "Foo", "Baz.pm")->mkpath;
    $dir->child("lib", "Foo", "Baz.pm~")->touch;

    $dir->child("lib", "Foo.pm.mite.pm")->touch;
    $dir->child("lib", "Foo", "Baz.pm.mite.pm~")->touch;
    $dir->child("lib", "Foo", "Bar.pm.mite.pm")->touch;
    $dir->child("lib", "Foo", "Baz.pm.mite.pm")->mkpath;

    mite_command "init", "Foo";

    my $project = Mite::Project->default;

    cmp_deeply
      [ sort map { $_.'' } $project->find_pms ],
      [ sort
          "lib/Foo.pm",
          "lib/Foo/Bar.pm"
      ];

    cmp_deeply
      [ sort map { $_.'' } $project->find_mites ],
      [ sort 
          "lib/Foo.pm.mite.pm",
          "lib/Foo/Bar.pm.mite.pm",
      ];

    $project->clean_mites;

    cmp_deeply
      [ sort map { $_.'' } $project->find_pms ],
      [ sort
          "lib/Foo.pm",
          "lib/Foo/Bar.pm"
      ], "clean ignores non mite files";

    cmp_deeply
      [ sort map { $_.'' } $project->find_mites ],
      [], "clean only .mite.pm";

    chdir $orig_dir;
};

done_testing;
