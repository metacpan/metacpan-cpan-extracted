use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

my %WriteMakefileArgs = (
    NAME             => 'Tesla::API',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Tesla/API.pm',
    ABSTRACT_FROM    => 'lib/Tesla/API.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/tesla-api.git',
                web => 'https://github.com/stevieb9/tesla-api',
            },
            bugtracker => {
                web => 'https://github.com/stevieb9/tesla-api/issues',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '0',
        'File::ShareDir::Install' => '0',
    },
    TEST_REQUIRES => {
        'Mock::Sub'  => '1.09',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Digest::SHA'       => 0,
        'File::Copy'        => 0,
        'File::HomeDir'     => 0,
        'File::Share'       => 0,
        'HTTP::Request'     => 0,
        'JSON'              => 0,
        'LWP::Protocol::https' => 0,
        'MIME::Base64'      => '3.16',
        'WWW::Mechanize'    => 0,
        'URI'               => 0,
        'UUID'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tesla-API-*' },
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

package MY;
use File::ShareDir::Install 'postamble';
