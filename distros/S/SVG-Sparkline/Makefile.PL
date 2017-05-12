use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVG::Sparkline',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/SVG/Sparkline.pm',
    ABSTRACT_FROM       => 'lib/SVG/Sparkline.pm',
    LICENSE             => 'perl',
    EXE_FILES           => ['bin/sparkline.pl', 'bin/sparkline.cgi'],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Carp'       => 0,
        'SVG'        => 2.50,
        'Getopt::Long' => 0,
        'Pod::Usage'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVG-Sparkline-*' },
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/svg-sparkline.git',
                web  => 'https://github.com/gwadej/svg-sparkline',
            },
        },
    },
    MIN_PERL_VERSION   => 5.008,
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);
