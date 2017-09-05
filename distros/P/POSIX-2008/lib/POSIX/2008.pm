package POSIX::2008;

use strict;
use warnings;

require Exporter;

our $VERSION = '0.12';

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
openat open pread ptsname pwrite pwritev random read readlink readlinkat
remainder remove rename renameat round scalbn seed48 setegid seteuid setgid
setitimer setpriority setregid setreuid setuid setutxent sighold sigignore
signbit sigpause sigrelse sinh srand48 srandom stat symlink symlinkat sync tan
tanh tgamma truncate trunc unlinkat unlink utimensat write writev y0 y1 yn

AT_EACCESS AT_EMPTY_PATH AT_FDCWD AT_NO_AUTOMOUNT AT_REMOVEDIR
AT_SYMLINK_FOLLOW AT_SYMLINK_NOFOLLOW BOOT_TIME CLOCK_BOOTTIME CLOCK_HIGHRES
CLOCK_MONOTONIC CLOCK_MONOTONIC_COARSE CLOCK_MONOTONIC_FAST
CLOCK_MONOTONIC_PRECISE CLOCK_MONOTONIC_RAW CLOCK_PROCESS_CPUTIME_ID
CLOCK_REALTIME CLOCK_REALTIME_COARSE CLOCK_REALTIME_FAST
CLOCK_REALTIME_PRECISE CLOCK_SOFTTIME CLOCK_THREAD_CPUTIME_ID CLOCK_UPTIME
CLOCK_UPTIME_FAST CLOCK_UPTIME_PRECISE _CS_GNU_LIBC_VERSION
_CS_GNU_LIBPTHREAD_VERSION _CS_PATH DEAD_PROCESS FNM_CASEFOLD FNM_FILE_NAME
FNM_LEADING_DIR FNM_NOESCAPE FNM_NOMATCH FNM_PATHNAME FNM_PERIOD FP_INFINITE
FP_NAN FP_NORMAL FP_SUBNORMAL FP_ZERO INIT_PROCESS ITIMER_PROF ITIMER_REAL
ITIMER_VIRTUAL LOGIN_PROCESS NEW_TIME O_CLOEXEC O_DIRECTORY O_EXEC OLD_TIME
O_NOFOLLOW O_RSYNC O_SEARCH O_SYNC O_TMPFILE O_TTY_INIT RTLD_GLOBAL RTLD_LAZY
RTLD_LOCAL RTLD_NOW RUN_LVL TIMER_ABSTIME USER_PROCESS UTIME_NOW UTIME_OMIT

);

our %EXPORT_TAGS = (
  'at'    => [grep(/^AT_/, @EXPORT_OK), grep(/at$/ && !/^l?stat$/, @EXPORT_OK)],
  'id'    => [grep /^[gs]et.+id$/, @EXPORT_OK],
  'clock' => [grep /^clock/i, @EXPORT_OK],
  'rw'    => [qw(read write writev)],
  'prw'   => [qw(pread pwrite pwritev)],
  'is'    => [grep /^is/, @EXPORT_OK],
);

sub DESTROY { }

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
