use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Codec.xs sits at the top of the dist and the build is the plain
# single-extension one MakeMaker defaults to. An XSMULTI build from
# lib/Struct/Codec.xs writes its linker export list to lib/Struct/Codec.def,
# while the import-library rule Strawberry adds for MinGW reads $(EXPORT_LIST),
# which is always $(BASEEXT).def in the top directory - the two names never meet
# and dlltool fails the build.

# ---- Struct::Codec as an ABI PROVIDER ------------------------------------- *
# sc_abi.h publishes the codec so a consumer's XS can encode a value straight
# into memory it owns and decode one straight out of it, with no Perl frame in
# between - which is the whole point, since on a small value the frame and the
# intermediate string are most of the cost. ExtUtils::Depends installs the
# header and records the include path; Struct::Codec::_abi_ptr hands over the
# table's address at runtime.
#
# Provider only: this dist consumes nobody's ABI and has no runtime
# prerequisites.
#
# NO set_inc. What EU::Depends records there is handed to every consumer, and
# a provider's own build-tree paths are meaningless once installed: '-I.' in a
# consumer's compile line means the CONSUMER's directory, and '-Iinclude'
# means a directory that is very likely not there. A consumer needs exactly
# one path - the installed header's - and EU::Depends derives that from CORE
# by itself.
my $pkg = ExtUtils::Depends->new('Struct::Codec');
$pkg->install('include/sc_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults, and an INC of its own. INC is set below and nothing extra is linked.
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker maps Codec.xs -> Codec.c and rescans neither the INCLUDEd xs/
# fragments nor the C headers, so name both: regenerate Codec.c when a fragment
# changes, and rebuild the object when a header does. The globs run at
# CONFIGURE time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/sc_abi.h', glob('include/sc/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Struct::Codec',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Struct/Codec.pm',
    ABSTRACT_FROM    => 'lib/Struct/Codec.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {},
    XS     => { 'Codec.xs' => 'Codec.c' },
    OBJECT => 'Codec$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    depend => {
        'Codec.c'         => $xs_deps,
        'Codec$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Struct-Codec-* Install/Files.pm' },
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
