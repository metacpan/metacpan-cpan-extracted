#
# $Source: /cvsroot/devicetool/Solaris-DeviceTree/Makefile.PL,v $
# $Id: Makefile.PL,v 1.6 2003/12/07 19:35:23 honkbude Exp $
#

use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is Solaris
my ($sys, $rel) = (POSIX::uname())[0,2];

if( $sys ne "SunOS" || $rel !~ /^(5.7|5.8|5.9)$/ ) {
  warn("WARNING: Solaris::DeviceTree has been tested on Solaris 7, 8, 9\n",
       "It may not work on $sys $rel\n\n");
}

WriteMakefile(
  'NAME'		=> 'Solaris::DeviceTree',
  'VERSION'		=> '0.03',
  'EXE_FILES'		=> [ 'scripts/devtree' ],
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM	=> 'lib/Solaris/DeviceTree.pod',
    AUTHOR		=> 'Dagobert Michelsen <dm@baltic-online.de>') : ()),
);
