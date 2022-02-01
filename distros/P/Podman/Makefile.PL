#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'   => 'Library of bindings to use the RESTful API of Podman.',
    'AUTHOR'     => 'Tobias Schaefer <github@blackox.org>',
    'DISTNAME'   => 'Podman',
    'META_MERGE' => {
        resources => {
            'license'    => 'http://dev.perl.org/licenses',
            'homepage'   => 'https://github.com/tschaefer/podman-perl',
            'repository' => 'https://github.com/tschaefer/podman-perl.git',
        }
    },
    'NAME'      => 'Podman',
    'PREREQ_PM' => {
        'Mojolicious'       => '9.22',
        'Moose'             => '2.2014',
        'Path::Tiny'        => '0.114',
        'Readonly'          => '2.05',
        'Test::Exception'   => '0.43',
        'Test::Moose::More' => '0.050',
        'Try::Tiny'         => '0.31',
    },
    'VERSION_FROM' => 'lib/Podman.pm',
    'clean'        => { FILES    => 'Podman-*' },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
);
