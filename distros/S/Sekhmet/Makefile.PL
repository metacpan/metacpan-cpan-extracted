use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Resolve Horus include path at build time:
#   1. Try installed Horus module (CPAN / system)
#   2. Fall back to sibling directory (development)
my $horus_inc;
eval {
    require Horus;
    my $dir = Horus::include_dir();
    $horus_inc = $dir if $dir && -d $dir;
};
if (!$horus_inc && -d '../Horus/include') {
    $horus_inc = '../Horus/include';
}
die "Sekhmet requires Horus (for C headers). Install Horus or place it as a sibling directory.\n"
    unless $horus_inc;

my %WriteMakefileArgs = (
    NAME             => 'Sekhmet',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Sekhmet.pm',
    ABSTRACT_FROM    => 'lib/Sekhmet.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Horus'               => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Horus' => '0.02',
    },
    INC    => "-I. -Iinclude -I$horus_inc",
    OBJECT => '$(O_FILES)',
    PM     => {
        'lib/Sekhmet.pm'           => '$(INST_LIB)/Sekhmet.pm',
        'include/sekhmet.h'        => '$(INST_LIB)/Sekhmet/include/sekhmet.h',
        'include/sekhmet_core.h'   => '$(INST_LIB)/Sekhmet/include/sekhmet_core.h',
        'include/sekhmet_ulid.h'   => '$(INST_LIB)/Sekhmet/include/sekhmet_ulid.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sekhmet-*' },
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
