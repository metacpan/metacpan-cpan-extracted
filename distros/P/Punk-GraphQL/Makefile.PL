use 5.024000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Punk::GraphQL',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Punk/GraphQL.pm',
    ABSTRACT_FROM    => 'lib/Punk/GraphQL.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.024000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
        # this dist IS the glue between the two, so both are hard requires
        'Punk'            => '0.04',   # install_kw arrived in 0.04
        'GraphQL::Houtou' => '0.05',
        'File::Raw::JSON' => '0.05',   # error envelopes; Punk requires it too
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            test => { recommends => { 'Hyperman' => '0.14' } },
        },
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Punk-GraphQL-*' },
);
