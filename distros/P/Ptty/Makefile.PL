use ExtUtils::MakeMaker;

require 'AutoConf';
use Config;

$Version = '0.01';
#
# Grab things that perl's Configure has already discovered
#
#AutoConf::Define(sigret_t => $Config{'signal_t'});
#AutoConf::Define(SIGPROTOARG => '()');
#
# Now some poking around in /dev to see what we can find
#
AutoConf::Define('HAVE_DEV_PTC') if (-e "/dev/ptc");

$pdir = (-d "/dev/ptym") ? "/dev/ptym" : "/dev";
@ptys = <$pdir/pty??>;
if (@ptys)
 {
  my %p0 = ();
  my %p1 = ();
  foreach (@ptys)
   {
    my ($x,$y) = /(.)(.)$/;
    $p0{$x}++;
    $p1{$y}++;
   }
  AutoConf::Define(PTYRANGE0 => '"'.join('',sort(keys %p0)).'"');
  AutoConf::Define(PTYRANGE1 => '"'.join('',sort(keys %p1)).'"');
  AutoConf::Define(PTYTEMPLATE,"\"$pdir/ptyXY\"");
 }

# Now we get to trial compiles

if (AutoConf::cpp(check=>"POSIX",'grep' => 'yes',code=>'
#include <sys/types.h>
#include <unistd.h>
main () {
#ifdef _POSIX_VERSION
  yes
#endif
'))
{
 AutoConf::Define('POSIX');
} 

AutoConf::Compile(check => 'System V',
header => '#include <sys/types.h>
#include <signal.h>
#include <fcntl.h>
',body => 'int x = SIGCHLD | FNDELAY;','else_define' => -DSYSV);

if (AutoConf::Compile(libs => '-lgibberish'))
 {
  die "Compile fails to detect stupid libraries";
 }

if (AutoConf::Compile(check => 'SVR4',libs => '-lelf') ||
    AutoConf::Compile(header => "#include <elf.h>\n") ||
    AutoConf::Compile(header => "#include <dwarf.h>\n")
   )
 {
  AutoConf::Define('SVR4');
 }
                           
WriteMakefile(
    'NAME'     => 'Ptty',
    'DISTNAME' => "Ptty",
    'VERSION'  => $Version,
    'DEFINE'  => &AutoConf::define, 
    'INC'     => &AutoConf::include,
    'LIBS'    => ["-linet"],
    'dist'      => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
    'clean' 	=> {'FILES' => '*%'},
    'MAP_TARGET' => 'perltty'
);


sub MY::postamble {
'
Makefile : AutoConf
';
}


