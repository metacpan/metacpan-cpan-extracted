use 5.008_009;  # my_dirfd not available earlier
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'POSIX::2008',
  AUTHOR        => 'Carsten Gaebler',
  VERSION_FROM  => 'lib/POSIX/2008.pm',
  ABSTRACT_FROM => 'lib/POSIX/2008.pod',
  MIN_PERL_VERSION => '5.008009',
  PREREQ_PM     => {}, # e.g., Module::Name => 1.1
  LIBS          => ['-lm -lrt'],
  DEFINE        => '', # e.g., '-DHAVE_SOMETHING'
  INC           => '-I.', # e.g., '-I. -I/usr/include/other'
  # Un-comment this if you add C files to link with later:
  # OBJECT      => '$(O_FILES)', # link all the C files too
  dist          => { TARFLAGS => '--numeric-owner -cpf' },
);

# Using T_NV is a bit ugly but how do you deal with e.g. an 8-byte off_t if
# ivsize is ony 4 bytes?
my $isizet = $Config{ivsize} < $Config{nvsize} ? 'T_NV' : 'T_IV';
(my $usizet = $isizet) =~ s/I/U/;

open my $TMAP, '>', 'typemap';
print $TMAP <<EOTM;
off_t     $isizet
size_t    $usizet
ssize_t   $isizet
time_t    $isizet
clock_t   $isizet
clockid_t T_IV
gid_t     T_UV
uid_t     T_UV
pid_t     T_IV
dev_t     T_UV
mode_t    T_UV
id_t      T_UV
int *     T_OPAQUEPTR
nl_catd   T_PTR
SysRet0   T_SYSRET0
FILE *    T_STDIO
psx_fd_t  T_PSX_FD

######
INPUT
T_PSX_FD
  \$var = psx_fileno(aTHX_ \$arg);
  if (\$var < 0)
    XSRETURN_UNDEF;

OUTPUT
T_SYSRET0
    if (\$var != -1)
      sv_setiv(\$arg, (IV)\$var);

EOTM
