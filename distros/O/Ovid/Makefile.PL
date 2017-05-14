use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Ovid',
    'VERSION_FROM'	=> 'ovid', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'EXE_FILES'  => [qw(ovid)], 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ovid', # retrieve abstract from module
       AUTHOR     => 'Gyepi Sam <gyepi@cpan.org>') : ()),
);
