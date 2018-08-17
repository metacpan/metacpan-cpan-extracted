use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Sub::Params',
    AUTHOR           => q{Branislav Zahradnik <branislav.zahradnik@gooddata.com>},
    VERSION_FROM     => 'lib/Sub/Params.pm',
    ABSTRACT_FROM    => 'lib/Sub/Params.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Test::Deep' => '0',
        'Test::Warnings' => '0',
    },
    PREREQ_PM => {
        'Ref::Util' => '0',
        'Hash::Util' => '0',
        'Exporter' => '0',
    },
    macro => { TARFLAGS => '--format=ustar -cvf' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sub-Params-*' },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        'resources' => {
            bugtracker => {
                web  => 'https://github.com/gooddata/perl-sub-params/issues',
            },
            repository => {
                url  => 'git://github.com/gooddata/perl-sub-params.git',
                web  => 'https://github.com/gooddata/perl-sub-params',
                type => 'git',
            },
        },
	'dynamic_config' => 0,
    },
);
