use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my %WriteMakefileArgs = (
    NAME             => 'String::Compile::Tr',
    AUTHOR           => q{Jörg Sommrey <git@sommrey.de>},
    VERSION_FROM     => 'lib/String/Compile/Tr.pm',
    ABSTRACT_FROM    => 'lib/String/Compile/Tr.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Config' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Test2::V0' => '0',
        'Scalar::Util' => '0',
    },
    PREREQ_PM => {
        overload => '0',
        Carp => '0',
        'Exporter::Shiny'  => '0',
    },
    clean => {FILES => "String-Compile-Tr-*"},
    test => {TESTS => 't/*.t'},
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/jo-37/String-Compile-Tr.git',
                web => 'https://github.com/jo-37/String-Compile-Tr.git',
            },
        },
    },
);

# Tainted tests
$WriteMakefileArgs{test}{TESTS} .= ' tt/*.t'
    unless $Config{ccflags} =~ /-DNO_TAINT_SUPPORT\b/;

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
