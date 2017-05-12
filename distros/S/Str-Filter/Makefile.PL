use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.63;

my %WriteMakefileArgs = (
    NAME                  => 'Str::Filter',
    AUTHOR                => 'Trevor S. Cornpropst <tscornpropst@gmail.com>',
    VERSION_FROM          => 'lib/Str/Filter.pm',
    ABSTRACT_FROM         => 'lib/Str/Filter.pm',
    LICENSE               => 'artistic_2',
    DISTNAME              => 'Str-Filter',
    MIN_PERL_VERSION      => 5.006,
    BUILD_REQUIRES        => {
        'ExtUtils::MakeMaker' => 6.63,
    },
    CONFIGURE_REQUIRES    => {
        'ExtUtils::MakeMaker' => 6.63,
    },
    PREREQ_PM             => {
        'HTML::Strip'     => 0,
    },
    TEST_REQUIRES         => {
        'Test::More'      => 0,
    },
    test                  => { "TESTS" => "t/*.t", },
    dist                  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

my %FallbackPrereqs = (
    'HTML::Strip'         => 0,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
