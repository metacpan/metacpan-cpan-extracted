use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Slug',
    AUTHOR           => 'lnation <email@lnation.org>',
    VERSION_FROM     => 'lib/Slug.pm',
    ABSTRACT_FROM    => 'lib/Slug.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Slug-*' },
    INC    => '-I. -Iinclude',
    OBJECT => '$(O_FILES)',
    PM     => {
        'lib/Slug.pm'                => '$(INST_LIB)/Slug.pm',
        'include/slug.h'             => '$(INST_LIB)/Slug/include/slug.h',
        'include/slug_core.h'        => '$(INST_LIB)/Slug/include/slug_core.h',
        'include/slug_utf8.h'        => '$(INST_LIB)/Slug/include/slug_utf8.h',
        'include/slug_unicode.h'     => '$(INST_LIB)/Slug/include/slug_unicode.h',
        'include/slug_transform.h'   => '$(INST_LIB)/Slug/include/slug_transform.h',
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

WriteMakefile(%WriteMakefileArgs);
