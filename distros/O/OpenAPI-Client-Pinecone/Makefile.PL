use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

# install configuration files from 'share' directory
install_share 'share';

my %WriteMakefileArgs = (
    NAME             => 'OpenAPI::Client::Pinecone',
    AUTHOR           => q{Nelson Ferraz <nferraz@gmail.com>},
    VERSION_FROM     => 'lib/OpenAPI/Client/Pinecone.pm',
    ABSTRACT_FROM    => 'lib/OpenAPI/Client/Pinecone.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '0',
        'File::ShareDir::Install' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::ShareDir'        => '0',
        'File::Spec::Functions' => '0',
        'OpenAPI::Client'       => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/nferraz/perl-openapi-client-pinecone.git',
                web  => 'https://github.com/nferraz/perl-openapi-client-pinecone',
            },
            bugtracker => {
                web => 'https://github.com/nferraz/perl-openapi-client-pinecone/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'OpenAPI-Client-Pinecone-*' },
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
