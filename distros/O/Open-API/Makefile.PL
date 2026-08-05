use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my $DEP_INC;
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Open::API',
                   'JSON::Schema::Fast', 'Fetch', 'File::Raw::JSON'); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        $DEP_INC = $v{INC} || '';
    } else {
        die "Open::API needs JSON::Schema::Fast, Fetch and File::Raw::JSON "
          . "installed,\nor present as sibling directories.\n"
            unless -d '../JSON-Schema-Fast/include'
                && -d '../Fetch/include/fetch'
                && -d '../File-Raw-JSON/include';
        $DEP_INC = '-I../JSON-Schema-Fast/include -I../Fetch/include/fetch '
                 . '-I../File-Raw-JSON/include';
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Open::API',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Open/API.pm',
    ABSTRACT_FROM    => 'lib/Open/API.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'JSON::Schema::Fast'  => '0.05',   # provides jsf_abi.h
        'Fetch'               => '0.08',   # provides fetch_abi.h
        'File::Raw::JSON'     => '0.05',   # provides frj_abi.h
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'JSON::Schema::Fast' => '0.05',   # schema validation C ABI (jsf_abi.h)
        'File::Raw::JSON'    => '0.05',   # spec + body JSON decode C ABI (frj_abi.h)
    },
    INC   => "-Iinclude $DEP_INC",
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Open-API-*' },
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
