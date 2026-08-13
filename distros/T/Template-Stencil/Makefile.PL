use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use Config;

# Template::Stencil is a provider: it installs st_abi.h so a dependent (Punk's
# view tier) can render through the engine in C, resolving the table at runtime
# from Template::Stencil::_abi_ptr. It consumes nothing itself.
my $pkg = ExtUtils::Depends->new('Template::Stencil');
$pkg->install('include/st_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
# EU::Depends returns an empty LIBS/LDFROM that would otherwise clobber
# MakeMaker's defaults, and an OBJECT that would drop the src/ objects; this
# module links nothing extra and builds its own object list below.
delete @dep{qw(LIBS LDFROM OBJECT INC)};
# Its PM map (installing st_abi.h + Files.pm) replaces MakeMaker's
# auto-detected one, so re-add everything shipped under lib/.
File::Find::find(sub {
    return unless -f;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# --- capability probes ---------------------------------------------------
#
# Each probe compiles a tiny C file with the toolchain that will build the
# module; success appends a -D define. Every probe fails soft: a missing
# capability means the SWAR/switch fallback path, never a build failure.
# The SIMD probes use __attribute__((target(...))) so the variants can be
# compiled per-function without raising the baseline -m flags for the whole
# object (which would crash older CPUs); runtime dispatch in stencil_boot.c
# picks a variant only when the CPU actually supports it.

sub try_compile {
    my ($code, $flags, $link) = @_;
    $flags = '' unless defined $flags;
    my $dir = "ts_probe_$$";
    mkdir $dir or return 0;
    my ($src, $out, $ok) = ("$dir/probe.c", "$dir/probe.out", 0);
    if (open my $fh, '>', $src) {
        print $fh $code;
        close $fh;
        my $cc  = $Config{cc} || 'cc';
        my $c   = $link ? '' : '-c';
        # cmd.exe has no /dev/null and no 2>&1-after-redirect ordering
        # quirks worth fighting; NUL does the same job there.
        my $null = $^O eq 'MSWin32' ? 'NUL' : '/dev/null';
        $ok = system("$cc $flags $c $src -o $out >$null 2>&1") == 0;
    }
    unlink $src, $out;
    rmdir $dir;
    return $ok;
}

# Keep XSUB.h from rewriting malloc/free/stat/open/read/close into the
# per-interpreter PERL_IMPLICIT_SYS vtable (threaded Windows perls). The C
# core has no pTHX in scope and owns its own memory; see include/stencil.h.
my @defines = ('-DNO_XSLOCKS');

push @defines, '-DSTENCIL_HAVE_COMPUTED_GOTO' if try_compile(<<'C');
int main(void) { static void *t[] = { &&a }; goto *t[0]; a: return 0; }
C

push @defines, '-DSTENCIL_HAVE_BUILTIN_EXPECT' if try_compile(<<'C');
int main(void) { return __builtin_expect(0, 0); }
C

# No archname sniffing - the compile probe itself is the truth (Apple
# Silicon perls report archnames like darwin-2level with no arm64 in them).
# Wrong-architecture probes simply fail to compile and skip the define.
push @defines, '-DSTENCIL_HAVE_SSE2' if try_compile(<<'C');
#include <emmintrin.h>
int main(void) { __m128i v = _mm_set1_epi8(1); return _mm_movemask_epi8(v) & 1; }
C
push @defines, '-DSTENCIL_HAVE_SSE42' if try_compile(<<'C');
#include <nmmintrin.h>
__attribute__((target("sse4.2")))
int probe(void) { return (int)_mm_crc32_u8(0, 1); }
int main(void) { return 0; }
C
push @defines, '-DSTENCIL_HAVE_AVX2' if try_compile(<<'C');
#include <immintrin.h>
__attribute__((target("avx2")))
int probe(void) { __m256i v = _mm256_set1_epi8(1); return _mm256_movemask_epi8(v) & 1; }
int main(void) { return 0; }
C
push @defines, '-DSTENCIL_HAVE_NEON' if try_compile(<<'C');
#include <arm_neon.h>
int main(void) { uint8x16_t v = vdupq_n_u8(1); return vgetq_lane_u8(v, 0); }
C

# --- optimisation flags: probe and append --------------------------------
#
# Start from the perl that will load us, then push harder flags the compiler
# demonstrably accepts. -flto is appended (to compile and link both) only
# when a full compile+link probe passes - some toolchains accept it at
# compile time then fail at link.

my $trivial  = "int main(void) { return 0; }\n";
my $optimize = $Config{optimize} || '-O2';
my $ldflags  = '';

for my $flag ('-O3', '-fomit-frame-pointer') {
    if (try_compile($trivial, "$optimize $flag")) {
        $optimize =~ s/(?:^|\s)-O[0-9s]\b//g if $flag eq '-O3';
        $optimize = join ' ', grep { length } $optimize, $flag;
    }
}
if (try_compile($trivial, "$optimize -flto", 1)) {
    $optimize .= ' -flto';
    $ldflags   = '-flto';
}

print "OPTIMIZE: $optimize\n";
print "DEFINE:   @defines\n" if @defines;

my %WriteMakefileArgs = (
    NAME             => 'Template::Stencil',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Template/Stencil.pm',
    ABSTRACT_FROM    => 'lib/Template/Stencil.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010001',
    OBJECT           => join(' ', 'Stencil$(OBJ_EXT)',
                             map { (my $o = $_) =~ s/\.c$/\$(OBJ_EXT)/; $o }
                                 sort glob 'src/*.c'),
    # '-I.' so include/stencil.h finds ppport.h at the dist root; the
    # compile runs from the root but '.' is not on the quote-include path.
    INC              => '-I. -Iinclude',
    OPTIMIZE         => $optimize,
    DEFINE           => join(' ', @defines),
    ($ldflags ? (dynamic_lib => { OTHERLDFLAGS => $ldflags }) : ()),
    depend           => {
        'Stencil$(OBJ_EXT)' => join(' ', 'ppport.h', sort glob 'include/*.h'),
    },
    %dep,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Template-Stencil-* src/*$(OBJ_EXT)' },
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

# MakeMaker's generated compile rule drops subdirectory objects into the
# top directory; give every src/ object an explicit rule so the .o lands
# where the link step expects it. Generated from the glob so new phases
# get their rules for free.
sub MY::postamble {
    my $headers = join ' ', 'ppport.h',
                            sort(glob('include/*.h'), glob('src/*.inc'));
    my $mk = '';
    for my $c (sort glob 'src/*.c') {
        (my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/;
        $mk .= "$o: $c $headers\n"
             . "\t\$(CCCMD) \$(CCCDLFLAGS) \"-I\$(PERL_INC)\" "
             . "\$(PASTHRU_DEFINE) \$(DEFINE) $c -o \$@\n\n";
    }
    return $mk;
}
