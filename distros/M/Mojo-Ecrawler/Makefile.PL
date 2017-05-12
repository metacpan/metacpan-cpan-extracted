use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Ecrawler',
    AUTHOR           => q{ORANGE <bollwarm@ijz.me>},
    VERSION_FROM     => 'lib/Mojo/Ecrawler.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Ecrawler.pm',
    LICENSE          => 'Perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    		"Mojolicious"   => '6.11',

    },
           META_MERGE => {
          'meta-spec' => { version => 2 },
           resources   => {
            repository => {
                type => 'git',
                url  => 'https://git.oschina.net/ijz/Mojo-Zabbix',
                web  => 'http://ijz.me',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Ecrawler-*' },
);
