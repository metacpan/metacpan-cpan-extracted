use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use File::Spec ();
use File::Temp ();

# ---- Physics::Balls as an ABI PROVIDER ---------------------------------------
# pb_abi.h publishes the engine: a world from a description, a strike, an
# outcome. It is perl-free, so the same table serves an XS consumer, a C
# program, or a wasm build of pb_engine.c. ExtUtils::Depends installs the header
# and records the include path; Physics::Balls::Engine::_abi_ptr hands the
# table's address over at runtime. No set_inc, for Struct::Codec's reason: what
# is recorded there is handed to every consumer, and a build tree's paths mean
# nothing once installed.
my $pkg = ExtUtils::Depends->new('Physics::Balls');
$pkg->install('include/pb_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM INC)};
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# ---- no fused multiply-add ----------------------------------------------------
# The engine promises the same doubles on every platform, and the fixtures in
# t/ were recorded by the JavaScript it was transliterated from. clang on arm64
# contracts a multiply and an add into one fused instruction by default, which
# rounds once where the JavaScript rounds twice, so the Mac build would differ
# from an x86 server in the last bit. -ffp-contract=off turns that off on gcc
# and clang; MSVC spells it /fp:strict; a compiler that knows neither (gcc
# before 4.6) does not contract on the targets it supports either. The flag is
# probed rather than assumed, because a flag an old compiler rejects fails the
# whole build.
my $contract = '';
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $src = File::Spec->catfile($dir, 'probe.c');
    my $obj = File::Spec->catfile($dir, 'probe.o');
    open my $fh, '>', $src or die "$src: $!";
    print {$fh} "int pb_probe(double a, double b, double c) { return a * b + c > 0; }\n";
    close $fh;
    my $null = File::Spec->devnull;
    if ($Config{cc} =~ /\bcl(?:\.exe)?\z/i) {
        $contract = ' /fp:strict';
    } elsif (system("$Config{cc} -ffp-contract=off -c -o $obj $src >$null 2>&1") == 0) {
        $contract = ' -ffp-contract=off';
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Physics::Balls',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Physics/Balls.pm',
    ABSTRACT_FROM    => 'lib/Physics/Balls.pm',
    LICENSE          => 'artistic_2',
    # 5.010 is the syntactic floor: the defined-or operator appears in the
    # modules and nothing later does. Object::Proto::Sugar, the one runtime
    # dependency, declares 5.008003 and does not raise this.
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'JSON::PP'   => '0',
        # t/11-kinds.t reads the lane fixtures in ulps of a double on a perl
        # whose NV may be wider than one. Test2::Bundle::Numerical 0.03 names
        # Test::Simple but uses Test2::Tools::Basic, which ships in
        # Test2::Suite: core only since 5.39.4, so it is named here too.
        'Test2::Bundle::Numerical' => '0.03',
        'Test2::Suite'             => '0.000060',
    },
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    XS     => { 'Balls.xs' => 'Balls.c' },
    C      => [ 'Balls.c', 'pb_engine.c' ],
    OBJECT => 'Balls$(OBJ_EXT) pb_engine$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    CCFLAGS => "$Config{ccflags}$contract",
    # MakeMaker rescans no header: name it, so the objects rebuild when it moves.
    depend => {
        'Balls$(OBJ_EXT)'     => 'include/pb_abi.h',
        'pb_engine$(OBJ_EXT)' => 'include/pb_abi.h',
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Physics-Balls-* Install' },
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
