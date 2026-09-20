use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::CBuilder;
use ExtUtils::Depends;
use File::Find ();
use File::Spec;

my $LIBS   = '';
my $DEFINE = '';

my $pkg = ExtUtils::Depends->new('Shared::Arena', 'Frozen', 'Struct::Codec');
$pkg->install('include/sa_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
my $dep_inc = $dep{INC} || '';
delete @dep{qw(LIBS LDFROM INC)};

File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# Compile and link a probe, and with `run` set, RUN it and require exit 0.
# Linking proves a symbol exists; only running proves it does what its name
# says. FreeBSD's libc exports a pthread_atfork that links cleanly and does
# nothing at all unless libthr is loaded, and a perl built without -lpthread
# does not load it: the fork handler never ran, every child kept its parent's
# cached pid, and six test files failed at once on the 5.14 and 5.16 smokers.
sub probe {
    my ($name, $body, $libs, $run) = @_;
    my $b   = eval { ExtUtils::CBuilder->new(quiet => 1) } or return 0;
    my $src = File::Spec->catfile(File::Spec->tmpdir(),
                                  'sa_probe_' . $$ . "_$name.c");
    open my $fh, '>', $src or return 0;
    print {$fh} $body;
    close $fh;
    my $ok = eval {
        my $obj = $b->compile(source => $src);
        my ($exe) = $b->link_executable(objects => [$obj],
                                        extra_linker_flags => $libs || '');
        my $rc = $run ? system($exe) : 0;
        unlink $obj, $exe;
        $rc == 0;
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
    print "64-bit atomics: NO - Shared::Arena will refuse to create a region "
        . "on this build. See the ATOMICS section of the POD.\n";
    $DEFINE .= ' -DSA_NO_ATOMICS';
}

if ($^O ne 'MSWin32') {
    # Registers a child handler, forks, and exits 0 only if the CHILD saw it
    # run. A stub that links and never fires fails this and not the link.
    my $atfork = <<'C';
#include <pthread.h>
#include <unistd.h>
#include <sys/wait.h>
static volatile int ran = 0;
static void child(void) { ran = 1; }
int main(void) {
    pid_t p;
    int st = 0;
    if (pthread_atfork(0, 0, child) != 0) return 1;
    p = fork();
    if (p < 0) return 1;
    if (p == 0) _exit(ran ? 0 : 2);
    if (waitpid(p, &st, 0) != p) return 1;
    return (WIFEXITED(st) && WEXITSTATUS(st) == 0) ? 0 : 3;
}
C
    if (probe('atfork', $atfork, '', 1)) {
        $DEFINE .= ' -DSA_HAVE_ATFORK';
        print "pthread_atfork: in libc, and its child handler runs.\n";
    }
    elsif (probe('atforkp', $atfork, '-lpthread', 1)) {
        $LIBS   .= ' -lpthread';
        $DEFINE .= ' -DSA_HAVE_ATFORK';
        print "pthread_atfork: needs -lpthread for its handler to run: "
            . "linking it.\n";
    }
    else {
        print "pthread_atfork: absent, or its child handler never runs - "
            . "getpid will not be cached.\n";
    }
}

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

if ($^O ne 'MSWin32') {
    # Run, not just linked: a header can name the clock on a kernel whose
    # syscall refuses it, and the fallback is silent only when the probe was
    # honest about that.
    my $coarse = <<'C';
#include <time.h>
int main(void) {
#ifdef CLOCK_REALTIME_COARSE
    struct timespec ts;
    return clock_gettime(CLOCK_REALTIME_COARSE, &ts) == 0 ? 0 : 1;
#else
    return 1;
#endif
}
C
    if (probe('coarse', $coarse, '', 1)) {
        $DEFINE .= ' -DSA_HAVE_COARSE_CLOCK';
        print "clock_gettime(CLOCK_REALTIME_COARSE): yes, deadlines read it.\n";
    }
    else {
        print "clock_gettime(CLOCK_REALTIME_COARSE): no, gettimeofday.\n";
    }
}

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
        'Frozen'              => '0.07',
        'Struct::Codec'       => '0.05',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Frozen'        => '0.07',
        'Struct::Codec' => '0.05',
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
