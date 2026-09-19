use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# ---- Physics::Terrain as an ABI PROVIDER -------------------------------------
# pt_abi.h publishes the engine: a field from a seed, bodies, a turn, an
# outcome. It is perl-free, so the same table serves an XS consumer, a C
# program, or a wasm build of pt_engine.c. ExtUtils::Depends installs the
# header and records the include path; Physics::Terrain::_abi_ptr hands the
# table's address over at runtime. No set_inc, for Struct::Codec's reason:
# what is recorded there is handed to every consumer, and a build tree's
# paths mean nothing once installed.
my $pkg = ExtUtils::Depends->new('Physics::Terrain');
$pkg->install('include/pt_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM INC)};
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my %WriteMakefileArgs = (
    NAME             => 'Physics::Terrain',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Physics/Terrain.pm',
    ABSTRACT_FROM    => 'lib/Physics/Terrain.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.88',
        'JSON::PP'    => '0',
        'Digest::SHA' => '0',
    },
    PREREQ_PM => {},
    XS     => { 'Terrain.xs' => 'Terrain.c' },
    C      => [ 'Terrain.c', 'pt_engine.c' ],
    OBJECT => 'Terrain$(OBJ_EXT) pt_engine$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    # MakeMaker rescans no header: name them, so the objects rebuild when one moves.
    depend => {
        'Terrain$(OBJ_EXT)'   => 'include/pt_abi.h',
        'pt_engine$(OBJ_EXT)' => 'include/pt_abi.h pt_sine.h',
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Physics-Terrain-* Install' },
    %dep,
);

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
