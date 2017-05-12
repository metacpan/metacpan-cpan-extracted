# $Id: Makefile.PL,v 1.5 2003/05/09 18:56:23 oradb Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Oracle::Debug',
    'VERSION_FROM'	=> 'Oracle/Debug.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Oracle/Debug.pm', # retrieve abstract from module
       AUTHOR     => 'Richard Foley <Oracle_Debug@rfi.net>') : ()),
);
