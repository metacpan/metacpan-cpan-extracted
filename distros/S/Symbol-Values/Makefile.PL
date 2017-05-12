use 5.006;
use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.4 2005/08/08 11:56:10 kay Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Symbol::Values',
    VERSION_FROM      => 'lib/Symbol/Values.pm', # finds $VERSION
    PREREQ_PM         => {
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Symbol/Values.pm', # retrieve abstract from module
       AUTHOR         => 'Keitaro Miyazaki <kmiyazaki@cpan.org>') : ()),
);
