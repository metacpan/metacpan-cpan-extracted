use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Term::SimpleColor',
    AUTHOR              => 'Takashi Uesugi <tksuesg@gmail.com>',
    VERSION_FROM        => 'lib/Term/SimpleColor.pm',
    ABSTRACT_FROM       => 'lib/Term/SimpleColor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'strict'              => 0,
        'warnings'            => 0,
        'utf8'                => 0,
        'Carp'                => 0,
        'base'                => 0,
        'Test::More'          => 0,
        'Test::Perl::Critic'  => 0,
        'Test::Pod'           => 1.14,
        'Test::Pod::Coverage' => 1.04,
        'version'             => 0,
      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Term-SimpleColor-*' },
);
