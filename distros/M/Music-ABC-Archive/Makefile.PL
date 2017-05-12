use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Music::ABC::Archive',
    'VERSION_FROM'	=> 'Archive.pm', # finds $VERSION

    'PREREQ_PM'		=> {
    				'Music::ABC::Song' => 0
			    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Archive.pm', # retrieve abstract from module
       AUTHOR     => 'root <root@localdomain>') : ()),
);
