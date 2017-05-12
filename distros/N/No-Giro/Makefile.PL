use 5.6.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'No::Giro',
    VERSION_FROM      => 'lib/No/Giro.pm', # finds $VERSION
    PREREQ_PM         => {
	PostScript::Simple => '0.06p3'
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/No/Giro.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Kjernsmo <kk@kjernsmo.net>') : ()),
);
