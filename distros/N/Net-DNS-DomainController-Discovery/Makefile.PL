use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Net::DNS::DomainController::Discovery',
    AUTHOR           => q{Marcin CIESLAK <saperski@cpan.org>},
    VERSION_FROM     => 'lib/Net/DNS/DomainController/Discovery.pm',
    ABSTRACT_FROM    => 'lib/Net/DNS/DomainController/Discovery.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Test2::V0' => '0',
        'ExtUtils::Manifest' => '0',
        'Net::DNS::Resolver::Mock' => '1.20171219',
    },
    PREREQ_PM => {
        'Net::DNS' => '1.21',
        'Exporter' => '5.57',
    },
    META_MERGE => {
        resources => {
            license     => 'https://dev.perl.org/licenses/artistic.html',
            homepage    => 'https://metacpan.org/release/Net-DNS-DomainController-Discovery',
            bugtracker  => {
                'url'  => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DNS-DomainController-Discovery',
            },
            repository  => {
                'url'  => 'http://repo.or.cz/Net-DNS-DomainController-Discovery',
                'type' => 'git',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-DNS-DomainController-Discovery-*' },
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
