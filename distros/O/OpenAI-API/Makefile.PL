use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'OpenAI::API',
    AUTHOR             => q{Nelson Ferraz <nferraz@gmail.com>},
    VERSION_FROM       => 'lib/OpenAI/API.pm',
    ABSTRACT_FROM      => 'lib/OpenAI/API.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => '5.010',
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
        'IO::Async'            => '0.802',
        'JSON::MaybeXS'        => '1.004002',
        'LWP::UserAgent'       => '6.47',
        'LWP::Protocol::https' => '6.10',
        'Moo'                  => '2.005005',
        'namespace::clean'     => '0.27',
        'strictures'           => '2.000006',
        'Throwable'            => '1.001',
        'Types::Standard'      => '2.002001',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/nferraz/perl-openai-api.git',
                web  => 'https://github.com/nferraz/perl-openai-api',
            },
            bugtracker => {
                web => 'https://github.com/nferraz/perl-openai-api/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'OpenAI-API-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
