use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Netflow::Parser',
    AUTHOR             => q{Alexei Pastuchov E<lt>palik at cpan dot orgE<gt>.},
    VERSION_FROM       => 'lib/Netflow/Parser.pm',
    ABSTRACT           => 'Netflow parser (V9 only)',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => '5.008',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.48', },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/p-alik/Netflow-Parser',
            repository => {
                type => 'git',
                web  => 'https://github.com/p-alik/Netflow-Parser',
                url  => 'git@github.com:p-alik/Netflow-Parser.git',
            },
            bugtracker => {
                web => 'https://github.com/p-alik/Netflow-Parser/issues',
            },
        },
    },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        'fields' => 0,
        'Carp'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Netflow-Parser-*' },
);
