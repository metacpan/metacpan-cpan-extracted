use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::HTMLLint',
    VERSION_FROM => 'lib/Mojolicious/Plugin/HTMLLint.pm',
    AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM    => {
        'Mojolicious' => '2.88',
        'HTML::Lint'  => '2.26'
    },
    META_MERGE   => {
        resources => {
            repository => 'https://github.com/koorchik/Mojolicious-Plugin-HTMLLint',
        },
    },
    test => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    MIN_PERL_VERSION => v5.10,
    LICENSE => 'perl_5',
    clean => { FILES => 'Mojolicious-Plugin-HTMLLint-*' },
);
