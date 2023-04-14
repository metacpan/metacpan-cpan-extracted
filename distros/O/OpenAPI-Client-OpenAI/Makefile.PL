use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

# install configuration files from 'share' directory
install_share 'share';

my %WriteMakefileArgs = (
    NAME             => 'OpenAPI::Client::OpenAI',
    AUTHOR           => q{Nelson Ferraz <nferraz@gmail.com>},
    VERSION_FROM     => 'lib/OpenAPI/Client/OpenAI.pm',
    ABSTRACT_FROM    => 'lib/OpenAPI/Client/OpenAI.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker'     => '0',
        'File::ShareDir::Install' => '0',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'             => '0',
        'Test::Deep'             => '0',
        'Test::Exception'        => '0',
        'Test::RequiresInternet' => '0',
    },
    PREREQ_PM => {
        'File::ShareDir'        => '0',
        'File::Spec::Functions' => '0',
        'OpenAPI::Client'       => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'OpenAPI-Client-OpenAI-*' },
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

# install configuration files from 'share' directory

package MY;
use File::ShareDir::Install qw( postamble );
