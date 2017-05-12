use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.5.1|5.6|5.7)$/)
   {
   die("Solaris:: is only supported on Solaris 2.5.1, 2.6 & 2.7\n");
   }

WriteMakefile(
   NAME         => 'Solaris',
   VERSION      => '0.05',
   DIR          => [ 'Kstat', 'MapDev' ],
   EXE_FILES    => [ 'scripts/dump_kstat', 'scripts/iost+',
                     'scripts/mapdev', 'scripts/show_devs' ], 
);
