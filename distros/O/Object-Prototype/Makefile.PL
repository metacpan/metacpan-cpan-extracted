#
# $Id: Makefile.PL,v 0.2 2007/04/07 01:57:59 dankogai Exp dankogai $
#
use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Object::Prototype',
    VERSION_FROM      => 'lib/Object/Prototype.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Object/Prototype.pm', # retrieve abstract from module
       AUTHOR         => 'Dan Kogai <dankogai@intra>') : ()),
);
