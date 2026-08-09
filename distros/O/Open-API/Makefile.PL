use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Open::API is BOTH a consumer (of JSON::Schema::Fast's jsf_abi, Fetch's
# fetch_abi and File::Raw::JSON's frj_abi, all resolved in C) and a provider
# (it installs oa_abi.h so a dependent like Punk reaches Open::API's own route
# + validate ABI without vendoring a copy).
my $INC = '-Iinclude';
my $pkg;
eval { $pkg = ExtUtils::Depends->new('Open::API',
           'JSON::Schema::Fast', 'Fetch', 'File::Raw::JSON'); 1 };
if (!$pkg) {
    die "Open::API needs JSON::Schema::Fast, Fetch and File::Raw::JSON "
      . "installed,\nor present as sibling directories.\n"
        unless -d '../JSON-Schema-Fast/include'
            && -d '../Fetch/include/fetch'
            && -d '../File-Raw-JSON/include';
    $pkg = ExtUtils::Depends->new('Open::API');        # provider only
    $INC .= ' -I../JSON-Schema-Fast/include -I../Fetch/include/fetch '
          . '-I../File-Raw-JSON/include';
}
$pkg->install('include/oa_abi.h');                     # provide oa_abi.h
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
$INC .= ' ' . delete $dep{INC} if $dep{INC};           # merge consumer inc
# EU::Depends returns an empty LIBS/LDFROM that would otherwise clobber
# MakeMaker's defaults; Open::API links nothing extra, so drop them.
delete $dep{LIBS};
delete $dep{LDFROM};

# EU::Depends' PM map (installing oa_abi.h + Files.pm) replaces MakeMaker's
# auto-detected PM, so re-add everything the module ships under lib/ - not just
# .pm, but the Open::API::UI static assets and Stencil templates too.
File::Find::find(sub {
    return unless -f;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

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
    INC   => $INC,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                # Only the docs UI (Open::API::UI) needs these, and it
                # names the same minimums itself with `use MODULE VERSION`
                # - a recommendation is not installed on every machine and
                # cannot upgrade one that already has an older copy, so it
                # is a hint to the client, not a guarantee to the code.
                # Markdown::Simple 0.18 is where its OO interface arrives.
                # The UI also wants perl 5.010 (defined-or), above this
                # distribution's own 5.008003 floor; its tests skip below
                # that rather than the whole distribution moving up for an
                # optional feature.
                recommends => {
                    'Template::Stencil' => '0.02',
                    'Markdown::Simple'  => '0.18',
                },
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Open-API-* Install/Files.pm' },
    # MakeMaker does not scan XS #includes; rebuild the object when any
    # vendored header changes so edits to include/*.h always take effect.
    depend => {
        'API$(OBJ_EXT)' => join(' ', glob('include/*.h')),
    },
    %dep,   # ExtUtils::Depends: TYPEMAPS + PM (installs oa_abi.h + our .pm)
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
