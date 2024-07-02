use 5.006;
use strict;
use warnings;

#use ExtUtils::MakeMaker 7.12; # for XSMULTI option
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'String::Random::Regexp::regxstring',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/String/Random/Regexp/regxstring.pm',
    ABSTRACT_FROM    => 'lib/String/Random/Regexp/regxstring.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0', # 7.12
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
    },
    PREREQ_PM => {
    },

    # you gotta love ExtUtils::MakeMaker this is so convenient!
    OBJECT => '$(O_FILES)',
    LIBS => '',
    CCFLAGS => '',
    LDFLAGS => '',
    XSOPT   => '-C++',
    # ideally we should not be specifying here the compiler executable
    # because it reduces compatibility.
    # XSOPT knows that this is C++ code I guess.
    CC      => 'c++', # g++
    LD      => 'c++', # g++
    #XSMULTI => 1, # many XS modules with different names, requires EUMM >= 7.12

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'String-Random-Regexp-regxstring-*' },
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
