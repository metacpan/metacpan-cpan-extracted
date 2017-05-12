use 5.14.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Term::ANSITable',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Term/ANSITable.pm',
    ABSTRACT_FROM      => '',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.14.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Test::More'      => 0,
        'Term::Cap'       => 0,
        'Term::Size'      => 0,
        'Text::ANSITable' => 0,

    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mziescha/Term-ANSITable.git',
                web  => 'https://github.com/mziescha/Term-ANSITable',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Term-ANSITable-*' },
);
