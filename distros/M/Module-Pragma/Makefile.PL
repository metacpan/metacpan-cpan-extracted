#!perl

use 5.010_000;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Module::Pragma',
    AUTHOR              => 'Goro Fuji <gfuji(at)cpan.org>',
    VERSION_FROM        => 'lib/Module/Pragma.pm',
    ABSTRACT_FROM       => 'lib/Module/Pragma.pm',

    LICENSE             => 'perl',
);
