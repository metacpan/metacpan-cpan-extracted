package POSIX::2008;

use strict;
use warnings;
use Carp;

require Exporter;

our $VERSION = '0.20';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION; # so "use Module 0.002" won't warn on underscore

our @_functions = qw(
a64l abort abs access acos acosh alarm asin asinh atan atan2 atanh atof atoi
basename cabs cacos cacosh carg casin casinh catan catanh catclose catgets
catopen cbrt ccos ccosh ceil cexp chdir chmod chown cimag clock
clock_getcpuclockid clock_getres clock_gettime clock_nanosleep clock_settime
clog close confstr conj copysign cos cosh cpow cproj creal csin csinh csqrt
ctan ctanh dirname div dlclose dlerror dlopen dlsym drand48 endutxent erand48
erf erfc exp exp2 expm1 faccessat fchmodat fchownat fdatasync fdim fdopen
fdopendir feclearexcept fegetround feraiseexcept fesetround fetestexcept ffs
floor fma fmax fmin fmod fnmatch fpclassify fstatat fsync futimens getdate
getdate_err getegid geteuid getgid gethostid gethostname getitimer getpriority
getsid getuid getutxent getutxid getutxline hypot ilogb isalnum isalpha
isascii isatty isblank iscntrl isdigit isfinite isgraph isgreaterequal isinf
isless islessequal islessgreater islower isnan isnormal isprint ispunct
isspace isunordered isupper isxdigit j0 j1 jn jrand48 killpg l64a ldexp lgamma
link linkat log log1p log2 logb lrand48 lround lstat mkdir mkdirat mkdtemp
mkfifo mkfifoat mknod mknodat mkstemp mrand48 nanosleep nearbyint nextafter
nice nrand48 open openat openat2 pread preadv preadv2 ptsname pwrite pwritev
pwritev2 random read readlink readlinkat readv realpath remainder remove
remquo rename renameat rmdir round scalbn seed48 setegid seteuid setgid
setitimer setpriority setregid setreuid setsid setuid setutxent sighold
sigignore signbit sigpause sigrelse sin sinh srand48 srandom stat strptime
symlink symlinkat sync tan tanh tgamma timer_create timer_delete
timer_getoverrun timer_gettime timer_settime trunc truncate ttyname unlink
unlinkat utimensat write writev y0 y1 yn
);

our @_constants = qw(
AT_EACCESS AT_EMPTY_PATH AT_FDCWD AT_NO_AUTOMOUNT AT_REMOVEDIR
AT_SYMLINK_FOLLOW AT_SYMLINK_NOFOLLOW BOOT_TIME CLOCK_BOOTTIME CLOCK_HIGHRES
CLOCK_MONOTONIC CLOCK_MONOTONIC_COARSE CLOCK_MONOTONIC_FAST
CLOCK_MONOTONIC_PRECISE CLOCK_MONOTONIC_RAW CLOCK_PROCESS_CPUTIME_ID
CLOCK_REALTIME CLOCK_REALTIME_COARSE CLOCK_REALTIME_FAST
CLOCK_REALTIME_PRECISE CLOCK_SOFTTIME CLOCK_THREAD_CPUTIME_ID CLOCK_UPTIME
CLOCK_UPTIME_FAST CLOCK_UPTIME_PRECISE _CS_GNU_LIBC_VERSION
_CS_GNU_LIBPTHREAD_VERSION _CS_PATH DEAD_PROCESS FASYNC F_DUPFD
F_DUPFD_CLOEXEC F_GETFD F_SETFD F_GETFL F_SETFL F_GETLK F_SETLK F_SETLKW
F_GETOWN F_SETOWN F_RDLCK F_UNLCK F_WRLCK FD_CLOEXEC FE_TONEAREST
FE_TOWARDZERO FE_UPWARD FE_DOWNWARD FE_DIVBYZERO FE_INEXACT FE_INVALID
FE_OVERFLOW FE_UNDERFLOW FE_ALL_EXCEPT FNM_CASEFOLD FNM_FILE_NAME
FNM_LEADING_DIR FNM_NOESCAPE FNM_NOMATCH FNM_PATHNAME FNM_PERIOD FP_INFINITE
FP_NAN FP_NORMAL FP_SUBNORMAL FP_ZERO INIT_PROCESS ITIMER_PROF ITIMER_REAL
ITIMER_VIRTUAL LOGIN_PROCESS NEW_TIME O_ACCMODE O_ASYNC O_APPEND O_CLOEXEC
O_CREAT O_DIRECT O_DIRECTORY O_DSYNC O_EXEC O_EXCL O_LARGEFILE O_NDELAY
O_NOATIME O_NOCTTY O_NOFOLLOW O_NONBLOCK O_PATH O_RDONLY O_RDWR O_RSYNC
O_SEARCH O_SYNC O_TMPFILE O_TRUNC O_TTY_INIT O_WRONLY OLD_TIME
POSIX_FADV_NORMAL POSIX_FADV_SEQUENTIAL POSIX_FADV_RANDOM POSIX_FADV_NOREUSE
POSIX_FADV_WILLNEED POSIX_FADV_DONTNEED PRIO_PROCESS PRIO_PGRP PRIO_USER
RESOLVE_BENEATH RESOLVE_IN_ROOT RESOLVE_NO_MAGICLINKS RESOLVE_NO_SYMLINKS
RESOLVE_NO_XDEV RESOLVE_CACHED RTLD_GLOBAL RTLD_LAZY RTLD_LOCAL RTLD_NOW
RUN_LVL RWF_DSYNC RWF_HIPRI RWF_SYNC RWF_NOWAIT RWF_APPEND S_IFMT S_IFBLK
S_IFCHR S_IFIFO S_IFREG S_IFDIR S_IFLNK S_IFSOCK S_ISUID S_ISGID S_IRWXU
S_IRUSR S_IWUSR S_IXUSR S_IRWXG S_IRGRP S_IWGRP S_IXGRP S_IRWXO S_IROTH
S_IWOTH S_IXOTH S_ISVTX SEEK_SET SEEK_CUR SEEK_END SEEK_DATA SEEK_HOLE
TIMER_ABSTIME USER_PROCESS UTIME_NOW UTIME_OMIT F_OK R_OK W_OK X_OK
);

our @ISA = qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = (@_functions, @_constants);

our %EXPORT_TAGS = (
  # at: Older Perls don't have variable length lookbehind, hence two regexen
  # for functions.
  'at'     => [grep(/^(?:AT|RESOLVE)_/, @_constants),
              grep(/at$/ && !/^l?stat$/, @_functions), 'openat2'],
  'id'     => [grep /^[gs]et.+id$/, @_functions],
  'is'     => [grep /^is/, @_functions],
  'rw'     => [qw(read write readv writev)],
  'prw'    => [qw(pread preadv preadv2 pwrite pwritev pwritev2)],
  'clock'  => [grep(/^CLOCK_/, @_constants), grep(/^clock/, @_functions)],
  'fcntl'  => [grep /^(?:[FORWX]|FD|POSIX_FADV|SEEK)_/, @_constants],
  'fenv_h' => [grep(/^FE_/, @_constants), grep (/^fe/, @_functions)],
  'fnm'    => [grep(/^FNM_/, @_constants), 'fnmatch'],
  'stat_h' => [grep /^(?:S_I|UTIME_)/, @_constants],
  'time_h' => [grep /^(?:CLOCK|TIMER)_/, @_constants],
  'timer'  => [grep(/^TIMER_/, @_constants), grep(/^timer_/, @_functions)],
);

my %depre = (
  atol => 'atoi',
  atoll => 'atoi',
  ldiv => 'div',
  fchdir => 'chdir',
  fchmod => 'chmod',
  fchown => 'chown',
  ftruncate => 'truncate',
);

push @EXPORT_OK, keys %depre;

our $AUTOLOAD;
sub AUTOLOAD {
  my ($func) = ($AUTOLOAD =~ /.*::(.*)/);
  die "POSIX::2008.xs has failed to load\n" if $func eq 'constant';
  constant($func);
}

sub import {
  my $this = shift;

  # This is a hack that allows us to import only the non-XS portion of the
  # module in Makefile.PL to get the constants for WriteConstants(). It's not
  # intended for use in actual code!
  if (@_ && $_[0] eq '-noxs') {
    shift;
  }
  else {
    require XSLoader;
    XSLoader::load('POSIX::2008', $XS_VERSION);

    while (my ($func, $repl) = each %depre) {
      my $package_func = __PACKAGE__."::${func}";
      my $package_repl = __PACKAGE__."::${repl}";
      no strict 'refs';
      *{$package_func} = sub {
        carp("${package_func}() is deprecated, use ${package_repl}() instead");
        &{*{$package_repl}};
      }
    }
  }

  __PACKAGE__->export_to_level(1, $this, @_);
}

1;
