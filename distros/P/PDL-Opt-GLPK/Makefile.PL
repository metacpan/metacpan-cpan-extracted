use 5.006;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Devel::CheckLib qw(assert_lib);

my @pack = (["glpk.pd",'GLPK','PDL::Opt::GLPK']);

assert_lib(lib => 'glpk', header => 'glpk.h');

my %WriteMakefileArgs = (
    pdlpp_stdargs(@pack),
    AUTHOR           => q{Jörg Sommrey <git@sommrey.de>},
    ABSTRACT_FROM    => 'lib/PDL/Opt/GLPK.pod',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'PDL::Core::Dev' => '0',
        'Devel::CheckLib' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
        'Test::More' => 0
    },
    PREREQ_PM => {
        'PDL'              => '2.085',
    },
    C => ['GLPK.c', 'glpk_aio.c'],
    OBJECT => '$(O_FILES)',
    LIBS => [' -lm -lglpk '],
    PM => {
        "lib/PDL/Opt/GLPK.pod" => '$(INST_LIBDIR)/GLPK.pod',
        "GLPK.pm" => '$(INST_LIBDIR)/GLPK.pm',
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/jo-37/pdl-opt-glpk/issues',
            },
            repository => {
                type => 'git',
                url => 'git://github.com/jo-37/pdl-opt-glpk.git',
                web => 'https://github.com/jo-37/pdl-opt-glpk.git',
            },
        },
    },
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

$WriteMakefileArgs{CCFLAGS} = "$Config::Config{ccflags} -std=c99"
    if $Config::Config{ccname} eq "gcc";

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    pdlpp_postamble(@pack);
}
