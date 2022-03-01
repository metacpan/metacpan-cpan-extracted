use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

my %WriteMakefileArgs = (
    NAME             => 'Parser::FIT',
    AUTHOR           => q{Sven Eppler <ghandi@cpan.org>},
    VERSION_FROM     => 'lib/Parser/FIT.pm',
    ABSTRACT_FROM    => 'lib/Parser/FIT.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010001',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:ghandmann/parser-fit.git',
                web => 'https://github.com/ghandmann/parser-fit',
            },
            bugtracker => {
                web => 'https://github.com/ghandmann/parser-fit/issues',
            }
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Parser-FIT-*' },
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
