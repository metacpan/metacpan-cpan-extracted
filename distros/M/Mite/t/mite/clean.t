#!/usr/bin/perl

# This is just for testing that "mite clean" basically works.
# Put more elaborate tests into the appropriate class test.

use lib 't/lib';
use Test::Mite;

use Mite::Project;

tests "clean" => sub {
    my $orig_dir = Path::Tiny->cwd;
    my $dir = Path::Tiny->tempdir;

    chdir $dir;

    $dir->child("lib", "Foo")->mkpath;
    $dir->child("lib", "Foo.pm")->spew(<<CODE);
package Foo;
use Foo::Mite;

has "something" =>
  is    => 'rw';

1;
CODE

    $dir->child("lib", "Foo", "Bar.pm")->spew(<<CODE);
package Foo::Bar;
use Foo::Mite;
extends "Foo";

1;
CODE

    mite_command "init", "Foo";
    mite_command "compile";

    my $project = Mite::Project->default;

    cmp_deeply
      [ sort map { $_.'' } $project->find_mites ],
      [ sort 
          "lib/Foo.pm.mite.pm",
          "lib/Foo/Bar.pm.mite.pm",
      ];

    mite_command "clean";

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
