use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::CBuilder;
use ExtUtils::Depends;
use File::Find ();
use File::Spec;

# Arena.xs sits at the top of the dist and the build is the plain
# single-extension one MakeMaker defaults to. An XSMULTI build from
# lib/Shared/Arena.xs writes its linker export list to lib/Shared/Arena.def,
# while the import-library rule Strawberry adds for MinGW reads $(EXPORT_LIST),
# which is always $(BASEEXT).def in the top directory - the two names never met
# and dlltool failed the build.

my $LIBS   = '';
my $DEFINE = '';

# ---- Shared::Arena as an ABI PROVIDER ------------------------------------- *
#
# sa_abi.h publishes the region, the ring and the cursor so a consumer's XS can
# use them with no Perl frame at all - which is the point, since a consumer
# paying a method call per record would be slower than the pipe it is replacing.
# ExtUtils::Depends installs the header and records the include path;
# Shared::Arena::_abi_ptr hands over the table's address at runtime.
#
# Provider only: this dist consumes nobody's ABI and has no runtime
# prerequisites.
#
# NO set_inc. What EU::Depends records there is handed to every consumer, and a
# provider's own build-tree paths are meaningless once installed: '-I.' in a
# consumer's compile line means the CONSUMER's directory, and '-Iinclude' means
# a directory that is very likely not there. A consumer needs exactly one path -
# the installed header's - and EU::Depends derives that from CORE by itself.
# ---- and a CONSUMER of Frozen ---------------------------------------------- *
#
# Shared::Arena::Frozen stores a structure that is read WHERE IT LIES rather
# than rebuilt on every read, and Frozen is the format and the reader. Named as
# a dependency here so that EU::Depends puts the installed fz_abi.h on the
# compile line, and so that a consumer of THIS dist inherits the same path.
#
# A hard prerequisite, not an optional one. A tenant that appears or does not
# depending on what else is installed is a tenant whose absence is discovered
# in production, and the arena's own ABI would have to grow a conditional hole.
my $pkg = ExtUtils::Depends->new('Shared::Arena', 'Frozen');
$pkg->install('include/sa_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults, and an INC of its own. This dist sets INC itself below - but the
# dependency's include path is in that INC and is the only way to find
# fz_abi.h, so keep it and merge it rather than dropping it on the floor.
my $dep_inc = $dep{INC} || '';
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# ---- probe: a 64-bit compare-and-swap that LINKS -------------------------- *
#
# The region's high-water mark and the ring's sequence are 64-bit words advanced
# with __sync or __atomic. On a 32-bit x86 target the 64-bit __sync builtins
# need -march=i586 or better, and without it they do not fail to COMPILE - they
# fail to LINK, or worse, resolve to a libgcc call that is not there until
# dlopen. So the probe builds and links a program, and a probe that only
# compiled would pass here and fail in the field.
sub probe {
    my ($name, $body, $libs) = @_;
    my $b   = eval { ExtUtils::CBuilder->new(quiet => 1) } or return 0;
    # NOT "sa_probe_$$_$name.c" - $$_ interpolates as ${$_}, a dereference of
    # $_, and the error it gives names a SCALAR reference rather than the pid
    # you thought you were asking for.
    my $src = File::Spec->catfile(File::Spec->tmpdir(),
                                  'sa_probe_' . $$ . "_$name.c");
    open my $fh, '>', $src or return 0;
    print {$fh} $body;
    close $fh;
    my $ok = eval {
        my $obj = $b->compile(source => $src);
        my ($exe) = $b->link_executable(objects => [$obj],
                                        extra_linker_flags => $libs || '');
        unlink $obj, $exe;
        1;
    };
    unlink $src;
    return $ok ? 1 : 0;
}

my $cas64 = <<'C';
#include <stdint.h>
int main(void) {
    volatile uint64_t v = 1;
#if defined(__has_builtin)
# if __has_builtin(__atomic_compare_exchange_n)
    uint64_t e = 1;
    return __atomic_compare_exchange_n(&v, &e, 2ULL, 0, 5, 2) ? 0 : 1;
# endif
#endif
    return __sync_bool_compare_and_swap(&v, 1ULL, 2ULL) ? 0 : 1;
}
C

if (probe('cas64', $cas64)) {
    print "64-bit atomics: yes.\n";
}
else {
    # Not fatal: every caller fails open with no atomics, and that is a tested
    # path rather than a new one. But say so, because a region that always
    # refuses is a confusing thing to debug from the outside.
    print "64-bit atomics: NO - Shared::Arena will refuse to create a region "
        . "on this build. See the ATOMICS section of the POD.\n";
    $DEFINE .= ' -DSA_NO_ATOMICS';
}

# ---- probe: pthread_atfork ------------------------------------------------ *
#
# The publish path needs to know its own pid, and getpid stopped being cached in
# glibc 2.25 - so caching it here is worth a syscall per record. A cache is only
# safe with something to invalidate it on fork, and pthread_atfork is that.
# glibc moved it from libpthread into libc in 2.34, so try bare first.
#
# Missing is not fatal: without it sa_getpid calls the real thing every time,
# which is what it did before and is always correct.
if ($^O ne 'MSWin32') {
    my $atfork = <<'C';
#include <pthread.h>
static void child(void) { }
int main(void) { return pthread_atfork(0, 0, child); }
C
    if (probe('atfork', $atfork)) {
        $DEFINE .= ' -DSA_HAVE_ATFORK';
        print "pthread_atfork: in libc.\n";
    }
    elsif (probe('atforkp', $atfork, '-lpthread')) {
        $LIBS   .= ' -lpthread';
        $DEFINE .= ' -DSA_HAVE_ATFORK';
        print "pthread_atfork: needs -lpthread: linking it.\n";
    }
    else {
        print "pthread_atfork: NOT FOUND - getpid will not be cached.\n";
    }
}

# ---- probe: shm_open, and whether it needs -lrt --------------------------- *
#
# glibc before 2.34 keeps shm_open in librt; from 2.34 it is folded into libc.
# macOS and the BSDs have no librt at all, so link it only when a probe needs
# it. Windows uses CreateFileMapping and never gets here.
if ($^O ne 'MSWin32') {
    my $shm = <<'C';
#include <sys/mman.h>
#include <fcntl.h>
int main(void) { return shm_open("/sa_probe", O_RDONLY, 0600) < 0 ? 0 : 0; }
C
    if (probe('shm', $shm)) {
        print "shm_open: in libc.\n";
    }
    elsif (probe('shmrt', $shm, '-lrt')) {
        $LIBS .= ' -lrt';
        print "shm_open: needs -lrt (old glibc): linking it.\n";
    }
    else {
        print "shm_open: NOT FOUND - named regions will be unavailable; "
            . "anonymous pre-fork regions still work.\n";
        $DEFINE .= ' -DSA_NO_SHM';
    }
}

# ---- probe: log(), for sizing a bloom filter ------------------------------ *
#
# Sizing a filter from an expected item count and a false-positive rate is two
# logarithms. glibc keeps them in libm; macOS and the BSDs fold them into libc.
# Link it only where a probe says it is needed.
{
    my $logp = <<'C';
#include <math.h>
int main(void) { return (int)(log(2.0) * 0.0); }
C
    if (probe('log', $logp)) {
        print "log(): in libc.\n";
    }
    elsif (probe('logm', $logp, '-lm')) {
        $LIBS .= ' -lm';
        print "log(): needs -lm: linking it.\n";
    }
    else {
        print "log(): NOT FOUND - a bloom filter must be sized in bits "
            . "rather than by item count.\n";
        $DEFINE .= ' -DSA_NO_LIBM';
    }
}

# MakeMaker maps Arena.xs -> Arena.c and rescans neither the INCLUDEd xs/
# fragments nor the C headers, so name both: regenerate Arena.c when a fragment
# changes, and rebuild the object when a header does. The globs run at CONFIGURE
# time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/*.h'), glob('include/sa/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Shared::Arena',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Shared/Arena.pm',
    ABSTRACT_FROM    => 'lib/Shared/Arena.pm',
    LICENSE          => 'artistic_2',
    # 5.010 rather than the skeleton's 5.008003: the layout is uint32_t and
    # uint64_t throughout and <stdint.h> is the floor that buys.
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::CBuilder'  => '0',
        'ExtUtils::Depends'   => '0.404',
        # Read at CONFIGURE time, because EU::Depends resolves the dependency's
        # installed include path while this file runs.
        'Frozen'              => '0.04',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        # The Frozen tenant reads a structure in place through Frozen's ABI
        # table. 0.04 is the version that publishes `borrow`, which is the
        # entry that reads a block without copying it - and copying it is the
        # thing the arena exists to avoid.
        'Frozen' => '0.04',
    },
    XS     => { 'Arena.xs' => 'Arena.c' },
    OBJECT => 'Arena$(OBJ_EXT)',
    INC    => "-I. -Iinclude $dep_inc",
    LIBS   => [$LIBS],
    DEFINE => $DEFINE,
    depend => {
        'Arena.c'         => $xs_deps,
        'Arena$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Shared-Arena-* Install/Files.pm' },
    %dep,
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
