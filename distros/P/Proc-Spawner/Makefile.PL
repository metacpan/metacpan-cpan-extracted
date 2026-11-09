use ExtUtils::MakeMaker;
use ExtUtils::CBuilder; use File::Temp 'tempdir'; use File::Spec; use Config;

# posix_spawn, and the extensions of it this libc has.  They are functions, not macros, so #ifdef cannot see them:
# compile and link a call to each, as autoconf would.  PROC_SPAWNER_WITHOUT="NAME ..." skips some (tests).  Without
# POSIX_SPAWN itself the primitive is fork and exec (decision M2), every setting done around it.
my %PROBE = (
  POSIX_SPAWN     => 'pid_t p; posix_spawn_file_actions_t f; posix_spawnattr_t a; return posix_spawn(&p, "/bin/true", &f, &a, 0, 0);',
  ADDCHDIR_NP     => 'posix_spawn_file_actions_t f; return posix_spawn_file_actions_addchdir_np(&f, "/");',
  ADDFCHDIR_NP    => 'posix_spawn_file_actions_t f; return posix_spawn_file_actions_addfchdir_np(&f, 0);',
  ADDCLOSEFROM_NP => 'posix_spawn_file_actions_t f; return posix_spawn_file_actions_addclosefrom_np(&f, 3);',
  ADDTCSETPGRP_NP => 'posix_spawn_file_actions_t f; return posix_spawn_file_actions_addtcsetpgrp_np(&f, 0);',
  SETCGROUP_NP    => 'posix_spawnattr_t a; return posix_spawnattr_setcgroup_np(&a, 0) + POSIX_SPAWN_SETCGROUP;',
  PIDFD_SPAWN     => 'int fd; return pidfd_spawn(&fd, "/bin/true", 0, 0, 0, 0) + pidfd_getpid(fd);',
);
my %without = map +($_ => 1), split ' ', $ENV{PROC_SPAWNER_WITHOUT} // '';
%PROBE = () if $^O eq 'MSWin32';   # Windows: posix_spawn is win_spawn.h's, on CreateProcessW (Spawner.xs includes it)
my ($cb, $dir, @have) = (ExtUtils::CBuilder->new(quiet => 1), tempdir(CLEANUP => 1));
open my $err, '>&', \*STDERR or die; open STDERR, '>', File::Spec->devnull;   # the failing probes' messages
for my $n (sort grep !$without{$_}, keys %PROBE) {
  open my $f, '>', "$dir/$n.c" or die "$dir/$n.c: $!";
  print $f "#define _GNU_SOURCE\n#include <spawn.h>\n", $n eq 'PIDFD_SPAWN' ? "#include <sys/pidfd.h>\n" : '',
           "int main(void) { $PROBE{$n} }\n";
  close $f;
  push @have, $n if eval {
    my $o = $cb->compile(source => "$dir/$n.c", object_file => "$dir/$n$Config{_o}",
                         $Config{gccversion} ? (extra_compiler_flags => '-Werror=implicit-function-declaration') : ());
    $cb->link_executable(objects => [$o], exe_file => "$dir/$n$Config{_exe}") } }
open STDERR, '>&', $err or die;
print $^O eq 'MSWin32' ? "Windows: posix_spawn from win_spawn.h (CreateProcessW)\n"
                      : "posix_spawn and extensions found: " . (join(' ', @have) || 'none') . "\n";

WriteMakefile(
  NAME             => 'Proc::Spawner',
  VERSION_FROM     => 'lib/Proc/Spawner.pm',
  ABSTRACT_FROM    => 'lib/Proc/Spawner.pm',
  AUTHOR           => 'Ilya Zakharevich',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.020',   # key/value hash slices
  XS               => { 'Spawner.xs' => 'Spawner.c' },
  DEFINE           => join(' ', map "-DHAVE_$_", @have),
  CONFIGURE_REQUIRES => { 'ExtUtils::CBuilder' => 0, 'ExtUtils::MakeMaker' => 0 },
  TEST_REQUIRES    => { 'Test::More' => 0 },
  META_MERGE       => { 'meta-spec' => { version => 2 },   # Run: only where there is neither posix_spawn nor fork (M2)
                        prereqs => { runtime => { recommends => { Run => '0.07' } } } },
);
