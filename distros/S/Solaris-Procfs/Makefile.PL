use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];

if ($sys ne "SunOS" || $rel !~ /^(5.6|5.7|5.8|5.9)$/) {

   die("Solaris::Procfs is only supported on Solaris 2.6, 7, 8, and 9\n");
}

WriteMakefile(
   NAME         => 'Solaris',
   VERSION_FROM => 'Procfs/Procfs.pm',
   DIR          => [ 'Procfs' ],
);
