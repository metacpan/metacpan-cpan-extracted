use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Store.xs sits at the top of the dist and the build is the plain
# single-extension one, for the reason HAMT's Makefile.PL gives: an XSMULTI
# build writes its export list where Strawberry's import-library rule does
# not look.

# ---- State::Store as a CONSUMER of HAMT's C ABI ------------------------- *
# The history is two HAMT vectors and the checkpoints a HAMT map, reached
# through hamt_abi.h with no Perl call. ExtUtils::Depends finds that header
# where HAMT installed it; HAMT::_abi_ptr hands over the table when this
# loads. Nothing is linked against HAMT.
#
# HAMT must be installed, or in @INC, before this file can run: that is what
# CONFIGURE_REQUIRES says below, and a missing one stops here by name.
my $pkg = eval { ExtUtils::Depends->new('State::Store', 'HAMT') };
unless ($pkg) {
    warn "State::Store needs HAMT to be installed before it is configured:\n$@";
    exit 0;
}

# ---- State::Store as an ABI PROVIDER ------------------------------------ *
# state_store_abi.h publishes the store to other extensions' C, resolved at
# run time through State::Store::_abi_ptr. ExtUtils::Depends installs the
# header and records where it went. NO set_inc, for the reason HAMT's
# Makefile.PL gives: a provider's build-tree paths mean nothing to a
# consumer once installed.
$pkg->install('include/state_store_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults. Its INC is the one thing wanted: where hamt_abi.h is.
delete @dep{qw(LIBS LDFROM)};
my $hamt_inc = delete $dep{INC} // '';

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker maps Store.xs -> Store.c and rescans neither the INCLUDEd xs/
# fragments nor the C headers, so name both. The globs run at CONFIGURE
# time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/state_store_abi.h', glob('include/store/*.h');

my %WriteMakefileArgs = (
    NAME             => 'State::Store',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/State/Store.pm',
    ABSTRACT_FROM    => 'lib/State/Store.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'HAMT'                => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'HAMT' => '0.02',
    },
    XS     => { 'Store.xs' => 'Store.c' },
    OBJECT => 'Store$(OBJ_EXT)',
    INC    => "-I. -Iinclude $hamt_inc",
    depend => {
        'Store.c'         => $xs_deps,
        'Store$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'State-Store-* Install/Files.pm' },
    %dep,
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
