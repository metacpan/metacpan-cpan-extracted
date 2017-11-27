#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::TempDir::Tiny;
use Module::Starter qw/Module::Starter::Smart/;
use File::Spec;

my $tempdir = tempdir();
my $root = File::Spec->catdir($tempdir, 'Foo-Bar');

{
    local $SIG{__WARN__} = sub {
        warn $_[0] unless $_[0] =~ /^Added to MANIFEST/;
    };

    Module::Starter->create_distro(
        author  => 'me',
        builder  => 'Module::Build',
        modules  => ['Foo::Bar'],
        email    => 'me@there.com',
        dir      => $root,
    );
}

ok(-d $root, 'Module root exists');

my $file = File::Spec->catfile($root, qw(lib Foo Bar.pm));
ok(-f $file, 'Module file exists');

push @INC, File::Spec->catdir($root, 'lib');
require_ok('Foo::Bar');
