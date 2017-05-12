# -*- mode:Perl -*-
# $Id: Makefile.PL,v 1.1 1997/04/22 04:15:48 chip Beta $
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Net::Whois',
    'VERSION_FROM' => 'Whois.pm', # finds $VERSION
);
