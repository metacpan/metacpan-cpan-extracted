use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::AutoParams',
    VERSION_FROM     => 'lib/Mojolicious/Plugin/AutoParams.pm',
    AUTHOR           => q{Brian Duggan <bduggan@matatu.org>},
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/AutoParams.pm',
    LICENSE          => 'Artistic_2_0',
    PREREQ_PM        => { 'Mojolicious' => '5.0' },
    test             => {TESTS => 't/*.t'},
    META_MERGE   => {
        resources => {
          repository => 'https://github.com/bduggan/Mojolicious-Plugin-AutoParams.git',
        }
    }
);
