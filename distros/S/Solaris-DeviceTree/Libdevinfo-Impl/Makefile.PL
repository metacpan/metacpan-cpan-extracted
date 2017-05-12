#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/Libdevinfo-Impl/Makefile.PL,v 1.4 2003/12/10 10:52:56 honkbude Exp $
#

use ExtUtils::MakeMaker;
use POSIX qw(uname);

our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

# Compile only if we have 
my ($sys, $rel) = (POSIX::uname())[0,2];

my ($release, $subrelease) = ($rel =~ /^(\d+)\.(\d+)$/);

if( $sys ne "SunOS" || $release != 5 || $subrelease < 7 ) {
  warn("WARNING: The libdevinfo API is only available on Solaris starting with release 7.\n" .
       "Skipping libdevinfo interface on $sys $rel\n");
  WriteMakefile(
    'NAME'		=> 'Solaris::DeviceTree::Libdevinfo::Impl',
    'PM'		=> {},
    'MAN3PODS'		=> {},
    'C'			=> [],
  );
} else {
  WriteMakefile(
    'NAME'		=> 'Solaris::DeviceTree::Libdevinfo::Impl',
    'VERSION_FROM'	=> 'Makefile.PL',	# that's us
    'LIBS'		=> '-ldevinfo',
    'OBJECT'		=> 'Impl.o Impl_wrap.o',
  );
}
