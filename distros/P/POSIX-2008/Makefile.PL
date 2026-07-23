use 5.008_009;  # for my_dirfd
use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Errno;
use Config;
use ExtUtils::Constant 'WriteConstants';
use ExtUtils::MakeMaker 'WriteMakefile';
use Fcntl;
use File::Spec;
use File::Temp 'mktemp';
use MIME::Base64 'decode_base64';
use POSIX ':signal_h';

use constant VERBOSE => exists $ENV{VERBOSE} ? $ENV{VERBOSE} : 0;

# Need "our" because we localize it in check_cc().
our $err2devnull = VERBOSE ? undef : ' 2>'.File::Spec->devnull();
my $cfile = 'try.c';
my $tmp_ccout = mktemp('_tXXXXXX');
# On some systems the compiler silently adds an extension to the executable.
my $tmp_exe = File::Spec->catfile(
  File::Spec->curdir(), "${tmp_ccout}$Config{'_exe'}"
);

my $CC = $Config{cc};
my $CCFLAGS = $Config{ccflags};
$CCFLAGS .= ' -D_GNU_SOURCE'
  if $Config{d_gnulibc} && $CCFLAGS !~ /-D_GNU_SOURCE/;
$CCFLAGS .= " $Config{ccstdflags}" if $Config{ccstdflags};
$CCFLAGS .= " $Config{optimize}" if $Config{optimize};

my %libs;
my %extra_cc_flags;

sub guess_int_fmt_type {
  # Guess largest integer type as well as integer type and format string
  # suitable for formatting a size_t.
  my $sizesize = $Config{sizesize};
  my @types = (
    { dfmt => 'zd', ufmt => 'zu', size => $sizesize,
      dtype => 'ssize_t', utype => 'size_t' },
    { dfmt => 'lld', ufmt => 'llu', size => $Config{longlongsize}||0,
      dtype => 'long long', utype => 'unsigned long long' },
    { dfmt => 'ld' , ufmt => 'lu', size => $Config{longsize},
      dtype => 'long', utype => 'unsigned long' },
    { dfmt => 'd', ufmt => 'u', size => $Config{intsize},
      dtype => 'int', utype => 'unsigned int' },
    { dfmt => 'hd', ufmt => 'hu', size => $Config{shortsize},
      dtype => 'short', utype => 'unsigned short' },
  );

  # Get largest integer type.
  my ($max_int) = grep $_->{size}, sort { $b->{size} <=> $a->{size} } @types;

  # Get smallest integer type that fits a size_t. Using the *smallest* type
  # avoids segfaults caused by wrong stack argument sizes when formatting with
  # croak() or warn().
  my ($size_fmt) = do {
    use warnings FATAL => 'printf';
    grep $_->{size} >= $sizesize && eval { sprintf "\%$_->{dfmt}", 1 },
      sort { $a->{size} <=> $b->{size} } @types;
  };

  $size_fmt ||= { dfmt => 'IVdf', ufmt => 'UVuf', size => $Config{ivsize},
                  dtype => 'IV', utype => 'UV' };

  return ($max_int, $size_fmt);
}

sub run_cmd {
  my $cmd = shift;
  my @sig_no_die = @_;

  $cmd .= $err2devnull if $err2devnull;
  print "$cmd\n" if VERBOSE;

  my $res = system $cmd;
  if ($res != -1 && (my $sig = $res & 127)) {
    my $msg = "$cmd killed by signal $sig";
    grep($sig == $_, @sig_no_die) ? warn $msg : die $msg;
  }

  return $res == 0;
}

sub try_compile {
  my $what = shift;
  my $ccode = shift;
  my $run = shift;

  my $lib =
    $what =~ /^dl/ ? '-ldl' :
    $what =~ /^bcrypt/ ? '-lbcrypt' :
    $what =~ /^(?:clock|timer)/ ? '-lrt' :
    $ccode =~ '<quadmath\.h>' ? '-lquadmath' :
    $ccode =~ /<(?:complex|fenv|math)\.h>/ ? '-lm' : '';

  my $mopt = $what =~ /^rdrand/ ? '-mrdrnd' : '';

  if ($lib eq '-lquadmath') {
    return 0 unless $Config{usequadmath};
  }
  if ($what =~ /^(?:ll?rint|ll?round|scalbl?n|c?sqrt|isfinite|isinf|isnan)l$/) {
    return 0 unless $Config{uselongdouble};
  }

  sysopen my $C, $cfile, O_WRONLY|O_CREAT|O_EXCL or die "Can't open $cfile: $!";
  print $C $ccode;
  close $C or die "Can't write to $cfile: $!";

  my $cccmd = "$CC $CCFLAGS $mopt -o $tmp_ccout $cfile $lib";
  my $ok = run_cmd($cccmd) && -s $tmp_exe && -x _;
  if ($ok && $run) {
    # RDRAND might raise SIGILL on Ivy Bridge,
    # RNDR raises SIGILL before ARMv8-A.
    my @sig_no_die = $what =~ /^(?:rdrand|rndr)/ ? SIGILL : ();
    $ok = run_cmd($tmp_exe, @sig_no_die);
  }

  unlink $cfile, $tmp_ccout, $tmp_exe;
  ++$libs{$lib} if $ok && $lib;
  ++$extra_cc_flags{$mopt} if $ok && $mopt;

  return $ok;
}

sub check_cc {
  my $ok = $CC && do {
    local $err2devnull;
    try_compile('', "int main(void) { return 0; }\n");
  };
  print { $ok ? *STDOUT : *STDERR } "Compiler[$CC]: ".($ok ? 'yes' : 'no')."\n";
  $ok or die(
    "It seems you don't have a working C compiler ".
    "(tried '$CC'; PATH=$ENV{PATH}).\n"
  );
}

unlink $cfile, $tmp_ccout, $tmp_exe, '2008.h', 'typemap';
check_cc();

sysopen my $DEF, '2008.h', O_WRONLY|O_CREAT|O_EXCL or die "2008.h: $!";

while (my $line = <DATA>) {
  next if $line =~ /^\s*(?:#.*)?$/;
  my ($what, $b64) = split ' ', $line;
  my $ccode = decode_base64($b64);
  my $ok = try_compile($what, $ccode, $what =~ /^(?:getrandom|rdrand|rndr)/);
  if ($ok) {
    my $define = '#define PSX2008_HAS_'.uc($what)."\n";
    print $DEF $define or close $DEF or die "Can't write to 2008.h: $!";
  }
  print "$what: ".($ok ? 'yes' : 'no')."\n";
}
close DATA;

my ($max_int, $size_fmt) = guess_int_fmt_type();
print $DEF <<EOSZ;
#define INT_MAX_TYPE $max_int->{dtype}
#define UINT_MAX_TYPE $max_int->{utype}
#define PSX2008_SZdf "$size_fmt->{dfmt}"
#define PSX2008_SZuf "$size_fmt->{ufmt}"
#define PSX2008_SZdft $size_fmt->{dtype}
#define PSX2008_SZuft $size_fmt->{utype}
EOSZ
close $DEF or die "Can't write to 2008.h: $!";

my @names = do {
  local $/;
  open my $fh, '<', 'constants.txt' or die "Can't open constants.txt: $!";
  grep !/^(?:HUGE_VAL|INFINITY|U?L?LONG_M(?:AX|IN))$/, split ' ', <$fh>;
};

push @names, (
  {
    # We cannot use newSVpvf() with "%llu" because "%llu" might not be
    # supported even if long long is available. ASSUME(!!temp_sv) saves the
    # NULL check of the generated SvREFCNT_inc().
    name => 'ULLONG_MAX', type => 'SV',
    pre => (
      'SV * temp_sv = (ULLONG_MAX <= UV_MAX) ? newSVuv((UV)ULLONG_MAX) : _fmt_uint_2sv(aTHX_ ULLONG_MAX); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'LLONG_MAX', type => 'SV',
    pre => (
      'SV * temp_sv = (LLONG_MAX <= IV_MAX) ? newSViv((IV)LLONG_MAX) : _fmt_uint_2sv(aTHX_ LLONG_MAX); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'LLONG_MIN', type => 'SV',
    pre => (
      'SV * temp_sv = (IV_MIN <= LLONG_MIN) ? newSViv((IV)LLONG_MIN) : _fmt_neg_int_2sv(aTHX_ LLONG_MIN); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'ULONG_MAX', type => 'SV',
    pre => (
      'SV * temp_sv = (ULONG_MAX <= UV_MAX) ? newSVuv((UV)ULONG_MAX) : _fmt_uint_2sv(aTHX_ ULONG_MAX); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'LONG_MAX', type => 'SV',
    pre => (
      'SV * temp_sv = (LONG_MAX <= IV_MAX) ? newSViv((IV)LONG_MAX) : _fmt_uint_2sv(aTHX_ LONG_MAX); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'LONG_MIN', type => 'SV',
    pre => (
      'SV * temp_sv = (IV_MIN <= LONG_MIN) ? newSViv((IV)LONG_MIN) : _fmt_neg_int_2sv(aTHX_ LONG_MIN); ' .
      'temp_sv = sv_2mortal(temp_sv); ASSUME(!!temp_sv);'
    ),
    value => 'temp_sv',
  },
  {
    name => 'INFINITY', type => 'NV', not_constant => 1,
  },
  {
    name => 'HUGE_VAL', type => 'NV', not_constant => 1,
    macro => [<<'EOHV_WRAP', "#endif\n"],
#if (defined(USE_QUADMATH) && defined(HUGE_VALQ)) || (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)) || defined(HUGE_VAL)
EOHV_WRAP
    value => '
# if defined(USE_QUADMATH) && defined(HUGE_VALQ)
                   HUGE_VALQ
# elif defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)
                   HUGE_VALL
# else
                   HUGE_VAL
# endif
'
  },
);

WriteConstants(
  NAME => 'POSIX::2008',
  NAMES => \@names,
  PROXYSUBS => {croak_on_error => 1},
);

my %wmf_attributes = (
  NAME             => 'POSIX::2008',
  AUTHOR           => 'Carsten Gaebler',
  LICENSE          => 'unrestricted', # WTFPL
  VERSION_FROM     => 'lib/POSIX/2008.pm',
  ABSTRACT_FROM    => 'lib/POSIX/2008.pod',
  MIN_PERL_VERSION => '5.008009',
  LIBS             => [join ' ', sort keys %libs],
  DEFINE           => '',
  INC              => '-I.', # e.g., '-I. -I/usr/include/other'
  CCFLAGS          => $Config{ccflags},
  realclean        => {
    FILES => '2008.h const-c.inc const-xs.inc typemap try.c _t*'
  },
  CONFIGURE_REQUIRES => {
    Config                => 0,
    Errno                 => 0,
    'ExtUtils::Constant'  => 0,
    'ExtUtils::MakeMaker' => 0,
    Fcntl                 => 0,
    'File::Spec'          => 0,
    'File::Temp'          => 0,
    'MIME::Base64'        => 0,
  },
  TEST_REQUIRES => {
    Config         => 0,
    Cwd            => 0,
    'Data::Dumper' => 0,
    Errno          => 0,
    Fcntl          => 0,
    'File::Path'   => 0,
    'File::Spec'   => 0,
    'File::Temp'   => 0,
    POSIX          => 0,
    'Scalar::Util' => 0,
    'Test::More'   => 0,
  },
  PREREQ_PM => {
    Carp       => 0,
    Exporter   => 0,
    'IO::Dir'  => 0,
    'IO::File' => 0,
    XSLoader   => 0,
  },
);
if ($Config{gccversion} && $Config{d_attribute_deprecated}) {
  $wmf_attributes{CCFLAGS} .= ' -Wno-deprecated-declarations';
}
if (%extra_cc_flags) {
  $wmf_attributes{CCFLAGS} .= join ' ', '', keys %extra_cc_flags;
}
@{$wmf_attributes{TEST_REQUIRES}}{keys %{$wmf_attributes{PREREQ_PM}}} =
  values %{$wmf_attributes{PREREQ_PM}};
WriteMakefile(%wmf_attributes);

# Using T_NV is a bit ugly but how do you deal with e.g. an 8-byte off_t if
# ivsize is only 4 bytes?
my $iofft  = $Config{ivsize} < $Config{lseeksize} ? 'T_NV' : 'T_IV';
my $isizet = $Config{ivsize} < $Config{sizesize} ? 'T_NV' : 'T_IV';
(my $usizet = $isizet) =~ s/I/U/;

sysopen my $TMAP, 'typemap', O_WRONLY|O_CREAT|O_EXCL or die "typemap: $!";
my $typemap = "
Off_t     $iofft
time_t    $isizet
clock_t   T_IV
clockid_t T_IV
gid_t     T_UV
uid_t     T_UV
pid_t     T_IV
dev_t     T_UV
mode_t    T_UV
id_t      T_UV
int *     T_OPAQUEPTR
nl_catd   T_PTR
timer_t   T_PTR
SysRet0   T_SYSRET0
SysRetTrue  T_SYSRET_TRUE
psx_fd_t  T_PSX_FD
" . '
######
INPUT
T_PSX_FD
	$var = _psx_fileno(aTHX_ $arg);

OUTPUT
T_SYSRET0
	if (LIKELY($var != -1))
	  sv_setiv($arg, (IV)$var);
T_SYSRET_TRUE
	if (LIKELY($var == 0))
	  sv_setpvn($arg, "0 but true", 10);
';
print $TMAP $typemap;
close $TMAP or die "Can't write to typemap: $!";

END {
  unlink $cfile, $tmp_ccout, $tmp_exe;
  unlink '2008.h', 'typemap' if $?;
}

__DATA__
complex_h I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
dlfcn_h I2luY2x1ZGUgPGRsZmNuLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIDA7IH0K
fnmatch_h I2luY2x1ZGUgPGZubWF0Y2guaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
libgen_h I2luY2x1ZGUgPGxpYmdlbi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAwOyB9Cg==
nl_types_h I2luY2x1ZGUgPG5sX3R5cGVzLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIDA7IH0K
poll_h I2luY2x1ZGUgPHBvbGwuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
quadmath_h I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIDA7IH0K
signal_h I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAwOyB9Cg==
string_h I2luY2x1ZGUgPHN0cmluZy5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAwOyB9Cg==
strings_h I2luY2x1ZGUgPHN0cmluZ3MuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
sys_poll_h I2luY2x1ZGUgPHN5cy9wb2xsLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIDA7IH0K
sys_random_h I2luY2x1ZGUgPHN5cy9yYW5kb20uaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
sys_select_h I2luY2x1ZGUgPHN5cy9zZWxlY3QuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
sys_types_h I2luY2x1ZGUgPHN5cy90eXBlcy5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAwOyB9Cg==
sys_uio_h I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gMDsgfQo=
unistd_h I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAwOyB9Cg==
utmpx_h I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIDA7IH0K
a64l I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpYTY0bChhcmd2WzBdKTsgfQo=
abort I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IGFib3J0KCk7IH0K
abs I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIGFicyhhcmdjKTsgfQo=
access I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBhY2Nlc3MoIi4iLCBYX09LKTsgfQo=
acos I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWFjb3MoMC4xKmFyZ2MpOyB9Cg==
acosh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWFjb3NoKDEuMiphcmdjKTsgfQo=
alarm I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIGFsYXJtKGFyZ2MpOyB9Cg==
arc4random_buf I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgaW50IGJ1ZjsKICBhcmM0cmFuZG9tX2J1ZigmYnVmLCBzaXplb2YoYnVmKSk7CiAgcmV0dXJuIGJ1ZjsKfQo=
asin I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWFzaW4oMC4xKmFyZ2MpOyB9Cg==
asinh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWFzaW5oKDEuMiphcmdjKTsgfQo=
atan I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWF0YW4oMS4yKmFyZ2MpOyB9Cg==
atan2 I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWF0YW4yKDEuMiphcmdjLCAxLjEpOyB9Cg==
atanh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWF0YW5oKDAuMSphcmdjKTsgfQo=
atof I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpYXRvZihhcmd2WzFdKTsgfQo=
atoi I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIGF0b2koYXJndlsxXSk7IH0K
atol I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpYXRvbChhcmd2WzFdKTsgfQo=
atoll I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpYXRvbGwoYXJndlsxXSk7IH0K
basename I2luY2x1ZGUgPGxpYmdlbi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBwYXRoW10gPSAiLiI7CiAgY2hhciAqYiA9IGJhc2VuYW1lKHBhdGgpOwogIHJldHVybiAoaW50KSpiOwp9Cg==
bcryptgenrandom I2luY2x1ZGUgPHdpbmRvd3MuaD4KI2luY2x1ZGUgPGJjcnlwdC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWY7CiAgcmV0dXJuIEJDcnlwdEdlblJhbmRvbShOVUxMLCAmYnVmLCAxLCBCQ1JZUFRfVVNFX1NZU1RFTV9QUkVGRVJSRURfUk5HKSAhPSAwOwp9Cg==
cabs I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gMS4yKmFyZ2M7CiAgZG91YmxlIGltID0gMS4yKigqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljYWJzKHopOwp9Cg==
cacos I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gMS4yKmFyZ2M7CiAgZG91YmxlIGltID0gMS4yKigqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljYWNvcyh6KTsKfQo=
cacosh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gMS4yKmFyZ2M7CiAgZG91YmxlIGltID0gMS4yKigqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljYWNvc2goeik7Cn0K
carg I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gMS4yKmFyZ2M7CiAgZG91YmxlIGltID0gMS4yKigqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljYXJnKHopOwp9Cg==
casin I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gMS4yKmFyZ2M7CiAgZG91YmxlIGltID0gMS4yKigqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljYXNpbih6KTsKfQo=
casinh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNhc2luaCh6KTsKfQo=
catan I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNhdGFuKHopOwp9Cg==
catanh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNhdGFuaCh6KTsKfQo=
catclose I2luY2x1ZGUgPG5sX3R5cGVzLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gY2F0Y2xvc2UoKG5sX2NhdGQpYXJndik7IH0K
catgets I2luY2x1ZGUgPG5sX3R5cGVzLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiAhY2F0Z2V0cygobmxfY2F0ZClhcmd2LCAwLCBhcmdjLCAiIik7Cn0K
catopen I2luY2x1ZGUgPG5sX3R5cGVzLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuICEhY2F0b3BlbigiLiIsIDApOyB9Cg==
cbrt I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWNicnQoYXJnYyk7IH0K
ccos I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNjb3Moeik7Cn0K
ccosh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNjb3NoKHopOwp9Cg==
ceil I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHggPSAoZG91YmxlKSgqKmFyZ3YpLyhkb3VibGUpYXJnYzsKICByZXR1cm4gKGludCljZWlsKHgpOwp9Cg==
cexp I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNleHAoeik7Cn0K
chdir I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBjaGRpcigiLiIpOyB9Cg==
chmod I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKCkgeyByZXR1cm4gY2htb2QoIl8iLCAwKTsgfQo=
chown I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBjaG93bigiLiIsIC0xLCAtMSk7IH0K
cimag I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNpbWFnKHopOwp9Cg==
clock I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWNsb2NrKCk7IH0K
clock_getcpuclockid I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgY2xvY2tpZF90IGNsb2NraWQ7CiAgcmV0dXJuIGNsb2NrX2dldGNwdWNsb2NraWQoMCwgJmNsb2NraWQpOwp9Cg==
clock_getres I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgc3RydWN0IHRpbWVzcGVjIHJlczsKICByZXR1cm4gY2xvY2tfZ2V0cmVzKENMT0NLX1JFQUxUSU1FLCAmcmVzKTsKfQo=
clock_gettime I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgc3RydWN0IHRpbWVzcGVjIHRwOwogIHJldHVybiBjbG9ja19nZXR0aW1lKENMT0NLX1JFQUxUSU1FLCAmdHApOwp9Cg==
clock_nanosleep I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCB0aW1lc3BlYyByZXEgPSB7MH0sIHJlbTsKICByZXR1cm4gY2xvY2tfbmFub3NsZWVwKENMT0NLX1JFQUxUSU1FLCAwLCAmcmVxLCAmcmVtKTsKfQo=
clock_settime I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgc3RydWN0IHRpbWVzcGVjIHRwID0gezB9OwogIHJldHVybiBjbG9ja19zZXR0aW1lKENMT0NLX1JFQUxUSU1FLCAmdHApOwp9Cg==
clog I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNsb2coeik7Cn0K
close I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBjbG9zZSgwKTsgfQo=
confstr I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBjaGFyIGJ1ZlsxNl07CiAgcmV0dXJuIChpbnQpY29uZnN0cigwLCBidWYsIHNpemVvZihidWYpKTsKfQo=
conj I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNvbmooeik7Cn0K
copysign I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHggPSAoZG91YmxlKWFyZ2M7CiAgZG91YmxlIHkgPSAoZG91YmxlKWFyZ2MgLSAoZG91YmxlKSgqKmFyZ3YpOwogIHJldHVybiAoaW50KWNvcHlzaWduKHgsIHkpOwp9Cg==
cos I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWNvcyhhcmdjKTsgfQo=
cosh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWNvc2goYXJnYyk7IH0K
cpow I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIGEgPSAoZG91YmxlKWFyZ2M7CiAgZG91YmxlIGIgPSAoZG91YmxlKSgqKmFyZ3YpOwogIGRvdWJsZSBjb21wbGV4IHggPSBhICsgYiAqIEk7CiAgZG91YmxlIGNvbXBsZXggeiA9IGIgKyBhICogSTsKICByZXR1cm4gKGludCljcG93KHgsIHopOwp9Cg==
cproj I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNwcm9qKHopOwp9Cg==
creal I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNyZWFsKHopOwp9Cg==
creat I2luY2x1ZGUgPGZjbnRsLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIGNyZWF0KCIiLCAwKTsgfQo=
csin I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNzaW4oeik7Cn0K
csinh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNzaW5oKHopOwp9Cg==
csqrt I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWNzcXJ0KHopOwp9Cg==
csqrtl I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgbG9uZyBkb3VibGUgcmUgPSAobG9uZyBkb3VibGUpYXJnYzsKICBsb25nIGRvdWJsZSBpbSA9IChsb25nIGRvdWJsZSkoKiphcmd2KTsKICBsb25nIGRvdWJsZSBjb21wbGV4IHogPSByZSArIGltICogSTsKICByZXR1cm4gKGludCljc3FydGwoeik7Cn0K
csqrtq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIF9fY29tcGxleDEyOCB6OwogIF9fcmVhbF9fIHogPSAoX19mbG9hdDEyOClhcmdjOwogIF9faW1hZ19fIHogPSAoX19mbG9hdDEyOCkoKiphcmd2KTsKICByZXR1cm4gKGludCljc3FydHEoeik7Cn0K
ctan I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWN0YW4oeik7Cn0K
ctanh I2luY2x1ZGUgPGNvbXBsZXguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHJlID0gKGRvdWJsZSlhcmdjOwogIGRvdWJsZSBpbSA9IChkb3VibGUpKCoqYXJndik7CiAgZG91YmxlIGNvbXBsZXggeiA9IHJlICsgaW0gKiBJOwogIHJldHVybiAoaW50KWN0YW5oKHopOwp9Cg==
dirname I2luY2x1ZGUgPGxpYmdlbi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBwYXRoW10gPSAiLiI7CiAgY2hhciAqYiA9IGRpcm5hbWUocGF0aCk7CiAgcmV0dXJuIChpbnQpKmI7Cn0K
div I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBkaXZfdCBxID0gZGl2KGFyZ2MsIChpbnQpKCoqYXJndikpOwogIHJldHVybiAoaW50KXEucXVvdDsKfQo=
dlclose I2luY2x1ZGUgPGRsZmNuLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gZGxjbG9zZSgodm9pZCopYXJndlswXSk7IH0K
dlerror I2luY2x1ZGUgPGRsZmNuLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuICEhZGxlcnJvcigpOyB9Cg==
dlopen I2luY2x1ZGUgPGRsZmNuLmg+CiNpbmNsdWRlIDxzdGRkZWYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gISFkbG9wZW4oTlVMTCwgMCk7IH0K
dlsym I2luY2x1ZGUgPGRsZmNuLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gISFkbHN5bSgodm9pZCopMCwgIiIpOyB9Cg==
drand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpZHJhbmQ0OCgpOyB9Cg==
endutxent I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsKICBlbmR1dHhlbnQoKTsKICByZXR1cm4gMDsKfQo=
erand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgdW5zaWduZWQgc2hvcnQgeHN1YmlbM107CiAgcmV0dXJuIChpbnQpZXJhbmQ0OCh4c3ViaSk7Cn0K
erf I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWVyZihhcmdjKTsgfQo=
erfc I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWVyZmMoYXJnYyk7IH0K
execveat I2luY2x1ZGUgPHN0ZGRlZi5oPgojaW5jbHVkZSA8dW5pc3RkLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiBleGVjdmVhdCgtMSwgYXJndlswXSwgYXJndiwgTlVMTCwgYXJnYyk7Cn0K
exp I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWV4cChhcmdjKTsgfQo=
exp2 I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWV4cDIoYXJnYyk7IH0K
exp2q I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiAoaW50KShleHAycSgoX19mbG9hdDEyOClhcmdjKSk7Cn0K
expm1 I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWV4cG0xKGFyZ2MpOyB9Cg==
fabs I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWZhYnMoKGRvdWJsZSlhcmdjKTsgfQo=
faccessat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmYWNjZXNzYXQoMCwgIi4iLCAwLCAwKTsgfQo=
fchdir I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmY2hkaXIoMCk7IH0K
fchmod I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIGZjaG1vZCgtMSwgMCk7IH0K
fchmodat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIGZjaG1vZGF0KC0xLCAiLiIsIDAsIDApOyB9Cg==
fchown I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmY2hvd24oLTEsIC0xLCAtMSk7IH0K
fchownat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmY2hvd25hdCgtMSwgIi4iLCAtMSwgLTEsIDApOyB9Cg==
fdatasync I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmZGF0YXN5bmMoMCk7IH0K
fdim I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgcmV0dXJuIChpbnQpZmRpbSgoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsKfQo=
fdopen I2luY2x1ZGUgPHN0ZGlvLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuICFmZG9wZW4oMCwgInJiIik7IH0K
fdopendir I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19UWVBFU19ICiNpbmNsdWRlIDxzeXMvdHlwZXMuaD4KI2VuZGlmCiNpbmNsdWRlIDxkaXJlbnQuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gIWZkb3BlbmRpcigwKTsgfQo=
feclearexcept I2luY2x1ZGUgPGZlbnYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZmVjbGVhcmV4Y2VwdCgwKTsgfQo=
fegetround I2luY2x1ZGUgPGZlbnYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZmVnZXRyb3VuZCgpOyB9Cg==
feraiseexcept I2luY2x1ZGUgPGZlbnYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZmVyYWlzZWV4Y2VwdCgwKTsgfQo=
fesetround I2luY2x1ZGUgPGZlbnYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZmVzZXRyb3VuZCgwKTsgfQo=
fetestexcept I2luY2x1ZGUgPGZlbnYuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZmV0ZXN0ZXhjZXB0KDApOyB9Cg==
fexecve I2luY2x1ZGUgPHN0ZGRlZi5oPgojaW5jbHVkZSA8dW5pc3RkLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIGNoYXIgKmNvbnN0IGVudnBbXSA9IHswfTsKICByZXR1cm4gZmV4ZWN2ZSgtMSwgYXJndiwgZW52cCk7Cn0K
ffs I2luY2x1ZGUgPHN0cmluZ3MuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBmZnMoYXJnYyk7IH0K
ffsl I2luY2x1ZGUgPHN0cmluZy5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpZmZzbChhcmdjKTsgfQo=
ffsll I2luY2x1ZGUgPHN0cmluZy5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpZmZzbGwoYXJnYyk7IH0K
finiteq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gZmluaXRlcSgoX19mbG9hdDEyOClhcmdjKTsgfQo=
floor I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHggPSAoZG91YmxlKSgqKmFyZ3YpLyhkb3VibGUpYXJnYzsKICByZXR1cm4gKGludClmbG9vcih4KTsKfQo=
fma I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgZG91YmxlIHggPSAoZG91YmxlKWFyZ2M7CiAgZG91YmxlIHkgPSAoZG91YmxlKSgqKmFyZ3YpOwogIGRvdWJsZSB6ID0gKGRvdWJsZSlhcmdjOwogIHJldHVybiAoaW50KWZtYSh4LCB5LCB6KTsKfQo=
fmax I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgcmV0dXJuIChpbnQpZm1heCgoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsKfQo=
fmin I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgcmV0dXJuIChpbnQpZm1pbigoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsKfQo=
fmod I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgcmV0dXJuIChpbnQpZm1vZCgoZG91YmxlKSoqYXJndiwgKGRvdWJsZSlhcmdjKTsKfQo=
fnmatch I2luY2x1ZGUgPGZubWF0Y2guaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZm5tYXRjaCgiKiIsICIuIiwgMCk7IH0K
fpathconf I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWZwYXRoY29uZigwLCAwKTsgfQo=
fpclassify I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBmcGNsYXNzaWZ5KChkb3VibGUpYXJnYyk7IH0K
frexp I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgaW50IGV4OwogICh2b2lkKWZyZXhwKGFyZ2MsICZleCk7CiAgcmV0dXJuIGV4Owp9Cg==
fstat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICByZXR1cm4gZnN0YXQoMCwgJnN0KTsKfQo=
fstatat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICByZXR1cm4gZnN0YXRhdCgwLCAiLiIsICZzdCwgMCk7Cn0K
fstatvfs I2luY2x1ZGUgPHN5cy9zdGF0dmZzLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdHZmcyBzdDsKICByZXR1cm4gZnN0YXR2ZnMoMCwgJnN0KTsKfQo=
fsync I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmc3luYygwKTsgfQo=
ftruncate I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBmdHJ1bmNhdGUoLTEsIC0xKTsgfQo=
futimens I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CiNpbmNsdWRlIDx0aW1lLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgdGltZXNwZWMgdGltZXNbMl0gPSB7MH07CiAgcmV0dXJuIGZ1dGltZW5zKC0xLCB0aW1lcyk7Cn0K
getdate I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gISFnZXRkYXRlKCIwIik7IH0K
getdate_err I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gZ2V0ZGF0ZV9lcnI7IH0K
getegid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWdldGVnaWQoKTsgfQo=
getentropy I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19SQU5ET01fSAojaW5jbHVkZSA8c3lzL3JhbmRvbS5oPgojZW5kaWYKI2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWY7CiAgcmV0dXJuIGdldGVudHJvcHkoJmJ1ZiwgMSk7Cn0K
geteuid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWdldGV1aWQoKTsgfQo=
getgid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWdldGdpZCgpOyB9Cg==
gethostid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWdldGhvc3RpZCgpOyB9Cg==
gethostname I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBuYW1lWzI1Nl07CiAgcmV0dXJuIGdldGhvc3RuYW1lKG5hbWUsIHNpemVvZihuYW1lKSk7Cn0K
getitimer I2luY2x1ZGUgPHN5cy90aW1lLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgaXRpbWVydmFsIGN2OwogIHJldHVybiBnZXRpdGltZXIoSVRJTUVSX1JFQUwsICZjdik7Cn0K
getpriority I2luY2x1ZGUgPHN5cy9yZXNvdXJjZS5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBnZXRwcmlvcml0eSgwLCAwKTsgfQo=
getrandom I2luY2x1ZGUgPHN5cy9yYW5kb20uaD4KaW50IG1haW4odm9pZCkgewogIGNoYXIgYnVmOwogIHJldHVybiBnZXRyYW5kb20oJmJ1ZiwgMSwgMCkgPCAwOwp9Cg==
getrandom_sys I2luY2x1ZGUgPHVuaXN0ZC5oPgojaW5jbHVkZSA8c3lzL3N5c2NhbGwuaD4KaW50IG1haW4odm9pZCkgewogIGNoYXIgYnVmOwogIHJldHVybiBzeXNjYWxsKFNZU19nZXRyYW5kb20sICZidWYsIDEsIDApIDwgMDsKfQo=
getresgid I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19UWVBFU19ICiNpbmNsdWRlIDxzeXMvdHlwZXMuaD4KI2VuZGlmCiNpbmNsdWRlIDx1bmlzdGQuaD4KaW50IG1haW4odm9pZCkgewogIGdpZF90IHJnaWQsIGVnaWQsIHNnaWQ7CiAgcmV0dXJuIGdldHJlc2dpZCgmcmdpZCwgJmVnaWQsICZzZ2lkKTsKfQo=
getresuid I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19UWVBFU19ICiNpbmNsdWRlIDxzeXMvdHlwZXMuaD4KI2VuZGlmCiNpbmNsdWRlIDx1bmlzdGQuaD4KaW50IG1haW4odm9pZCkgewogIHVpZF90IHJ1aWQsIGV1aWQsIHN1aWQ7CiAgcmV0dXJuIGdldHJlc3VpZCgmcnVpZCwgJmV1aWQsICZzdWlkKTsKfQo=
getsid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBnZXRzaWQoMCk7IH0K
getuid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWdldHVpZCgpOyB9Cg==
getutxent I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuICFnZXR1dHhlbnQoKTsgfQo=
getutxid I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgdXRtcHggdXQgPSB7MH07CiAgcmV0dXJuICFnZXR1dHhpZCgmdXQpOwp9Cg==
getutxline I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgdXRtcHggdXQgPSB7MH07CiAgcmV0dXJuICFnZXR1dHhsaW5lKCZ1dCk7Cn0K
grantpt I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBncmFudHB0KDApOyB9Cg==
hypot I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWh5cG90KGFyZ2MsICoqYXJndik7IH0K
ilogb I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpbG9nYihhcmdjKTsgfQo=
isalnum I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNhbG51bShhcmdjKTsgfQo=
isalpha I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNhbHBoYShhcmdjKTsgfQo=
isascii I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNhc2NpaShhcmdjKTsgfQo=
isatty I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBpc2F0dHkoMCk7IH0K
isblank I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNibGFuayhhcmdjKTsgfQo=
iscntrl I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNjbnRybChhcmdjKTsgfQo=
isdigit I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNkaWdpdChhcmdjKTsgfQo=
isfinite I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2Zpbml0ZSgoZG91YmxlKWFyZ2MpOyB9Cg==
isfinitel I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2Zpbml0ZWwoKGxvbmcgZG91YmxlKWFyZ2MpOyB9Cg==
isgraph I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNncmFwaChhcmdjKTsgfQo=
isgreaterequal I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2dyZWF0ZXJlcXVhbCgoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsgfQo=
isinf I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2luZigoZG91YmxlKWFyZ2MpOyB9Cg==
isinfl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2luZmwoKGxvbmcgZG91YmxlKWFyZ2MpOyB9Cg==
isinfq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNpbmZxKChfX2Zsb2F0MTI4KWFyZ2MpOyB9Cg==
isless I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2xlc3MoKGRvdWJsZSlhcmdjLCAoZG91YmxlKSoqYXJndik7IH0K
islessequal I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2xlc3NlcXVhbCgoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsgfQo=
islessgreater I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc2xlc3NncmVhdGVyKChkb3VibGUpYXJnYywgKGRvdWJsZSkqKmFyZ3YpOyB9Cg==
islower I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNsb3dlcihhcmdjKTsgfQo=
isnan I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc25hbigoZG91YmxlKWFyZ2MpOyB9Cg==
isnanl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc25hbmwoKGxvbmcgZG91YmxlKWFyZ2MpOyB9Cg==
isnanq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNuYW5xKChfX2Zsb2F0MTI4KWFyZ2MpOyB9Cg==
isnormal I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc25vcm1hbCgoZG91YmxlKWFyZ2MpOyB9Cg==
isprint I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNwcmludChhcmdjKTsgfQo=
ispunct I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNwdW5jdChhcmdjKTsgfQo=
isspace I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXNzcGFjZShhcmdjKTsgfQo=
isunordered I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBpc3Vub3JkZXJlZCgoZG91YmxlKWFyZ2MsIChkb3VibGUpKiphcmd2KTsgfQo=
isupper I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXN1cHBlcihhcmdjKTsgfQo=
isxdigit I2luY2x1ZGUgPGN0eXBlLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gaXN4ZGlnaXQoYXJnYyk7IH0K
j0 LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpajAoYXJnYyk7IH0K
j1 LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpajEoYXJnYyk7IH0K
jn LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpam4oYXJnYywgKiphcmd2KTsgfQo=
jrand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICB1bnNpZ25lZCBzaG9ydCB4c3ViaVszXTsKICByZXR1cm4gKGludClqcmFuZDQ4KHhzdWJpKTsKfQo=
killpg I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBraWxscGcoMCwgMCk7IH0K
l64a I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBjaGFyICphNjQgPSBsNjRhKGFyZ2MpOwogIHJldHVybiAoaW50KSphNjQ7Cn0K
labs I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIGxhYnMoYXJnYyk7IH0K
lchown I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBsY2hvd24oIi4iLCAtMSwgLTEpOyB9Cg==
ldexp I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxkZXhwKCoqYXJndiwgYXJnYyk7IH0K
ldiv I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBsZGl2X3QgcSA9IGxkaXYoYXJnYywgKiphcmd2KTsKICByZXR1cm4gKGludClxLnF1b3Q7Cn0K
lgamma I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxnYW1tYShhcmdjKTsgfQo=
link I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBsaW5rKCIuIiwgIi4iKTsgfQo=
linkat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBsaW5rYXQoLTEsICIuIiwgLTEsICIuIiwgMCk7IH0K
llabs I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIGxsYWJzKGFyZ2MpOyB9Cg==
lldiv I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBsbGRpdl90IHEgPSBsbGRpdihhcmdjLCAqKmFyZ3YpOwogIHJldHVybiAoaW50KXEucXVvdDsKfQo=
llrint I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxscmludChhcmdjKTsgfQo=
llrintl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxscmludGwoYXJnYyk7IH0K
llrintq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludClsbHJpbnRxKChfX2Zsb2F0MTI4KWFyZ2MpOyB9Cg==
llround I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxscm91bmQoYXJnYyk7IH0K
llroundl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxscm91bmRsKGFyZ2MpOyB9Cg==
llroundq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludClsbHJvdW5kcSgoX19mbG9hdDEyOClhcmdjKTsgfQo=
log I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxvZyhhcmdjKTsgfQo=
log10 I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxvZzEwKGFyZ2MpOyB9Cg==
log1p I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxvZzFwKGFyZ2MpOyB9Cg==
log2 I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxvZzIoYXJnYyk7IH0K
logb I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxvZ2IoYXJnYyk7IH0K
logbq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludCkobG9nYnEoKF9fZmxvYXQxMjgpYXJnYykpOyB9Cg==
lrand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KWxyYW5kNDgoKTsgfQo=
lrint I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxyaW50KGFyZ2MpOyB9Cg==
lrintl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxyaW50bChhcmdjKTsgfQo=
lrintq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludClscmludHEoKF9fZmxvYXQxMjgpYXJnYyk7IH0K
lround I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxyb3VuZChhcmdjKTsgfQo=
lroundl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KWxyb3VuZGwoYXJnYyk7IH0K
lroundq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludClscm91bmRxKChfX2Zsb2F0MTI4KWFyZ2MpOyB9Cg==
lstat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICByZXR1cm4gbHN0YXQoIi4iLCAmc3QpOwp9Cg==
mkdir I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKI2lmIGRlZmluZWQoX1dJTjMyKSAmJiAhZGVmaW5lZChfX0NZR1dJTl9fKQogIHJldHVybiBta2RpcigiLiIpOwojZWxzZQogIHJldHVybiBta2RpcigiLiIsIDApOwojZW5kaWYKfQo=
mkdirat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG1rZGlyYXQoLTEsICIuIiwgMCk7IH0K
mkdtemp I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBmW10gPSAiIjsKICByZXR1cm4gISFta2R0ZW1wKGYpOwp9Cg==
mkfifo I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG1rZmlmbygiLiIsIDApOyB9Cg==
mkfifoat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG1rZmlmb2F0KC0xLCAiLiIsIDApOyB9Cg==
mknod I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG1rbm9kKCIuIiwgMCwgMCk7IH0K
mknodat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG1rbm9kYXQoLTEsICIuIiwgMCwgMCk7IH0K
mkostemp I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBmW10gPSAiIjsKICByZXR1cm4gbWtvc3RlbXAoZiwgMCk7Cn0K
mkstemp I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBmW10gPSAiIjsKICByZXR1cm4gbWtzdGVtcChmKTsKfQo=
mrand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KW1yYW5kNDgoKTsgfQo=
nanosleep I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgc3RydWN0IHRpbWVzcGVjIHJlcSA9IHsudHZfc2VjPWFyZ2MsIC50dl9uc2VjPSoqYXJndiB9LCByZW07CiAgcmV0dXJuIG5hbm9zbGVlcCgmcmVxLCAmcmVtKTsKfQo=
nearbyint I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KW5lYXJieWludChhcmdjKTsgfQo=
nextafter I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KW5leHRhZnRlcihhcmdjLCAqKmFyZ3YpOyB9Cg==
nexttoward I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KW5leHR0b3dhcmQoKGRvdWJsZSlhcmdjLCAoZG91YmxlKSoqYXJndik7IH0K
nexttowardq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiAoaW50KShuZXh0dG93YXJkcSgoX19mbG9hdDEyOClhcmdjLCAoX19mbG9hdDEyOCkqKmFyZ3YpKTsKfQo=
nfds_t I2luY2x1ZGUgIjIwMDguaCIKI2lmIGRlZmluZWQoUFNYMjAwOF9IQVNfUE9MTF9IKQojaW5jbHVkZSA8cG9sbC5oPgojZWxpZiBkZWZpbmVkKFBTWDIwMDhfSEFTX1NZU19QT0xMX0gpCiNpbmNsdWRlIDxzeXMvcG9sbC5oPgojZW5kaWYKaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgbmZkc190IG5mZHMgPSAobmZkc190KWFyZ2M7CiAgcmV0dXJuICEhbmZkczsKfQo=
nice I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBuaWNlKDApOyB9Cg==
nrand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICB1bnNpZ25lZCBzaG9ydCB4c3ViaVszXTsKICByZXR1cm4gKGludClucmFuZDQ4KHhzdWJpKTsKfQo=
open I2luY2x1ZGUgPGZjbnRsLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG9wZW4oIi4iLCBPX1JET05MWSk7IH0K
openat I2luY2x1ZGUgPGZjbnRsLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIG9wZW5hdCgtMSwgIi4iLCAwKTsgfQo=
openat2 I2luY2x1ZGUgPGZjbnRsLmg+CiNpbmNsdWRlIDxsaW51eC9vcGVuYXQyLmg+CiNpbmNsdWRlIDxzeXMvc3lzY2FsbC5oPgojaW5jbHVkZSA8dW5pc3RkLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgb3Blbl9ob3cgaG93ID0gezB9OwogIHJldHVybiAoaW50KXN5c2NhbGwoU1lTX29wZW5hdDIsIEFUX0ZEQ1dELCAiLiIsICZob3csIHNpemVvZihob3cpKTsKfQo=
pathconf I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbigpIHsgcmV0dXJuIChpbnQpcGF0aGNvbmYoIi4iLCAwKTsgfQo=
pause I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBwYXVzZSgpOyB9Cg==
poll I2luY2x1ZGUgIjIwMDguaCIKI2lmIGRlZmluZWQoUFNYMjAwOF9IQVNfUE9MTF9IKQojaW5jbHVkZSA8cG9sbC5oPgojZWxpZiBkZWZpbmVkKFBTWDIwMDhfSEFTX1NZU19QT0xMX0gpCiNpbmNsdWRlIDxzeXMvcG9sbC5oPgojZW5kaWYKaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBwb2xsZmQgZmRzID0gezB9OwogIHJldHVybiBwb2xsKCZmZHMsIDAsIDApOwp9Cg==
posix_fadvise I2luY2x1ZGUgPGZjbnRsLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gcG9zaXhfZmFkdmlzZSgtMSwgMCwgMCwgMCk7IH0K
posix_fallocate I2luY2x1ZGUgPGZjbnRsLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIHBvc2l4X2ZhbGxvY2F0ZSgtMSwgMCwgMCk7IH0K
posix_openpt I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBwb3NpeF9vcGVucHQoMCk7IH0K
pow I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXBvdyhhcmdjLCAqKmFyZ3YpOyB9Cg==
ppoll I2luY2x1ZGUgPHRpbWUuaD4KI2luY2x1ZGUgIjIwMDguaCIKI2lmIGRlZmluZWQoUFNYMjAwOF9IQVNfUE9MTF9IKQojaW5jbHVkZSA8cG9sbC5oPgojZWxpZiBkZWZpbmVkKFBTWDIwMDhfSEFTX1NZU19QT0xMX0gpCiNpbmNsdWRlIDxzeXMvcG9sbC5oPgojZW5kaWYKaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBwb2xsZmQgZmRzID0gezB9OwogIHN0cnVjdCB0aW1lc3BlYyB0bW8gPSB7MH07CiAgcmV0dXJuIHBwb2xsKCZmZHMsIDAsICZ0bW8sIE5VTEwpOwp9Cg==
pread I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWZbMV07CiAgcmV0dXJuIChpbnQpcHJlYWQoLTEsIGJ1Ziwgc2l6ZW9mKGJ1ZiksIDApOwp9Cg==
preadv I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIGNoYXIgYnVmOwogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7JmJ1ZiwgMX07CiAgcmV0dXJuIChpbnQpcHJlYWR2KC0xLCAmaW92LCAxLCAwKTsKfQo=
preadv2 I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIGNoYXIgYnVmOwogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7JmJ1ZiwgMX07CiAgcmV0dXJuIChpbnQpcHJlYWR2MigtMSwgJmlvdiwgMSwgMCwgMCk7Cn0K
psignal I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7CiAgcHNpZ25hbCgwLCAiIik7CiAgcmV0dXJuIDA7Cn0K
ptsname I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAhcHRzbmFtZSgwKTsgfQo=
ptsname_r I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBuYW1lWzhdOwogIHJldHVybiBwdHNuYW1lX3IoMCwgbmFtZSwgc2l6ZW9mKG5hbWUpKTsKfQo=
pwrite I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KXB3cml0ZSgwLCAiIiwgMCwgMCk7IH0K
pwritev I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7MH07CiAgcmV0dXJuIChpbnQpcHdyaXRldigwLCAmaW92LCAxLCAwKTsKfQo=
pwritev2 I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7MH07CiAgcmV0dXJuIChpbnQpcHdyaXRldjIoMCwgJmlvdiwgMSwgMCwgMCk7Cn0K
raise I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiByYWlzZSgxNSk7IH0K
random I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KXJhbmRvbSgpOyB9Cg==
rdrand32 I2luY2x1ZGUgPGltbWludHJpbi5oPgppbnQgbWFpbih2b2lkKSB7CiAgdW5zaWduZWQgdSwgaSA9IDczOwogIHdoaWxlIChpLS0pCiAgICBpZiAoX3JkcmFuZDMyX3N0ZXAoJnUpKQogICAgICByZXR1cm4gMDsKICByZXR1cm4gMTsKfQo=
rdrand64 I2lmZGVmIF9fSU5URUxfQ09NUElMRVIKI2luY2x1ZGUgPHN0ZGludC5oPgp0eXBlZGVmIHVpbnQ2NF90IHJkcmFuZF90OwojZWxzZQp0eXBlZGVmIHVuc2lnbmVkIGxvbmcgbG9uZyByZHJhbmRfdDsKI2VuZGlmCiNpbmNsdWRlIDxpbW1pbnRyaW4uaD4KaW50IG1haW4odm9pZCkgewogIHJkcmFuZF90IHUsIGkgPSA3MzsKICB3aGlsZSAoaS0tKQogICAgaWYgKF9yZHJhbmQ2NF9zdGVwKCZ1KSkKICAgICAgcmV0dXJuIDA7CiAgcmV0dXJuIDE7Cn0K
read I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWZbOF07CiAgcmV0dXJuIHJlYWQoLTEsIGJ1Ziwgc2l6ZW9mKGJ1ZikpOwp9Cg==
readlink I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWZbOF07CiAgcmV0dXJuIChpbnQpcmVhZGxpbmsoIi4iLCBidWYsIHNpemVvZihidWYpKTsKfQo=
readlinkat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWZbOF07CiAgcmV0dXJuIChpbnQpcmVhZGxpbmthdCgtMSwgIi4iLCBidWYsIHNpemVvZihidWYpKTsKfQo=
readv I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIGNoYXIgYnVmWzhdOwogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7YnVmLCBzaXplb2YoYnVmKX07CiAgcmV0dXJuIChpbnQpcmVhZHYoLTEsICZpb3YsIDEpOwp9Cg==
realpath I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAhIXJlYWxwYXRoKCIuIiwgTlVMTCk7IH0K
remainder I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXJlbWFpbmRlcihhcmdjLCAqKmFyZ3YpOyB9Cg==
remove I2luY2x1ZGUgPHN0ZGlvLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIHJlbW92ZSgiXyIpOyB9Cg==
remquo I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7CiAgaW50IGk7CiAgcmV0dXJuIChpbnQpcmVtcXVvKGFyZ2MsICoqYXJndiwgJmkpOwp9Cg==
rename I2luY2x1ZGUgPHN0ZGlvLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIHJlbmFtZSgiLiIsICIuIik7IH0K
renameat I2luY2x1ZGUgPHN0ZGlvLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIHJlbmFtZWF0KC0xLCAiLiIsIC0xLCAiLiIpOyB9Cg==
renameat2 I2luY2x1ZGUgPHN0ZGlvLmg+CmludCBtYWluKHZvaWQpIHsgcmV0dXJuIHJlbmFtZWF0MigtMSwgIi4iLCAtMSwgIi4iLCAwKTsgfQo=
rint I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXJpbnQoYXJnYyk7IH0K
rmdir I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBybWRpcigiXyIpOyB9Cg==
rndr I2luY2x1ZGUgPGFybV9hY2xlLmg+CiNpbmNsdWRlIDxzdGRpbnQuaD4KX19hdHRyaWJ1dGVfXygodGFyZ2V0KCIrcm5nIikpKQppbnQgbWFpbih2b2lkKSB7CiAgdWludDY0X3QgdSwgaSA9IDczOwogIHdoaWxlIChpLS0pCiAgICBpZiAoX19ybmRyKCZ1KSA9PSAwKQogICAgICByZXR1cm4gMDsKICByZXR1cm4gMTsKfQo=
round I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXJvdW5kKGFyZ2MpOyB9Cg==
scalbln I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNjYWxibG4oYXJnYywgKiphcmd2KTsgfQo=
scalblnl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNjYWxibG5sKGFyZ2MsICoqYXJndik7IH0K
scalblnq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiAoaW50KXNjYWxibG5xKChfX2Zsb2F0MTI4KWFyZ2MsICoqYXJndik7Cn0K
scalbn I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNjYWxibihhcmdjLCAqKmFyZ3YpOyB9Cg==
scalbnl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNjYWxibmwoYXJnYywgKiphcmd2KTsgfQo=
scalbnq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgewogIHJldHVybiAoaW50KXNjYWxibnEoKF9fZmxvYXQxMjgpYXJnYywgKiphcmd2KTsKfQo=
seed48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7CiAgdW5zaWduZWQgc2hvcnQgc2VlZDE2dlszXSA9IHswfTsKICB1bnNpZ25lZCBzaG9ydCAqcyA9IHNlZWQ0OChzZWVkMTZ2KTsKICByZXR1cm4gKGludCkqczsKfQo=
setegid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRlZ2lkKDApOyB9Cg==
seteuid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRldWlkKDApOyB9Cg==
setgid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRnaWQoMCk7IH0K
setitimer I2luY2x1ZGUgPHN5cy90aW1lLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgaXRpbWVydmFsIG9sZF92YWw7CiAgc3RydWN0IGl0aW1lcnZhbCBuZXdfdmFsID0ge3swLDB9LHswLDB9fTsKICByZXR1cm4gc2V0aXRpbWVyKElUSU1FUl9SRUFMLCAmbmV3X3ZhbCwgJm9sZF92YWwpOwp9Cg==
setpriority I2luY2x1ZGUgPHN5cy9yZXNvdXJjZS5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRwcmlvcml0eSgwLCAwLCAwKTsgfQo=
setregid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRyZWdpZCgwLCAwKTsgfQo=
setresgid I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19UWVBFU19ICiNpbmNsdWRlIDxzeXMvdHlwZXMuaD4KI2VuZGlmCiNpbmNsdWRlIDx1bmlzdGQuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gc2V0cmVzZ2lkKDAsIDAsIDApOyB9Cg==
setresuid I2luY2x1ZGUgIjIwMDguaCIKI2lmZGVmIFBTWDIwMDhfSEFTX1NZU19UWVBFU19ICiNpbmNsdWRlIDxzeXMvdHlwZXMuaD4KI2VuZGlmCiNpbmNsdWRlIDx1bmlzdGQuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gc2V0cmVzdWlkKDAsIDAsIDApOyB9Cg==
setreuid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXRyZXVpZCgwLCAwKTsgfQo=
setsid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KXNldHNpZCgpOyB9Cg==
setuid I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzZXR1aWQoMCk7IH0K
setutxent I2luY2x1ZGUgPHV0bXB4Lmg+CmludCBtYWluKHZvaWQpIHsKICBzZXR1dHhlbnQoKTsKICByZXR1cm4gMDsKfQo=
sighold I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzaWdob2xkKDE1KTsgfQo=
sigignore I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzaWdpZ25vcmUoMTUpOyB9Cg==
signbit I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiBzaWduYml0KChkb3VibGUpYXJnYyk7IH0K
sigpause I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzaWdwYXVzZSgxNSk7IH0K
sigrelse I2luY2x1ZGUgPHNpZ25hbC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzaWdyZWxzZSgxNSk7IH0K
sin I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNpbihhcmdjKTsgfQo=
sinh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXNpbmgoYXJnYyk7IH0K
sqrt I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KShzcXJ0KGFyZ2MpKTsgfQo=
sqrtl I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KShzcXJ0bChhcmdjKSk7IH0K
sqrtq I2luY2x1ZGUgPHF1YWRtYXRoLmg+CmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndikgeyByZXR1cm4gKGludCkoc3FydHEoKF9fZmxvYXQxMjgpYXJnYykpOyB9Cg==
srand48 I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBzcmFuZDQ4KGFyZ2MpOwogIHJldHVybiAwOwp9Cg==
srandom I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsKICBzcmFuZG9tKGFyZ2MpOwogIHJldHVybiAwOwp9Cg==
st_atim I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICAodm9pZClzdGF0KCIuIiwgJnN0KTsKICByZXR1cm4gKGludClzdC5zdF9hdGltLnR2X25zZWM7Cn0K
st_atimensec I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICAodm9pZClzdGF0KCIuIiwgJnN0KTsKICByZXR1cm4gKGludClzdC5zdF9hdGltZW5zZWM7Cn0K
st_ctime I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICAodm9pZClzdGF0KCIuIiwgJnN0KTsKICByZXR1cm4gKGludClzdC5zdF9jdGltZTsKfQo=
stat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdCBzdDsKICByZXR1cm4gc3RhdCgiLiIsICZzdCk7Cn0K
statvfs I2luY2x1ZGUgPHN5cy9zdGF0dmZzLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3Qgc3RhdHZmcyBzdDsKICByZXR1cm4gc3RhdHZmcygiLiIsICZzdCk7Cn0K
strptime I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCB0bSB0bTsKICByZXR1cm4gISFzdHJwdGltZSgiMCIsICIlVCIsICZ0bSk7Cn0K
strsignal I2luY2x1ZGUgPHN0cmluZy5oPgppbnQgbWFpbih2b2lkKSB7CiAgKHZvaWQpc3Ryc2lnbmFsKDApOwogIHJldHVybiAwOwp9Cg==
symlink I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzeW1saW5rKCIuIiwgIi4iKTsgfQo=
symlinkat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiBzeW1saW5rYXQoIi4iLCAtMSwgIi4iKTsgfQo=
sync I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgc3luYygpOwogIHJldHVybiAwOwp9Cg==
sysconf I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KXN5c2NvbmYoMCk7IH0K
tan I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXRhbihhcmdjKTsgfQo=
tanh I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KSh0YW5oKGFyZ2MpKTsgfQo=
tgamma I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXRnYW1tYShhcmdjKTsgfQo=
timer_create I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgewogIHRpbWVyX3QgdGltZXJfaWQ7CiAgcmV0dXJuIHRpbWVyX2NyZWF0ZShDTE9DS19SRUFMVElNRSwgTlVMTCwgJnRpbWVyX2lkKTsKfQo=
timer_delete I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gdGltZXJfZGVsZXRlKCh0aW1lcl90KTApOyB9Cg==
timer_getoverrun I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgeyByZXR1cm4gdGltZXJfZ2V0b3ZlcnJ1bigodGltZXJfdCkwKTsgfQo=
timer_gettime I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBpdGltZXJzcGVjIGN2OwogIHJldHVybiB0aW1lcl9nZXR0aW1lKCh0aW1lcl90KTAsICZjdik7Cn0K
timer_settime I2luY2x1ZGUgPHRpbWUuaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBpdGltZXJzcGVjIG5ld192YWwgPSB7ezAsMH0sIHswLDB9fTsKICBzdHJ1Y3QgaXRpbWVyc3BlYyBvbGRfdmFsID0ge3swLDB9LCB7MCwwfX07CiAgcmV0dXJuIHRpbWVyX3NldHRpbWUoKHRpbWVyX3QpMCwgMCwgJm5ld192YWwsICZvbGRfdmFsKTsKfQo=
trunc I2luY2x1ZGUgPG1hdGguaD4KaW50IG1haW4oaW50IGFyZ2MsIGNoYXIgKiphcmd2KSB7IHJldHVybiAoaW50KXRydW5jKGFyZ2MpOyB9Cg==
truncate I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiB0cnVuY2F0ZSgiLiIsIC0xKTsgfQo=
ttyname I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAhdHR5bmFtZSgwKTsgfQo=
ttyname_r I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7CiAgY2hhciBidWZbOF07CiAgcmV0dXJuIHR0eW5hbWVfcigwLCBidWYsIHNpemVvZihidWYpKTsKfQo=
unlink I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiB1bmxpbmsoIi4iKTsgfQo=
unlinkat I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiB1bmxpbmthdCgtMSwgIi4iLCAwKTsgfQo=
unlockpt I2luY2x1ZGUgPHN0ZGxpYi5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiB1bmxvY2twdCgwKTsgfQo=
utimensat I2luY2x1ZGUgPHN5cy9zdGF0Lmg+CiNpbmNsdWRlIDx0aW1lLmg+CmludCBtYWluKHZvaWQpIHsKICBzdHJ1Y3QgdGltZXNwZWMgdGltZXNbMl0gPSB7MH07CiAgcmV0dXJuIHV0aW1lbnNhdCgtMSwgIi4iLCB0aW1lcywgMCk7Cn0K
write I2luY2x1ZGUgPHVuaXN0ZC5oPgppbnQgbWFpbih2b2lkKSB7IHJldHVybiAoaW50KXdyaXRlKDAsICIiLCAwKTsgfQo=
writev I2luY2x1ZGUgPHN5cy91aW8uaD4KaW50IG1haW4odm9pZCkgewogIHN0cnVjdCBpb3ZlYyBpb3YgPSB7MH07CiAgcmV0dXJuIChpbnQpd3JpdGV2KDAsICZpb3YsIDEpOwp9Cg==
y0 LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpeTAoYXJnYyk7IH0K
y1 LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpeTEoYXJnYyk7IH0K
yn LyogaHR0cHM6Ly9zb3VyY2Vmb3JnZS5uZXQvcC9taW5ndy13NjQvZmVhdHVyZS1yZXF1ZXN0cy82OC8gKi8KI2lmIGRlZmluZWQoX19NSU5HVzMyX18pICYmIGRlZmluZWQoX19TVFJJQ1RfQU5TSV9fKQojdW5kZWYgX19TVFJJQ1RfQU5TSV9fCiNlbmRpZgojaW5jbHVkZSA8bWF0aC5oPgppbnQgbWFpbihpbnQgYXJnYywgY2hhciAqKmFyZ3YpIHsgcmV0dXJuIChpbnQpeW4oYXJnYywgKiphcmd2KTsgfQo=
