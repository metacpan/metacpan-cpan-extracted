#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;
use Test::Output;

use autodie;
use Path::Tiny;

my $Orig_Cwd = Path::Tiny->cwd;

tests "--exit-if-no-mite-dir" => sub {
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    lives_ok { mite_command("compile", "--exit-if-no-mite-dir") };

    chdir $Orig_Cwd;
};

tests "--no-search-mite-dir" => sub {
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    # Make a .mite file above.
    mite_command("init", "Foo");

    # Go down a level
    my $subdir = $dir->child("testing");
    $subdir->mkpath;
    chdir $subdir;

    stderr_like {
        ok !eval { mite_command("compile", "--no-search-mite-dir") };
    } qr{No .mite directory found};

    stderr_is {
        mite_command("compile", "--no-search-mite-dir", "--exit-if-no-mite-dir");
    } '';

    chdir $Orig_Cwd;
};

tests "compile" => sub {
    my $dir = Path::Tiny->tempdir;
    chdir $dir;

    mite_command( init => "Foo" );
    path("lib/Foo")->mkpath;

    path("lib/Foo.pm")->spew(<<'CODE');
package Foo;
use Foo::Mite;

has "foo" =>
  is    => 'rw';

has "bar" =>
  is    => 'rw';

1;
CODE

    path("lib/Foo/Bar.pm")->spew(<<'CODE');
package Foo::Bar;
use Foo::Mite;
extends 'Foo';

has "baz" =>
    is          => 'rw',
    default     => sub { 42 };

1;
CODE

    mite_command("compile");

    ok -e "lib/Foo/Mite.pm";

    local @INC = ("lib", @INC);
    require_ok 'Foo';
    require_ok 'Foo::Bar';

    my $foo  = new_ok "Foo", [foo => 99];
    my $fbar = new_ok "Foo::Bar";

    is $foo->foo, 99;
    is $foo->bar, undef;

    is $fbar->foo, undef;
    is $fbar->bar, undef;
    is $fbar->baz, 42;

    chdir $Orig_Cwd;
};

done_testing;
