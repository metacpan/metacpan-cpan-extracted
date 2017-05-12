#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Project;
use Path::Tiny;

tests "load_directory" => sub {
    my $Orig_Cwd = Path::Tiny->cwd;
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    mite_command( init => "Foo" );

    path("lib/Foo")->mkpath;

    path("lib/Foo.pm")->spew(<<'CODE');
package Foo;
use Foo::Mite;

has "foo" =>
    is      => 'rw';
has "bar" =>
    is      => 'rw';

1;
CODE

    path("lib/Foo/Bar.pm")->spew(<<'CODE');
package Foo::Bar;
use Foo::Mite;
extends 'Foo';

has "baz" =>
    is      => 'rw',
    default => sub { 42 };

1;
CODE

    my $project = Mite::Project->default;
    $project->add_mite_shim;
    $project->load_directory;
    $project->write_mites;

    chdir $Orig_Cwd;
};

done_testing;
