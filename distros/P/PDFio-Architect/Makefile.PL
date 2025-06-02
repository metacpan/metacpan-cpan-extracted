use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper;

my %WriteMakefileArgs = (
    NAME             => 'PDFio::Architect',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/PDFio/Architect.pm',
    ABSTRACT_FROM    => 'lib/PDFio/Architect.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    XSMULTI => 1,
    INC => "-Iinc",
    MYEXTLIB => 'inc/architect$(OBJ_EXT)',    
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
	'Alien::Base::Wrapper' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
	'Alien::PDFio' => '0.05',
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDFio-Architect-* inc/*$(OBJ_EXT)' },
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

WriteMakefile(Alien::Base::Wrapper->new('Alien::PDFio')->mm_args2( %WriteMakefileArgs ));
