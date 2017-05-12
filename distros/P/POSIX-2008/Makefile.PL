use 5.010001;
use Config;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POSIX::2008',
    VERSION_FROM      => 'lib/POSIX/2008.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/POSIX/2008.pod', # retrieve abstract from module
    LIBS              => ['-lm -lrt'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

my $isizetype = $Config{ivsize} < $Config{nvsize} ? 'T_NV' : 'T_IV';
(my $usizetype = $isizetype) =~ s/I/U/;

open my $TMAP, '>', 'typemap';
print $TMAP <<EOTM;
off_t      $isizetype
size_t     $usizetype
ssize_t    $isizetype
time_t     $isizetype
clockid_t  T_IV
gid_t      T_UV
uid_t      T_UV
pid_t      T_IV
dev_t      T_UV
mode_t     T_UV
id_t       T_UV
int *      T_OPAQUEPTR
nl_catd    T_PTR
SysRet0    T_SYSRET0

######################
OUTPUT
T_SYSRET0
    if (\$var != -1) {
        sv_setiv(\$arg, (IV)\$var);
    }
EOTM
