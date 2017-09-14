package POSIX::2008;

use strict;
use warnings;

require Exporter;

our $VERSION = '0.15';

our @ISA = qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = qw(

a64l abort abs access acos acosh alarm asin asinh atan2 atan atanh atof atoi
atol basename cabs cacos cacosh carg casinh catan catanh catclose catgets
catopen cbrt ccos ccosh ceil cexp chdir chmod chown cimag clock
clock_getcpuclockid clock_getres clock_gettime clock_nanosleep clock_settime
clog confstr conj copysign cos cosh cpow cproj creal csin csinh csqrt ctan
ctanh dirname div dlclose dlerror dlopen dlsym drand48 endutxent erand48 erf
erfc exp2 expm1 faccessat fchdir fchmod fchmodat fchown fchownat fdatasync
fdim fdopen fdopendir fegetround fesetround ffs floor fma fmax fmin fmod
fnmatch fpclassify fstatat fsync ftruncate futimens getdate getdate_err
getegid geteuid getgid gethostid gethostname getitimer getpriority getsid
getuid getutxent getutxid getutxline hypot ilogb isalpha isatty isblank
iscntrl isdigit isfinite isgraph isinf islower isnan isnormal isprint ispunct
isspace isupper isxdigit j0 j1 jn jrand48 killpg l64a ldexp ldiv lgamma link
linkat log1p log2 logb lrand48 lround lstat mkdir mkdirat mkdtemp mkfifo
mkfifoat mknod mknodat mkstemp mrand48 nanosleep nearbyint nextafter nrand48
openat open pread preadv ptsname pwrite pwritev random read readlink
readlinkat readv remainder remove rename renameat round scalbn seed48 setegid
seteuid setgid setitimer setpriority setregid setreuid setuid setutxent
sighold sigignore signbit sigpause sigrelse sinh srand48 srandom stat strptime
symlink symlinkat sync tan tanh tgamma truncate trunc unlinkat unlink
utimensat write writev y0 y1 yn

AT_EACCESS AT_EMPTY_PATH AT_FDCWD AT_NO_AUTOMOUNT AT_REMOVEDIR
AT_SYMLINK_FOLLOW AT_SYMLINK_NOFOLLOW BOOT_TIME CLOCK_BOOTTIME CLOCK_HIGHRES
CLOCK_MONOTONIC CLOCK_MONOTONIC_COARSE CLOCK_MONOTONIC_FAST
CLOCK_MONOTONIC_PRECISE CLOCK_MONOTONIC_RAW CLOCK_PROCESS_CPUTIME_ID
CLOCK_REALTIME CLOCK_REALTIME_COARSE CLOCK_REALTIME_FAST
CLOCK_REALTIME_PRECISE CLOCK_SOFTTIME CLOCK_THREAD_CPUTIME_ID CLOCK_UPTIME
CLOCK_UPTIME_FAST CLOCK_UPTIME_PRECISE _CS_GNU_LIBC_VERSION
_CS_GNU_LIBPTHREAD_VERSION _CS_PATH DEAD_PROCESS F_DUPFD F_DUPFD_CLOEXEC
F_GETFD F_SETFD F_GETFL F_SETFL F_GETLK F_SETLK F_SETLKW F_GETOWN F_SETOWN
F_RDLCK F_UNLCK F_WRLCK FD_CLOEXEC FNM_CASEFOLD FNM_FILE_NAME FNM_LEADING_DIR
FNM_NOESCAPE FNM_NOMATCH FNM_PATHNAME FNM_PERIOD FP_INFINITE FP_NAN FP_NORMAL
FP_SUBNORMAL FP_ZERO INIT_PROCESS ITIMER_PROF ITIMER_REAL ITIMER_VIRTUAL
LOGIN_PROCESS NEW_TIME O_ACCMODE O_APPEND O_CLOEXEC O_CREAT O_DIRECTORY
O_DSYNC O_EXEC O_NOCTTY O_NOFOLLOW O_NONBLOCK O_RDONLY O_RDWR O_RSYNC O_SEARCH
O_SYNC O_TMPFILE O_TRUNC O_TTY_INIT O_WRONLY OLD_TIME POSIX_FADV_NORMAL
POSIX_FADV_SEQUENTIAL POSIX_FADV_RANDOM POSIX_FADV_NOREUSE POSIX_FADV_WILLNEED
POSIX_FADV_DONTNEED RTLD_GLOBAL RTLD_LAZY RTLD_LOCAL RTLD_NOW RUN_LVL SEEK_SET
SEEK_CUR SEEK_END TIMER_ABSTIME USER_PROCESS UTIME_NOW UTIME_OMIT

);

our %EXPORT_TAGS = (
  'at'    => [grep(/^AT_/, @EXPORT_OK), grep(/at$/ && !/^l?stat$/, @EXPORT_OK)],
  'id'    => [grep /^[gs]et.+id$/, @EXPORT_OK],
  'is'    => [grep /^is/, @EXPORT_OK],
  'rw'    => [qw(read write readv writev)],
  'prw'   => [qw(pread preadv pwrite pwritev)],
  'clock' => [grep /^clock/i, @EXPORT_OK],
  'fcntl' => [grep /^(?:F|FD|O|POSIX_FADV)_/, @EXPORT_OK],
  'fnm'   => [grep(/^FNM_/, @EXPORT_OK), 'fnmatch']
);

our $AUTOLOAD;
sub AUTOLOAD {
  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  die "&POSIX::2008::constant not defined" if $constname eq 'constant';
  my ($error, $val) = constant($constname);
  if ($error) {
    my (undef,$file,$line) = caller;
    die "$error at $file line $line.\n";
  }
  {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  }
  goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('POSIX::2008', $VERSION);

1;
