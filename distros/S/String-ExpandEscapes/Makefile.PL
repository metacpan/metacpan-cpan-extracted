# $Id: Makefile.PL,v 1.1.1.1 2003/04/03 19:10:10 matthias Exp $
#

use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::ExpandEscapes',
    'VERSION_FROM'	=> 'ExpandEscapes.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ExpandEscapes.pm', # retrieve abstract from module
       AUTHOR     => 'Matthias Friedrich <matt@mafr.de>') : ()),
);
