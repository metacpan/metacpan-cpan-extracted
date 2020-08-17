use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

$::VERSION = '0.0.3';

my %WriteMakefileArgs = (
    NAME             => 'Net::EtcDv2',
    AUTHOR           => q{Gary L. Greene, Jr. <greeneg@tolharadys.net>},
    VERSION_FROM     => 'lib/Net/EtcDv2.pm',
    ABSTRACT_FROM    => 'lib/Net/EtcDv2.pm',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.030',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'boolean'           => 0,
        'Data::Dumper'      => 0,
        'Errno'             => 0,
        'HTTP::Request'     => 0,
        'HTTP::Status'      => 0,
        'JSON'              => 0,
        'LWP::UserAgent'    => 0,
        'strictures'        => 0,
        'Throw'             => 0,
        'Try::Tiny'         => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        no_index => {
            directory => [ 't', 'private' ],
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/greeneg/Net-EtcDv2.git',
                web  => 'https://github.com/greeneg/Net-EtcDv2',
            },
            bugtracker => {web => 'https://github.com/greeneg/Net-EtcDv2/issues'},
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-EtcDv2-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
