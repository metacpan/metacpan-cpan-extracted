use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MojoX::Renderer::Handlebars',
    AUTHOR           => q{Robert Grimes <rmzgrimes@gmail.com>},
    VERSION_FROM     => 'lib/MojoX/Renderer/Handlebars.pm',
    ABSTRACT_FROM    => 'lib/MojoX/Renderer/Handlebars.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
				'Text::Handlebars' => 0.04,
				'Mojolicious'      => 5.81,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MojoX-Renderer-Handlebars-*' },
);
