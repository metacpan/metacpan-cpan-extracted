use 5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'String::ShowHTMLDiff',
    EXE_FILES		 => [],
    VERSION_FROM      => 'lib/String/ShowHTMLDiff.pm', # finds $VERSION
    PREREQ_PM         => { 
    		'Test::More' => 0 
    		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/String/ShowHTMLDiff.pm', # retrieve abstract from module
       AUTHOR         => 'Jim <james.garvin@titan.com>' ) : ()),
);
