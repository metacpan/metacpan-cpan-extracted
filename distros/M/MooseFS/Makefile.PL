use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME             => 'MooseFS',
    AUTHOR           => q{chenryn <rao.chenlin@gmail.com>},
    VERSION_FROM     => 'lib/MooseFS.pm',
    ABSTRACT_FROM    => 'lib/MooseFS.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo' => 0,
        'IO::Socket::INET' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooseFS-*' },
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/chenryn/perl-moosefs',
                },
                no_index => {directory => [qw/t/]},
            },
        )
    ),
);
