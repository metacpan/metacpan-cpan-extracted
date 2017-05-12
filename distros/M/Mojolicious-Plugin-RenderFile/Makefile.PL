use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::RenderFile',
    VERSION_FROM     => 'lib/Mojolicious/Plugin/RenderFile.pm',
    AUTHOR           => 'Viktor Turskyi <koorchik@cpan.org>',
    MIN_PERL_VERSION => 5.010,
    PREREQ_PM        => { 'Mojolicious' => '5.78' },
    META_MERGE       => {
        resources => {
            repository => 'https://github.com/koorchik/Mojolicious-Plugin-RenderFile',
        },
    },
    test             => { TESTS => 't/*.t' },
);
