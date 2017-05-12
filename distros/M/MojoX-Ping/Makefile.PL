#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

if ($^O eq 'MSWin32') {
    die "Building on OS '$^O' is unsupported. Only *nix systems\n";
}

WriteMakefile(
    NAME          => 'MojoX::Ping',
    AUTHOR        => 'Sergey Zasenko <d3fin3@gmail.com>',
    LICENSE       => 'artistic_2',
    ABSTRACT_FROM => 'lib/MojoX/Ping.pm',
    VERSION_FROM  => 'lib/MojoX/Ping.pm',

    BUILD_REQUIRES => {'Test::More'  => '0.88'},
    PREREQ_PM      => {'Mojolicious' => '2.37'},
    META_MERGE => {
        x_deprecated => 1,
        resources => {repository => 'https://github.com/und3f/mojox-ping'},
    },
);
