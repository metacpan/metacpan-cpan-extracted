use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(

    'NAME'		=> 'Paper::Specs',

    'VERSION_FROM'	=> 'lib/Paper/Specs.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Paper/Specs.pm', # retrieve abstract from module
       AUTHOR     => 'Jon Allen <jj@jonallen.info>') : ()),

);
